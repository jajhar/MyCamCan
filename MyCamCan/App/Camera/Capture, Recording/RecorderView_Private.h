#import "RecorderView.h"
#import "CaptureView_Private.h"

@interface RecorderView (Private)

- (void)recordingWasLaunched;
- (void)recordingWillBeStopped;

@property (strong, nonatomic, readonly) GPUImageMovieWriter *movieWriter;

- (void)targetMovieWriter;
- (void)untargetMovieWriter;

//@property (assign, nonatomic, readonly) pthread_mutex_t stateChangeMutex; //should protect from async calls to start/stop recording
//@property (assign, nonatomic, readonly) pthread_mutex_t recordingMutex; //should protect recording operation

@end
