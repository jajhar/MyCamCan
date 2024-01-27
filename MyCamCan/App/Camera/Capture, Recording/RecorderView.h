#import "CaptureViewFlash.h"
#import "GPUImagePictureWriter.h"

extern const float VideoRecorderRelieveTime;

typedef void (^RecordingStartedCallback)(void);
typedef void (^RecordingFinishedCallback)(BOOL cancelled, NSString *pathToMovie);

@interface RecorderView : CaptureViewFlash {
@protected
	pthread_mutex_t _stateChangeMutex;
	pthread_mutex_t _recordingMutex;
}

@property (assign, nonatomic, readonly) BOOL isRecording;
@property (assign, nonatomic, readonly) BOOL videoIsRecorded;

@property (strong, nonatomic, readonly) NSString *pathToMovie;
@property (strong, nonatomic, readonly) NSString *pathToPicture;

@property (strong, nonatomic, readonly) UIImage *thumb;

+ (NSString *)generatePathToMovie;

- (void)capturePicture:(GPUImagePictureWriterCallback)callback;
- (void)prepareToRecord;
- (void)startRecording:(RecordingStartedCallback)callback;
- (void)stopRecording:(BOOL)cancel callback:(RecordingFinishedCallback)callback;

- (void)updatePathToMovie;
//use this method to update RecorderView after video was supplies to pathToMovie externally
- (void)videoFileSupplied;
- (void)forgetVideoFile;
- (void)deleteVideoFile;

@end
