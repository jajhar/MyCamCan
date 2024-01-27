#import "CaptureView.h"

@interface CaptureView (Private)

@property (strong, nonatomic) GPUImageOutput *source;

@property (strong, nonatomic) GPUImageVideoCamera *videoCamera;

//do not use 'commonInit', it is taken
- (void)_commonInit;

//callbacks on source change
- (void)startBeingTargetOfSource:(GPUImageOutput *)source;
- (void)stopBeingTargetOfSource:(GPUImageOutput *)source;

@end
