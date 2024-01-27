#import <GPUImage/GPUImage.h>

@interface CaptureView : GPUImageView

@property (assign, nonatomic, readonly) BOOL isCapturing;

- (void)rotateCamera;

- (void)prepareToCapture;
- (void)startCapture;
- (void)stopCapture;

@end
