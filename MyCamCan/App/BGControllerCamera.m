#import "BGControllerCamera.h"
#import "Media.h"
#import "MediaPlayerView.h"
#import "AppData.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "User.h"
#import "MusicItem.h"
#import "MBProgressHUD.h"
#import "Media_Uploads.h"
#import "DACircularProgressView.h"
#import "BGTouchDownGestureRecognizer.h"
#import "BGTouchUpGestureRecognizer.h"
#import "CIColorInvert.h"
#import "SDAVAssetExportSession.h"
#import <QuartzCore/QuartzCore.h>

@import Firebase;

NSString *kBGControllerCamera = @"BGControllerCamera";
NSString *kBGInfoCameraAmbientSoundFlag = @"BGInfoCameraAmbientSoundFlag";

@interface BGControllerCamera () <AVAudioPlayerDelegate>
{
    SCRecorder *_recorder;
    BOOL _isTouchDown;
    NSTimer *_musicPlayerTimer;
    BOOL _isProcessing;
    BOOL _recordingStarted;
}

@property (weak, nonatomic) IBOutlet UIButton *flipCameraButton;
@property (strong, nonatomic) IBOutlet UIView *previewView;
@property (strong, nonatomic) MusicItem *musicItem;
@property (strong, nonatomic) IBOutlet MediaPlayerView *mediaPlayer;
@property (strong, nonatomic) AVAudioPlayer *musicPlayer;
@property (strong, nonatomic) IBOutlet UIButton *postButton;
@property (strong, nonatomic) IBOutlet UIButton *nextButton;
@property (strong, nonatomic) IBOutlet UIView *backgroundProgressView;
@property (weak, nonatomic) IBOutlet UIButton *undoButton;
@property (strong, nonatomic) IBOutlet SCSwipeableFilterView *filterView;
@property (strong, nonatomic) IBOutlet UILabel *filterNameLabel;
@property (strong, nonatomic) IBOutlet UIImageView *audioPlot;
@property (strong, nonatomic) IBOutlet UIImageView *bottomAudioPlot;
@property (weak, nonatomic) IBOutlet UIView *toolTipViewOne;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *audioPlotWidthConstraint;

@property (strong, nonatomic) DACircularProgressView *uploadProgressView;
@property (weak, nonatomic) IBOutlet UIView *audioView;

@property (strong, nonatomic) Media *localMedia;


@property (nonatomic) CGFloat currentAudioViewOffset;
@property (strong, nonatomic) UIView *currentAudioPlotView;
@property (strong, nonatomic) NSMutableArray *audioPlotViews;

@end

@implementation BGControllerCamera


#pragma mark L1

- (IBAction)dismissToolTipViewPressed:(id)sender {
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.toolTipViewOne.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         self.toolTipViewOne.hidden = YES;
                     }];
}


- (IBAction)shootTouchDown:(id)sender {
    
    [FIRAnalytics logEventWithName:@"video_recording_started"
                        parameters:@{
                                     @"user":[NSString stringWithFormat:@"USER_ID_%@", [AppData sharedInstance].localUser.theId],
                                     @"song_title": self.musicItem.title,
                                     @"song_artist": self.musicItem.artist,
                                     }];
    
    // This allows audio to be played while video is being recorded
//    AVAudioSession *session = [AVAudioSession sharedInstance];
//    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
//    [session setActive:YES error:nil];
    
    if(_isTouchDown) {
        [self shootTouchUp:sender];
        return;
    }
    
    _isTouchDown = YES;
    
    if(!_recordingStarted) {
        _recordingStarted = YES;
        
        _musicPlayerTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                             target:self
                                                           selector:@selector(checkPlayTime)
                                                           userInfo:nil
                                                            repeats:YES];
        
        [self.musicPlayer setCurrentTime:self.musicItem.startTime];
    }
    
    self.currentAudioViewOffset = ceil(CGRectGetMaxX(self.currentAudioPlotView.frame));
    
    if (self.audioPlotViews.count > 0) {
        // Add some space between segments
        self.currentAudioViewOffset += 1.0;
    }
    
    UIView *coloredView = [[UIView alloc] initWithFrame:CGRectMake(self.currentAudioViewOffset, 0, 0, self.audioView.frame.size.height)];
    self.currentAudioPlotView = coloredView;
    coloredView.translatesAutoresizingMaskIntoConstraints = YES;
    [coloredView setBackgroundColor:[UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1.0]];
    [self.audioView addSubview:coloredView];
    
    [self.audioPlotViews addObject:coloredView];
    
    // Begin appending video/audio buffers to the session
    [_recorder record];

    [self.musicPlayer play];
}

- (IBAction)shootTouchUp:(id)sender {
    
    [FIRAnalytics logEventWithName:@"video_recording_stopped"
                        parameters:@{
                                     @"user":[NSString stringWithFormat:@"USER_ID_%@", [AppData sharedInstance].localUser.theId],
                                     @"song_title": self.musicItem.title,
                                     @"song_artist": self.musicItem.artist,
                                     }];
    
    _isTouchDown = NO;
    
    [_recorder pause];

    [self.musicPlayer pause];
    
    [self.undoButton setHidden:self.audioPlotViews.count == 0];
    [self.nextButton setHidden:self.audioPlotViews.count == 0];
}

