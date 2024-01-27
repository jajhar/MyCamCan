#import "RecorderView.h"
#import "CaptureView_Private.h"
#import "pthread.h"

const float VideoRecorderRelieveTime = 0.25f;
//const NSUInteger WantedSizeBits = 3 * 1024 * 1024;
//const CGFloat EstimatedDuration = 6.0;
const NSUInteger WantedSizeBits = 5 * 1024 * 1024;
const CGFloat EstimatedDuration = 9.0;

typedef void (^PreparationsDoneCallback)(BOOL wasAlreadyPrepared);
typedef void (^CompletionDoneCallback)(void);

@interface RecorderView ()

//L1

@property (assign, nonatomic, readonly) pthread_mutex_t stateChangeMutex; //should protect from async calls to start/stop recording
@property (assign, nonatomic, readonly) pthread_mutex_t recordingMutex; //should protect recording operation

@property (strong, nonatomic) GPUImageMovieWriter *movieWriter;
@property (strong, nonatomic) NSString *pathToMovie;
@property (strong, nonatomic) GPUImagePictureWriter *pictureWriter;

@property (assign, nonatomic) BOOL videoIsRecordedInner;

- (void)tryPrepareToRecordAnd:(PreparationsDoneCallback)callback;
- (void)tryCompleteRecordingAnd:(CompletionDoneCallback)callback;

- (void)recordingWasLaunched;
- (void)recordingWillBeStopped;

- (void)setNewPathToMovie;

//L2

@property (strong, nonatomic, readonly) dispatch_semaphore_t prepareToRecordSemaphore;

@property (strong, nonatomic) PreparationsDoneCallback preparationsDoneCallback;

@property (assign, nonatomic, readonly) BOOL preparedToRecord;
@property (strong, nonatomic) UIImage *thumb;

@property (assign, nonatomic, readonly) CGSize videoSize;
@property (strong, nonatomic, readonly) NSString *videoFileType;
@property (strong, nonatomic, readonly) NSMutableDictionary *videoOutputSettings;

- (void)targetMovieWriter;
- (void)untargetMovieWriter;
- (void)targetPictureWriter;
- (void)untargetPictureWriter;

- (void)setPathToMovie:(NSString *)pathToMovie;

@end

@implementation RecorderView

#define PICTURE_RESOLUTION_W 832.0
#define PICTURE_RESOLUTION_H 1477.0

#pragma mark L0

+ (NSString *)generatePathToMovie {
	NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	return [cachesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"vixlet-clip-%lu-tmp.mp4", time(NULL)]]; //file name must be unique
}

- (BOOL)videoIsRecorded {
    return NO;// (self.videoIsRecordedInner && !self.movieWriter.isRecording);
}

- (BOOL)isRecording {
    return NO;//self.movieWriter.isRecording;
}

- (void)capturePicture:(GPUImagePictureWriterCallback)callback {
    [self.pictureWriter capturePicture:callback];
}

- (void)prepareToRecord {
	if (pthread_mutex_trylock(&_stateChangeMutex) != 0) {
		NSLog(@"Prepare to recording cancelled because state is already changing");
		return;
	}
	if (pthread_mutex_trylock(&_recordingMutex) != 0) {
		NSLog(@"Prepare to recording cancelled because video is already recording");
		pthread_mutex_unlock(&_stateChangeMutex);
        return;
	}
	[self tryPrepareToRecordAnd:NULL];
	pthread_mutex_unlock(&_recordingMutex);
	pthread_mutex_unlock(&_stateChangeMutex);
}

- (void)startRecording:(RecordingStartedCallback)callback {
	if (pthread_mutex_trylock(&_stateChangeMutex) != 0) {
		NSLog(@"Start of recording cancelled because state is already changing");
		return;
	}
    
	[self tryPrepareToRecordAnd:^(BOOL wasAlreadyPrepared){
		if (pthread_mutex_trylock(&_recordingMutex) != 0) {
			NSLog(@"Start of recording cancelled because video is already recording");
			pthread_mutex_unlock(&_stateChangeMutex);
			return;
		}

		double delayToStartRecording = 0.1;
		dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, delayToStartRecording * NSEC_PER_SEC);
		dispatch_after(startTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
			[self.movieWriter startRecording];

			[self performSelectorOnMainThread:@selector(recordingWasLaunched) withObject:nil waitUntilDone:YES];

//			if (callback != NULL) {
//				callback();
//			}

			//stopping writer too fast will produce exception
			dispatch_time_t reliefTime = dispatch_time(DISPATCH_TIME_NOW, VideoRecorderRelieveTime * NSEC_PER_SEC);
			dispatch_after(reliefTime, dispatch_get_main_queue(), ^(void){
				pthread_mutex_unlock(&_stateChangeMutex);
                if (callback != NULL) {
                    callback();
                }
			});
		});
	}];
}