- (IBAction)cancel:(id)sender {
    
    
    if (self.localMedia.mediaUrl != nil) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Wait!" message:@"If you leave now your video will be erased.\nAre you sure?" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            
            [FIRAnalytics logEventWithName:@"video_discarded"
                                parameters:@{
                                             @"user":[NSString stringWithFormat:@"USER_ID_%@", [AppData sharedInstance].localUser.theId],
                                             }];
            
            CATransition *transition = [CATransition animation];
            transition.duration = 0.3;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            transition.type = kCATransitionFade;
            [self.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];
            
            [self.navigationController popViewControllerAnimated:NO];
        }];
        
        UIAlertAction *stopAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:nil];
        
        [alertController addAction:cancelAction];
        [alertController addAction:stopAction];
        
        [self presentViewController:alertController animated:YES completion:nil];

    } else {
        
        CATransition *transition = [CATransition animation];
        transition.duration = 0.3;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        [self.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];
        
        [self.navigationController popViewControllerAnimated:NO];
    }
}

- (IBAction)exportVideoPressed:(id)sender {
    
    _isProcessing = NO;
    _isTouchDown = NO;
    
    [self.musicPlayer pause];
    [_recorder pause];
    [_recorder stopRunning];
    
    [_musicPlayerTimer invalidate];
    _musicPlayerTimer = nil;

    [self saveVideoAndContinue];
}

- (IBAction)flipCamera:(id)sender {
    [_recorder switchCaptureDevices];

}


//- (void)compressVideo:(NSURL*)inputURL outputURL:(NSURL*)outputURL handler:(void (^)(AVAssetExportSession*))handler
//{
//    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
//    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
//    
//    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
//    exportSession.outputURL = outputURL;
//    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
//    exportSession.shouldOptimizeForNetworkUse = YES;
//
//    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
//         handler(exportSession);
//    }];
//    
//}

- (IBAction)postPressed:(id)sender {
    
    self.postButton.enabled = NO;
    
    [self.mediaPlayer pause];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"What would you like to do?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *uploadAction = [UIAlertAction actionWithTitle:@"Upload video" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self uploadVideo];
    }];
    UIAlertAction *saveAction = [UIAlertAction actionWithTitle:@"Save to camera roll" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        _isProcessing = NO;
        [self saveVideoToCameraRoll];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
   
    [alert addAction:uploadAction];
    [alert addAction:saveAction];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)uploadVideo {
    
    [self.localMedia generateUploadFileName];
    
    [FIRAnalytics logEventWithName:@"video_uploaded"
                        parameters:@{
                                     @"user":[NSString stringWithFormat:@"USER_ID_%@", [AppData sharedInstance].localUser.theId],
                                     @"file_name":self.localMedia.uploadFileName,
                                     @"video_length": [NSString stringWithFormat:@"%f", (self.musicItem.endTime - self.musicItem.startTime)],
                                     @"song_title": self.musicItem.title,
                                     @"song_artist": self.musicItem.artist,
                                     kFIRParameterContentType:@"video"
                                     }];
    
    __block BGControllerCamera *blockSelf = self;
    
    [_uploadProgressView removeFromSuperview];
    _uploadProgressView = [[DACircularProgressView alloc] initWithFrame:CGRectMake(0.0, 0.0, 80.0, 80.0)];
    [_uploadProgressView setCenter:self.view.center];
    _uploadProgressView.autoresizingMask = UIViewAutoresizingNone;
    _uploadProgressView.roundedCorners = YES;
    _uploadProgressView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_uploadProgressView];
    [self.view bringSubviewToFront:self.uploadProgressView];
    [self.uploadProgressView setProgress:0.0];
    
    self.backgroundProgressView.hidden = NO;
    
    if ( [[NSFileManager defaultManager] isReadableFileAtPath:[self.localMedia.mediaUrl path]] ) {
        [[NSFileManager defaultManager] copyItemAtURL:self.localMedia.mediaUrl toURL:self.localMedia.localFileURL error:nil];
    }
    
    //    NSURL *compressedURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@-compressed.mov", self.localMedia.localFileURL.absoluteString]];
    
    //    [self compressVideo:self.localMedia.localFileURL
    //              outputURL:compressedURL
    //                handler:^(AVAssetExportSession *session) {
    
    //                    if (session.error != nil) {
    //                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Uh oh!" message:@"Uploading Failed! Please try again." preferredStyle:UIAlertControllerStyleAlert];
    //
    //                        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    //                        [alertController addAction:ok];
    //
    //                        [self presentViewController:alertController animated:YES completion:nil];
    //                        return;
    //                    }
    
    //                    self.localMedia.localFileURL = compressedURL;
    //                    self.localMedia.mediaUrl = compressedURL;
    
    
    [APICommunication uploadMedia:blockSelf.localMedia
                          fileURL:self.localMedia.mediaUrl
                           forKey:self.localMedia.uploadFileName
                       completion:^(NSData *data) {
                           
                           [APICommunication saveMediaToDatabase:blockSelf.localMedia
                                                        filename:blockSelf.localMedia.uploadFileName
                                                       thumbName:blockSelf.localMedia.thumbName
                                                      completion:^(NSData *data) {
                                                          
                                                          NSDictionary *mediaDict = [[APICommunication convertJsonToDictionary:data] objectForKey:@"media"];
                                                          
                                                          blockSelf.postButton.enabled = YES;

                                                          Media *media = [[AppData sharedInstance] getMediaFromPoolWithInfo:mediaDict];
                                                          
                                                          if (media) {
                                                              
                                                              media.localFileURL = blockSelf.localMedia.localFileURL;
                                                              media.uploadFileName = blockSelf.localMedia.uploadFileName;
                                                              
                                                              
                                                              [[AppData sharedInstance].localUser.feedPager addElement:media toFilter:kBGFeedFilterDefault atIndex:0];
                                                              [[AppData sharedInstance].localUser.feedPager addElement:media toFilter:kBGFeedFilterGlobal atIndex:0];
                                                              [[AppData sharedInstance].localUser.feedPager addElement:media toFilter:kBGFeedFilterProfile atIndex:0];
                                                              
                                                              [[NSNotificationCenter defaultCenter] postNotificationName:kAppData_Notification_FeedChanged
                                                                                                                  object:nil
                                                                                                                userInfo:@{kAppData_NotificationKey_User: [AppData sharedInstance].localUser,
                                                                                                                           @"FeedFilter": [NSNumber numberWithInteger:kBGFeedFilterDefault],
                                                                                                                           kAppData_NotificationKey_TotalFlag: @(YES)}];
                                                              
                                                              [[NSNotificationCenter defaultCenter] postNotificationName:kAppData_Notification_FeedChanged
                                                                                                                  object:nil
                                                                                                                userInfo:@{kAppData_NotificationKey_User: [AppData sharedInstance].localUser,
                                                                                                                           @"FeedFilter": [NSNumber numberWithInteger:kBGFeedFilterGlobal],
                                                                                                                           kAppData_NotificationKey_TotalFlag: @(YES)}];
                                                          }
                                                          
                                                          [blockSelf.navigationController popToRootViewControllerAnimated:NO];
                                                          [[AppData sharedInstance].navigationManager presentControllerForPurpose:kBGPurposePostEdit info:@{kVXKeyMedia: media} showTabBar:NO];
                                                          
                                                      } failure:^(NSError *error) {
                                                          
                                                          [blockSelf.uploadProgressView removeFromSuperview];
                                                          blockSelf.backgroundProgressView.hidden = YES;
                                                          blockSelf.postButton.enabled = YES;
                                                          
                                                          NSLog(@"Error: %@", error);
                                                          
                                                          UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Uh oh!" message:@"Uploading Failed! Please try again." preferredStyle:UIAlertControllerStyleAlert];
                                                          
                                                          UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                                                          [alertController addAction:ok];
                                                          
                                                          [blockSelf presentViewController:alertController animated:YES completion:nil];
                                                      }];
                           
                       } progress:^(float progress, float progressSoFar, float length) {
                           
                           NSLog(@"upload progress: %f", progress);
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                               [blockSelf.uploadProgressView setProgress:progress animated:NO];
                           });
                           
                       } failure:^(NSError *error) {
                           NSLog(@"Error: %@", error);
                           self.postButton.enabled = YES;
                           [self.uploadProgressView removeFromSuperview];
                           self.backgroundProgressView.hidden = YES;
                           
                           UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Uh oh!" message:@"Uploading Failed! Please try again." preferredStyle:UIAlertControllerStyleAlert];
                           
                           UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                           [alertController addAction:ok];
                           
                           [blockSelf presentViewController:alertController animated:YES completion:nil];
                       }];
    //    }];

}

- (IBAction)flashPressed:(id)sender {

    if ([_recorder.captureSessionPreset isEqualToString:AVCaptureSessionPresetPhoto]) {
       
        switch (_recorder.flashMode) {
            case SCFlashModeAuto:
                _recorder.flashMode = SCFlashModeOff;
                break;
            case SCFlashModeOff:
                _recorder.flashMode = SCFlashModeOn;
                break;
            case SCFlashModeOn:
                _recorder.flashMode = SCFlashModeLight;
                break;
            case SCFlashModeLight:
                _recorder.flashMode = SCFlashModeAuto;
                break;
            default:
                break;
        }
        
    } else {
        
        switch (_recorder.flashMode) {
            case SCFlashModeOff:
                _recorder.flashMode = SCFlashModeLight;
                break;
            case SCFlashModeLight:
                _recorder.flashMode = SCFlashModeOff;
                break;
            default:
                break;
        }
    }
}