- (void)stopRecording:(BOOL)cancel callback:(RecordingFinishedCallback)callback {
	if (pthread_mutex_trylock(&_stateChangeMutex) != 0) {
		NSLog(@"Stop of recording cancelled because state is already changing");
		return;
	}

	if (pthread_mutex_trylock(&_recordingMutex) == 0) {
		NSLog(@"Stop of recording cancelled because video is not recording");
		pthread_mutex_unlock(&_recordingMutex);
		pthread_mutex_unlock(&_stateChangeMutex);
		return;
	}

	[self performSelectorOnMainThread:@selector(recordingWillBeStopped) withObject:nil waitUntilDone:YES];

	if (cancel) {
		[self.movieWriter cancelRecording];
		pthread_mutex_unlock(&_recordingMutex);
		[self tryCompleteRecordingAnd:^{
			pthread_mutex_unlock(&_stateChangeMutex);
            if (callback != NULL) {
                callback(YES,nil);
            }
		}];
	}
	else {
		__block RecorderView *blockSelf = self;
		@try {
			[self.movieWriter finishRecordingWithCompletionHandler:^{
				//not main thread
				void (^block)(void) = ^{
					pthread_mutex_unlock(&_recordingMutex);
					[blockSelf tryCompleteRecordingAnd:^{
						blockSelf.videoIsRecordedInner = YES;
						pthread_mutex_unlock(&(blockSelf->_stateChangeMutex));
						if (callback != NULL) {
							callback(NO, self.pathToMovie);
						}
						blockSelf = nil;
					}];
				};

				if ([NSThread isMainThread]) {
					block();
				} else {
					dispatch_sync(dispatch_get_main_queue(), block);
				}

			}];
		}
		@catch (NSException *exception) {
			pthread_mutex_unlock(&_recordingMutex);
			[blockSelf tryCompleteRecordingAnd:^{
				pthread_mutex_unlock(&(blockSelf->_stateChangeMutex));
				if (callback != NULL) {
					callback(NO, nil);
				}
				NSLog(@"recording finished with exception");
				NSLog(@"%@",exception);
				blockSelf = nil;
			}];
		}
	}
}

- (void)updatePathToMovie {
	[self setNewPathToMovie];
	self.movieWriter = nil;
}

- (void)videoFileSupplied {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	self.videoIsRecordedInner = [fileManager fileExistsAtPath:self.pathToMovie];
}

- (void)forgetVideoFile {
	self.videoIsRecordedInner = NO;
	self.pathToMovie = nil;
}

- (void)deleteVideoFile {
	if ([self.pathToMovie length] != 0) {
		unlink([self.pathToMovie UTF8String]);
	}
	[self forgetVideoFile];
}

#pragma mark L1

@synthesize stateChangeMutex	= _stateChangeMutex;
@synthesize recordingMutex		= _recordingMutex;

@synthesize movieWriter = _movieWriter;

- (void)setMovieWriter:(GPUImageMovieWriter *)movieWriter {
#if defined(DEBUG)
	NSAssert(!self.isRecording, @"Should not change movie writer while recording");
#endif
	[self untargetMovieWriter];
	_movieWriter = movieWriter;
	[self targetMovieWriter];
}

@synthesize pictureWriter = _pictureWriter;

- (void)setPictureWriter:(GPUImagePictureWriter *)pictureWriter {
    [self untargetPictureWriter];
    _pictureWriter = pictureWriter;
    [self targetPictureWriter];
}

@synthesize pathToMovie = _pathToMovie;

- (void)tryPrepareToRecordAnd:(PreparationsDoneCallback)callback {
	if (dispatch_semaphore_wait(_prepareToRecordSemaphore, DISPATCH_TIME_NOW) != 0) {
		if (self.preparationsDoneCallback == NULL) {
			self.preparationsDoneCallback = callback;
		}
		return;
	}
    
	if (self.preparedToRecord) {
		if (callback != NULL) {
			callback(YES);
		}
        dispatch_semaphore_signal(_prepareToRecordSemaphore);
	} else {
		self.preparationsDoneCallback = callback;
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[self setPathToMovie:[[self class] generatePathToMovie]];
			self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:[NSURL fileURLWithPath:self.pathToMovie]
																		size:self.videoSize
																	fileType:self.videoFileType
															  outputSettings:self.videoOutputSettings];
//			self.movieWriter.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
			self.movieWriter.encodingLiveVideo = YES;
			self.thumb = nil;
			
			if (self.preparationsDoneCallback != NULL) {
				self.preparationsDoneCallback(NO);
			}
            dispatch_semaphore_signal(_prepareToRecordSemaphore);
		});
	}
}

- (void)tryCompleteRecordingAnd:(void (^)(void))callback {
	self.movieWriter = nil;

	if (callback != NULL) {
		callback();
	}
}

- (void)recordingWasLaunched {
}

- (void)recordingWillBeStopped {
}

- (void)setNewPathToMovie {
	[self setPathToMovie:[[self class] generatePathToMovie]];
}

#pragma mark L2

@synthesize prepareToRecordSemaphore = _prepareToRecordSemaphore;

@synthesize preparationsDoneCallback = _preparationsDoneCallback;