- (IBAction)undoButtonPressed:(id)sender {
   
    if (_recorder.isRecording) {
        return;
    }
    
    [_recorder.session removeLastSegment];
    [self adjustMusicNewTime:[_recorder.session segmentsDuration]];
    
    self.currentAudioViewOffset -= CGRectGetWidth(self.currentAudioPlotView.frame) - 1;

    [self.currentAudioPlotView removeFromSuperview];
    [self.audioPlotViews removeLastObject];
    
    self.currentAudioPlotView = [self.audioPlotViews lastObject];
    
    [self.undoButton setHidden:self.audioPlotViews.count == 0];
    [self.nextButton setHidden:self.audioPlotViews.count == 0];
}

#pragma mark - Helpers

- (void)adjustMusicNewTime:(CMTime)time {
    
    [self.musicPlayer setCurrentTime:self.musicItem.startTime + CMTimeGetSeconds(time)];
}

- (void)resetMusicProgressBar {
    self.audioPlotWidthConstraint.constant = 0;
}

- (void)prepareSession {
    if (_recorder.session == nil) {
        
        SCRecordSession *session = [SCRecordSession recordSession];
        session.fileType = AVFileTypeQuickTimeMovie;
        
        _recorder.session = session;
    }
}

- (void)saveVideoAndContinue {
    if(_isProcessing) {
        return;
    }
    
    _isProcessing = YES;
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    if ([[NSTimer class] respondsToSelector:@selector(scheduledTimerWithTimeInterval:repeats:block:)]) {
        // Allows time for SCRecorder to save the video segments
        [NSTimer scheduledTimerWithTimeInterval:2.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
            [self saveVideo];
        }];
    } else {
        // fallback to ios 9 API
        [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(saveVideo) userInfo:nil repeats:NO];
    }
}

- (void)saveVideo {
    
    __block BGControllerCamera *blockSelf = self;
    
    // Merge all the segments into one file using an AVAssetExportSession
    [_recorder.session mergeSegmentsUsingPreset:AVAssetExportPresetHighestQuality completionHandler:^(NSURL *url, NSError *error) {
        
        if (error == nil) {
            
            dispatch_async(dispatch_get_main_queue(), ^{

                Media *videoMedia = [Media mediaWithMovieAtPath:[url path]];
                videoMedia.musicItem = blockSelf.musicItem;
                
                blockSelf.localMedia = videoMedia;
                
    //            [blockSelf saveVideoToCameraRoll];
                [blockSelf mergeAndSave];
            });
            
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                NSLog(@"Failed to merge video segments: %@", error);
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Uh Oh!" message:@"Failed to generate video." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *action = [UIAlertAction actionWithTitle:@"Try again" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    _isProcessing = NO;
                    [self saveVideoAndContinue];
                }];
                UIAlertAction *saveAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    _isProcessing = NO;
                }];
                [alert addAction:action];
                [alert addAction:saveAction];
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
    }];

}

-(void)mergeAndSave
{
    //Create AVMutableComposition Object which will hold our multiple AVMutableCompositionTrack or we can say it will hold our video and audio files.
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    //Now first load your audio file using AVURLAsset. Make sure you give the correct path of your videos.
    NSURL *audio_url;
    if(![self.musicItem.localFileURL isFileURL]) {
        NSLog(@"ERROR: unable to merge audio. Music item URL is not a file URL: %@", self.musicItem.localFileURL);
        return;
    } else {
        audio_url = self.musicItem.localFileURL;
    }
    
    //Now we will load video file.
    NSURL *video_url = self.localMedia.mediaUrl;
    AVURLAsset *videoAsset = [[AVURLAsset alloc]initWithURL:video_url options:nil];
    
    AVURLAsset *audioAsset = [[AVURLAsset alloc]initWithURL:audio_url options:nil];
    CMTimeRange audio_timeRange = CMTimeRangeMake(CMTimeMake(self.musicItem.startTime, 1), videoAsset.duration);
    CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    
    //Now we are creating the first AVMutableCompositionTrack containing our audio and add it to our AVMutableComposition object.
    AVMutableCompositionTrack *music_compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                         preferredTrackID:kCMPersistentTrackID_Invalid];
    
    if ([audioAsset tracksWithMediaType:AVMediaTypeAudio].count > 0) {
        
        [music_compositionAudioTrack insertTimeRange:audio_timeRange
                                             ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                                              atTime:kCMTimeZero error:nil];
    }
    
    //Now we are creating the second AVMutableCompositionTrack containing our video and add it to our AVMutableComposition object.
    AVMutableCompositionTrack *video_compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                         preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [video_compositionVideoTrack insertTimeRange:video_timeRange
                                         ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                          atTime:kCMTimeZero error:nil];
    
    NSMutableArray *audioMixInputArray = [NSMutableArray new];
    
    // The volume that the music will begin at when it starts to fade out at the end of the video.
    CGFloat fadeOutBeginInSeconds = CMTimeGetSeconds(videoAsset.duration) > 3 ? CMTimeGetSeconds(videoAsset.duration) : 0;
    CMTime fadeOutBegin = CMTimeMakeWithSeconds(fadeOutBeginInSeconds - 3.0, 1);

    if (self.recordAmbientSound) {
        
        // If the user opted to record ambient sounds in the vidoe, add the video's audio track as well
        AVMutableCompositionTrack *audio_compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                             preferredTrackID:kCMPersistentTrackID_Invalid];
        
        [audio_compositionVideoTrack insertTimeRange:video_timeRange
                                             ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                                              atTime:kCMTimeZero error:nil];
        
        // Set music to half volume so ambient sound takes precedence
        AVMutableAudioMixInputParameters *audioMixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:music_compositionAudioTrack];
        
        CMTime volumeBegin = CMTimeMakeWithSeconds(0, 1);
        
        NSLog(@"duration: %f", CMTimeGetSeconds(videoAsset.duration));
        
        [audioMixParameters setVolume:2 atTime:volumeBegin];

        // Fade out the music 3 seconds from the end...
        [audioMixParameters setVolumeRampFromStartVolume:2
                                             toEndVolume:0.0
                                               timeRange: CMTimeRangeMake(fadeOutBegin, CMTimeMake(3.0, 1))];
        
        [audioMixInputArray addObject:audioMixParameters];
        
        // Configure the ambient noise track
        AVMutableAudioMixInputParameters *ambientMixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audio_compositionVideoTrack];
        
        [ambientMixParameters setVolume:10.0 atTime:volumeBegin];

        // Fade out the ambient audio 3 seconds from the end...
        [ambientMixParameters setVolumeRampFromStartVolume:10.0
                                             toEndVolume:0.0
                                               timeRange: CMTimeRangeMake(fadeOutBegin, CMTimeMake(3.0, 1))];
        
        [audioMixInputArray addObject:ambientMixParameters];
        
    } else {
        
        // Fade out the music 3 seconds from the end...
        AVMutableAudioMixInputParameters *audioMixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:music_compositionAudioTrack];
        
        [audioMixParameters setVolumeRampFromStartVolume:1.0
                                             toEndVolume:0.0
                                               timeRange: CMTimeRangeMake(fadeOutBegin, CMTimeMake(3.0, 1))];
        
        [audioMixInputArray addObject:audioMixParameters];
    }
    
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = audioMixInputArray;

    //decide the path where you want to store the final video created with audio and video merge.
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *outputFilePath = [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"FinalVideo-%d.mov", (int)[[NSDate date] timeIntervalSince1970]]];
    NSString *copyFilePath = [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"FinalVideoCopy-%d.mov", (int)[[NSDate date] timeIntervalSince1970]]];
    
    NSURL *outputFileUrl = [NSURL fileURLWithPath:outputFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputFilePath])
        [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
    
    NSURL *copyFileURL = [NSURL fileURLWithPath:copyFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:copyFilePath])
        [[NSFileManager defaultManager] removeItemAtPath:copyFilePath error:nil];

    self.localMedia.localFileURL = copyFileURL;
    
    SDAVAssetExportSession *encoder = [SDAVAssetExportSession.alloc initWithAsset:mixComposition];
    encoder.outputFileType = AVFileTypeMPEG4;
    encoder.outputURL = outputFileUrl;
    encoder.audioMix = audioMix;
    encoder.shouldOptimizeForNetworkUse = YES;
    
    encoder.videoSettings = @
    {
        AVVideoCodecKey: AVVideoCodecH264,
        AVVideoWidthKey: @640,
        AVVideoHeightKey: @1136,
        AVVideoCompressionPropertiesKey: @
            {
                AVVideoAverageBitRateKey: @3000000,
//                AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
            },
    };
    encoder.audioSettings = @
    {
        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        AVNumberOfChannelsKey: @2,
        AVSampleRateKey: @44100,
        AVEncoderBitRateKey: @128000,
    };
    
    [encoder exportAsynchronouslyWithCompletionHandler:^
    {
        dispatch_async(dispatch_get_main_queue(), ^{

             [MBProgressHUD hideAllHUDsForView:self.view animated:YES];

             if(encoder.status == AVAssetExportSessionStatusCompleted){
                 self.localMedia.mediaUrl = outputFileUrl;

                 [self exportDidFinish];

//                 [self addWaterMarkToVideo:self.localMedia.mediaUrl];

             } else {
                 NSLog(@"ERROR: %@", encoder.error);

                 UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Uh oh!" message:@"Something went wrong. Tap to retry" preferredStyle:UIAlertControllerStyleAlert];

                 UIAlertAction* ok = [UIAlertAction actionWithTitle:@"Retry" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                     [self mergeAndSave];
                 }];
                 
                 UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil];
                 
                 [alertController addAction:ok];
                 [alertController addAction:cancel];
                 
                 [self presentViewController:alertController animated:YES completion:nil];
                 
             }             
         });
    }];
}