- (BOOL)preparedToRecord {
	return ((self.movieWriter != nil) && [self.videoCamera.targets containsObject:self.movieWriter] && (self.pathToMovie.length != 0));
}

@synthesize thumb = _thumb;

@synthesize videoSize			= _videoSize;
@synthesize videoFileType		= _videoFileType;
@synthesize videoOutputSettings	= _videoOutputSettings;

- (void)targetMovieWriter {
	if (!self.isRecording) {
		if (self.movieWriter != nil) {
			[self.videoCamera addTarget:self.movieWriter];
			self.videoCamera.audioEncodingTarget = self.movieWriter;
		}
	}
}

- (void)untargetMovieWriter {
	if (!self.isRecording) {
		[self.videoCamera removeTarget:self.movieWriter];
		if (self.videoCamera.audioEncodingTarget == self.movieWriter) {
			self.videoCamera.audioEncodingTarget = nil;
		}
	}
}

- (void)targetPictureWriter {
    if (self.pictureWriter != nil) {
//        [self.videoCamera addTarget:self.pictureWriter];
    }
}

- (void)untargetPictureWriter {
    [self.videoCamera removeTarget:self.pictureWriter];
}

- (void)setPathToMovie:(NSString *)pathToMovie {
	if (self.isRecording) {
		NSLog(@"Cannot change path while recording");
	} else {
		_pathToMovie = pathToMovie;
		unlink([_pathToMovie UTF8String]);
	}
}

#pragma mark - Inherited

#pragma mark NSObject

- (void)dealloc {
	pthread_mutex_destroy(&_stateChangeMutex);
	pthread_mutex_destroy(&_recordingMutex);
    if (_prepareToRecordSemaphore != NULL) {
//        dispatch_release(_prepareToRecordSemaphore);
    }
}

#pragma mark UIView

- (void)layoutSubviews {
    [super layoutSubviews];

    _videoSize = self.bounds.size;
    [_videoOutputSettings setObject:[NSNumber numberWithInt:(int)_videoSize.width] forKey:AVVideoWidthKey];
    [_videoOutputSettings setObject:[NSNumber numberWithInt:(int)_videoSize.height] forKey:AVVideoHeightKey];

    [self.pictureWriter setPictureSizeAsync:CGSizeMake(PICTURE_RESOLUTION_W, PICTURE_RESOLUTION_H)];
}

#pragma mark CaptureView

- (void)_commonInit {
	[super _commonInit];

	pthread_mutex_init(&_stateChangeMutex, NULL);
	pthread_mutex_init(&_recordingMutex, NULL);
    _prepareToRecordSemaphore = dispatch_semaphore_create(1);

//	_videoSize = CGSizeMake(320.0, 320.0);
    _videoSize = self.bounds.size;
	_videoFileType = AVFileTypeMPEG4;
	NSString *profile =	AVVideoProfileLevelH264Baseline30;

	CGFloat bitRate = WantedSizeBits / EstimatedDuration; //calculate or set bitrate

//	NSInteger keyInterval = NSIntegerMax; // as least keyframes as possible, must be integer
	NSInteger keyInterval = 180; // gp : not sure how much is it, but seems like it's better with this parameter set

	_videoOutputSettings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							AVVideoCodecH264,									AVVideoCodecKey,
							[NSNumber numberWithInt:(int)_videoSize.width],		AVVideoWidthKey,
							[NSNumber numberWithInt:(int)_videoSize.height],	AVVideoHeightKey,
							AVVideoScalingModeResizeAspect,					AVVideoScalingModeKey,
							[NSDictionary dictionaryWithObjectsAndKeys:
								[NSNumber numberWithInt:ceilf(bitRate)],			AVVideoAverageBitRateKey,
								[NSNumber numberWithInt:(int)keyInterval],				AVVideoMaxKeyFrameIntervalKey,
								profile,											AVVideoProfileLevelKey,
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									[NSNumber numberWithInt:(int)_videoSize.width],		AVVideoCleanApertureWidthKey,
//									[NSNumber numberWithInt:(int)_videoSize.height],	AVVideoCleanApertureHeightKey,
//									[NSNumber numberWithInt:0],							AVVideoCleanApertureHorizontalOffsetKey,
//									[NSNumber numberWithInt:0],							AVVideoCleanApertureVerticalOffsetKey,
//									nil],											AVVideoCleanApertureKey,
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									[NSNumber numberWithInt:3],							AVVideoPixelAspectRatioHorizontalSpacingKey,
//									[NSNumber numberWithInt:3],							AVVideoPixelAspectRatioVerticalSpacingKey,
//									nil],											AVVideoPixelAspectRatioKey,
							 nil],												AVVideoCompressionPropertiesKey,
							nil];

    self.pictureWriter = [[GPUImagePictureWriter alloc] initWithPictureSize:self.bounds.size];
    self.pictureWriter.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
}

- (void)stopCapture {
	if (self.isRecording) {
		[self stopRecording:YES callback:NULL];
	}
	[super stopCapture];
}

@end