- (void)addWaterMarkToVideo:(NSURL *)videoURL {
    
    [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    
    [Media addWaterMarkToVideo:videoURL completion:^(NSURL *url, NSError *error) {
        if(!error) {
             NSURLSessionTask *download = [[NSURLSession sharedSession] downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                 NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] firstObject];
                 NSURL *tempURL = [documentsURL URLByAppendingPathComponent:[url lastPathComponent]];
                 [[NSFileManager defaultManager] moveItemAtURL:location toURL:tempURL error:nil];
                 UISaveVideoAtPathToSavedPhotosAlbum(tempURL.path, self,  @selector(video:finishedSavingWithError:contextInfo:), @selector(video:finishedSavingWithError:contextInfo:));
             }];
             
             [download resume];
        } else {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Uh oh!" message:@"Failed to save video. Please try again." preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:ok];
            
            [self presentViewController:alertController animated:YES completion:nil];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
        });
    }];

}

- (void)exportDidFinish
{
    NSLog(@"video url: %@", self.localMedia.mediaUrl);
    
    self.mediaPlayer.hidden = NO;
    [self.mediaPlayer setMedia:self.localMedia];
    
    self.undoButton.hidden = YES;
    self.audioPlot.hidden = YES;
    self.audioView.hidden = YES;
    self.bottomAudioPlot.hidden = YES;
    self.nextButton.hidden = YES;
    self.flipCameraButton.hidden = YES;
    self.postButton.hidden = NO;
    
    _isProcessing = NO;
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
}

- (void)saveVideoToCameraRoll {
    if (!self.localMedia.mediaUrl) { return; }
    
    [FIRAnalytics logEventWithName:@"saved_video"
                        parameters:@{
                                     @"user":[NSString stringWithFormat:@"USER_ID_%@", [AppData sharedInstance].localUser.theId],
                                     @"video_length": [NSString stringWithFormat:@"%f", (self.musicItem.endTime - self.musicItem.startTime)],
                                     @"song_title": self.musicItem.title,
                                     @"song_artist": self.musicItem.artist,
                                     kFIRParameterContentType:@"video"
                                     }];
    
    [self addWaterMarkToVideo:self.localMedia.mediaUrl];
}

- (void)video:(NSString *)videoPath finishedSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if(error) {
        NSLog(@"Failed to save the video to camera roll");
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Uh oh!" message:@"Failed to save video. Please try again." preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        
        [self presentViewController:alertController animated:YES completion:nil];

    } else {
        NSLog(@"Saved the video to camera roll");
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Success!" message:@"Video saved" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }];
        
        [alertController addAction:ok];
        
        [self presentViewController:alertController animated:YES completion:nil];

    }
}

#pragma mark - Inherited

#pragma mark UIViewController

- (void)setInfo:(NSDictionary *)info animated:(BOOL)animated {
    [super setInfo:info animated:animated];
    
    self.musicItem = [info objectForKey:kBGInfoMusicItem];
    
    if ([info objectForKey:kBGInfoCameraAmbientSoundFlag]) {
        
        self.recordAmbientSound = [[info objectForKey:kBGInfoCameraAmbientSoundFlag] boolValue];
    }
    
}

- (void)dealloc {
    [self.musicPlayer pause];
//    [self.musicPlayer removeAllItems];
    self.musicPlayer = nil;
    [self.filterView removeObserver:self forKeyPath:@"selectedFilter"];
    self.filterView = nil;
    [self.mediaPlayer pause];
    [_recorder stopRunning];
    _recorder = nil;
    [_musicPlayerTimer invalidate];
    _musicPlayerTimer = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.mediaPlayer pause];
    [_musicPlayerTimer invalidate];
    _musicPlayerTimer = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.postButton.clipsToBounds = YES;
    
    self.audioPlotViews = [NSMutableArray new];
    
    self.nextButton.clipsToBounds = YES;
    self.nextButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.nextButton.layer.borderWidth = 1.0;
    [self.nextButton setHidden:YES];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if([defaults objectForKey:@"hasViewedCameraToolTip"] != nil &&
       [[defaults objectForKey:@"hasViewedCameraToolTip"] boolValue])
    {
        self.toolTipViewOne.hidden = YES;
    } else {
        self.toolTipViewOne.hidden = NO;
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"hasViewedCameraToolTip"];
    }

    [self.undoButton setHidden:YES];
    
    self.navigationItem.hidesBackButton = YES;

    // Audio Player
    self.musicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.musicItem.localFileURL error:nil];
    self.musicPlayer.currentTime = self.musicItem.startTime;
    
    self.musicPlayer.delegate = self;
    
    if (self.musicItem.endTime > self.musicPlayer.duration) {
        self.musicItem.endTime = self.musicPlayer.duration;
    }
    
    if (self.recordAmbientSound) {
        // If the user opted to record ambient sound, set the music player's volume to 0 so it doesn't interfere with recording.
        self.musicPlayer.volume = 0.0;
    }
    
    _isProcessing = NO;
    _recordingStarted = NO;
    
    UITapGestureRecognizer *touchDown = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shootTouchDown:)];
    [self.filterView addGestureRecognizer:touchDown];
//    BGTouchUpGestureRecognizer *touchUp = [[BGTouchUpGestureRecognizer alloc] initWithTarget:self action:@selector(shootTouchUp:)];
//    [self.filterView addGestureRecognizer:touchUp];
    
    self.audioPlot.image = [self.audioPlot.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.audioPlot setTintColor:[UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1.0]];
    
    [self resetMusicProgressBar];
    
    // get top image from camera roll and set it as the roll button background
//    [self displayTopRollImage];
    
    _recorder = [SCRecorder recorder];
    _recorder.captureSessionPreset = [SCRecorderTools bestCaptureSessionPresetCompatibleWithAllDevices];
//    _recorder.maxRecordDuration = CMTimeMake((self.musicItem.endTime - self.musicItem.startTime), 1);
//    _recorder.fastRecordMethodEnabled = YES;
    _recorder.autoSetVideoOrientation = NO;
    _recorder.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    _recorder.delegate = self;
    
    // Get the video configuration object
    SCVideoConfiguration *video = _recorder.videoConfiguration;
    
    // Whether the video should be enabled or not
    video.enabled = YES;
    // The bitrate of the video video
//    video.bitrate = 1000000; // Mbit/s
    
//    video.preset = SCPresetHighestQuality;
    // Size of the video output
//    video.size = CGSizeMake(1920, 1080);
    // Scaling if the output aspect ratio is different than the output one
    video.scalingMode = AVVideoScalingModeResizeAspect;
    // The timescale ratio to use. Higher than 1 makes a slow motion, between 0 and 1 makes a timelapse effect
//    video.timeScale = 1;
    // Whether the output video size should be infered so it creates a square video
//    video.sizeAsSquare = NO;
    
    _recorder.previewView = self.previewView;
    
    // Get the audio configuration object
    SCAudioConfiguration *audio = _recorder.audioConfiguration;
    
    // Whether the audio should be enabled or not
    audio.enabled = self.recordAmbientSound;
    
    _recorder.initializeSessionLazily = NO;
    
    NSError *error;
    if (![_recorder prepare:&error]) {
        NSLog(@"Prepare error: %@", error.localizedDescription);
    }
    
    // Start running the flow of buffers
    if (![_recorder startRunning]) {
        NSLog(@"Unable to start recorder: %@", _recorder.error);
    }
    
    // These lines fix an issue with SCRecorder filters rendering on live video: https://github.com/rFlex/SCRecorder/issues/182
    CIImage *dummyImage = [CIImage imageWithColor:[CIColor colorWithRed:0 green:0 blue:0]];
    CIFilter *cropFilter = [CIFilter filterWithName:@"CICrop" withInputParameters:@{@"inputImage": dummyImage,
                                                                                    @"inputRectangle": [CIVector vectorWithCGRect:self.view.bounds]
                                                                                    }];
    _filterView.CIImage = cropFilter.outputImage;
    
    if ([[NSProcessInfo processInfo] activeProcessorCount] > 1) {
        _filterView.refreshAutomaticallyWhenScrolling = NO;
        _filterView.contentMode = UIViewContentModeScaleAspectFill;
        
        SCFilter *emptyFilter = [SCFilter emptyFilter];
        emptyFilter.name = @"#nofilter";
        
//        SCFilter *filter = [SCFilter filterWithCIFilterName:@"CIVignetteEffect"];
//        [filter setValue:[CIVector vectorWithCGPoint:self.view.center] forKey:@"inputCenter"];
        
        _filterView.filters = @[
                                            emptyFilter,
//                                            [SCFilter filterWithCIFilter:[CIColorInvert new]],
                                            [SCFilter filterWithCIFilterName:@"CIPhotoEffectNoir"],
                                            [SCFilter filterWithCIFilterName:@"CIPhotoEffectChrome"],
                                            [SCFilter filterWithCIFilterName:@"CIPhotoEffectInstant"],
                                            [SCFilter filterWithCIFilterName:@"CIPhotoEffectTonal"],
                                            [SCFilter filterWithCIFilterName:@"CIPhotoEffectFade"],
                                            [SCFilter filterWithCIFilterName:@"CISepiaTone"],
//                                            [SCFilter filterWithCIFilterName:@"CISixfoldReflectedTile"],
//                                            [SCFilter filterWithCIFilterName:@"CIVignetteEffect"],
//                                            [SCFilter filterWithCIFilterName:@"CIZoomBlur"],
//                                            filter
                                            ];
        
        _recorder.CIImageRenderer = _filterView;
        [_filterView addObserver:self forKeyPath:@"selectedFilter" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    [self prepareSession];

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.filterView) {
        
//        _recorder.videoConfiguration.filter = [SCFilter filterWithFilters:<#(NSArray * _Nonnull)#>:@"CISharpenLuminance"];
        _recorder.videoConfiguration.filter = self.filterView.selectedFilter;
        
        self.filterNameLabel.hidden = NO;
        self.filterNameLabel.text = self.filterView.selectedFilter.name;
        self.filterNameLabel.alpha = 0;
        [UIView animateWithDuration:0.3 animations:^{
            self.filterNameLabel.alpha = 1;
        } completion:^(BOOL finished) {
            if (finished) {
                [UIView animateWithDuration:0.3 delay:1 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                    self.filterNameLabel.alpha = 0;
                } completion:^(BOOL finished) {
                    
                }];
            }
        }];
    }
}

- (void)recorder:(SCRecorder *)recorder didSkipVideoSampleBufferInSession:(SCRecordSession *)recordSession {
    NSLog(@"Skipped video buffer");
}

- (void)recorder:(SCRecorder *)recorder didReconfigureAudioInput:(NSError *)audioInputError {
    NSLog(@"Reconfigured audio input: %@", audioInputError);
}

- (void)recorder:(SCRecorder *)recorder didReconfigureVideoInput:(NSError *)videoInputError {
    NSLog(@"Reconfigured video input: %@", videoInputError);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self.view bringSubviewToFront:_postButton];
    [_recorder previewViewFrameChanged];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.musicPlayer pause];
//    [self.musicPlayer removeAllItems];
    
    [MediaPlayerView pauseLastActivePlayer];

}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSURL *url = info[UIImagePickerControllerMediaURL];
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    SCRecordSessionSegment *segment = [SCRecordSessionSegment segmentWithURL:url info:nil];
    
    [_recorder.session addSegment:segment];
}

//- (void)displayTopRollImage {
//
//    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
//    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
//                                 usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
//                                     if (nil != group) {
//                                         // be sure to filter the group so you only get photos
//                                         [group setAssetsFilter:[ALAssetsFilter allPhotos]];
//                                         
//                                         
//                                         [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:group.numberOfAssets - 1]
//                                                                 options:0
//                                                              usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
//                                                                  if (nil != result) {
//                                                                      ALAssetRepresentation *repr = [result defaultRepresentation];
//                                                                      // this is the most recent saved photo
//                                                                      UIImage *img = [UIImage imageWithCGImage:[repr fullResolutionImage]];
//                                                                      [self.cameraRollButton setImage:img forState:UIControlStateNormal];
//                                                                      // we only need the first (most recent) photo -- stop the enumeration
//                                                                      *stop = YES;
//                                                                  }
//                                                              }];
//                                     }
//                                     
//                                     *stop = NO;
//                                 } failureBlock:^(NSError *error) {
//                                     NSLog(@"error: %@", error);
//                                 }];
//}

- (void)recorder:(SCRecorder *)recorder didCompleteSession:(SCRecordSession *)session {
    
}

-(void)itemDidFinishPlaying:(NSNotification *) notification {
    // Will be called when AVPlayer finishes playing playerItem
    [self finishRecording];
}

- (void)finishRecording {
    
    [FIRAnalytics logEventWithName:@"video_recorded"
                        parameters:@{
                                     @"user":[NSString stringWithFormat:@"USER_ID_%@", [AppData sharedInstance].localUser.theId],
                                     @"song_title": self.musicItem.title,
                                     @"song_artist": self.musicItem.artist,
                                     }];
    
    [_musicPlayerTimer invalidate];
    _musicPlayerTimer = nil;
    
    self.audioPlotWidthConstraint.constant = CGRectGetWidth(self.bottomAudioPlot.frame);
    
    CGRect frame = self.currentAudioPlotView.frame;
    frame.size.width = ceil(self.audioPlotWidthConstraint.constant - self.currentAudioViewOffset);
    frame.origin.x = self.currentAudioViewOffset;
    self.currentAudioPlotView.frame = frame;
    
    [self.musicPlayer pause];
    [_recorder pause];
    [_recorder stopRunning];
    
    [self saveVideoAndContinue];
}

- (void)checkPlayTime {
    // Update any UI controls including sliders and labels
    // display current time/duration
    dispatch_async(dispatch_get_main_queue(), ^{

        if(_isProcessing || !_recorder.isRecording) {
            return;
        }
                
        CGFloat totalSecond = [self.musicPlayer currentTime] - self.musicItem.startTime;
        self.audioPlotWidthConstraint.constant = (totalSecond / (self.musicItem.endTime - self.musicItem.startTime)) * CGRectGetWidth(self.bottomAudioPlot.frame);
        
        self.audioPlot.image = [self.audioPlot.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.audioPlot setTintColor:[UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1.0]];

        [self.view bringSubviewToFront:self.audioPlot];
        [self.view bringSubviewToFront:self.audioView];
        [self.view bringSubviewToFront:self.undoButton];
        
        CGRect frame = self.currentAudioPlotView.frame;
        frame.size.width = ceil(self.audioPlotWidthConstraint.constant - self.currentAudioViewOffset);
        frame.origin.x = self.currentAudioViewOffset;
        self.currentAudioPlotView.frame = frame;
        
        NSLog(@"recording: %f", totalSecond);
        
        if (totalSecond >= (self.musicItem.endTime - self.musicItem.startTime)) {
           
            [self finishRecording];
        }


    });
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
 
    [self finishRecording];
}

@end
