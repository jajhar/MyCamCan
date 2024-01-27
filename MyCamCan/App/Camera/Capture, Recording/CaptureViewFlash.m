#import "CaptureViewFlash.h"
#import "CaptureView_Private.h"

@interface CaptureViewFlash ()

//L0

- (BOOL)hasFlash;
- (BOOL)toggleFlash;

//L1

@property (weak, nonatomic) UIButton *flashButton;

- (void)updateFlashButton;

@end

@implementation CaptureViewFlash

#pragma mark L0

- (BOOL)hasFlash {
    //	if (self.videoCamera.inputCamera.hasFlash && self.videoCamera.inputCamera.hasTorch) {
    return (self.videoCamera.inputCamera.torchAvailable && self.videoCamera.inputCamera.hasTorch);
}

- (BOOL)toggleFlash {
    BOOL result = NO;
    if([self.videoCamera cameraPosition] == AVCaptureDevicePositionBack) {
        NSError *error = nil;
        if ([self.videoCamera.inputCamera lockForConfiguration:&error]) {
            if(self.videoCamera.inputCamera.torchMode == AVCaptureTorchModeOff) {
                [self.videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOn];
                result = YES;
            }else{
                [self.videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOff];
                result = NO;
            }
            [self updateFlashButton];
        } else {
            NSLog(@"Error locking camera for configuration: %@", error);
        }

        [self.videoCamera.inputCamera unlockForConfiguration];
    }
    return result;
}

#pragma mark L1

@synthesize flashButton = _flashButton;

- (void)updateFlashButton {
	if (self.videoCamera.inputCamera.torchMode == AVCaptureTorchModeOff) {
//		[self.flashButton setImage:[VXResources imageNamed:@"camera_flash"] forState:UIControlStateNormal];
	} else {
//		[self.flashButton setImage:[VXResources imageNamed:@"camera_flash"] forState:UIControlStateNormal];
	}
}

#pragma mark - Inherited

- (void)stopCapture {
    [super stopCapture];
}


- (void)rotateCamera {
    [super rotateCamera];
    
    self.flashButton.hidden = ![self hasFlash];
}

#pragma mark UIView

- (void)layoutSubviews {
	[super layoutSubviews];
	CGSize size = self.bounds.size;
	self.flashButton.frame = CGRectMake(size.width - 54.0, 55.0, 34.0, 37.0);
}

#pragma mark CaptureView

- (void)_commonInit {
	[super _commonInit];
	UIButton *flashButton = nil;
    if ([self hasFlash]) {
		flashButton = [UIButton new];
	}
	flashButton.opaque = NO;
	flashButton.backgroundColor = [UIColor clearColor];
	self.flashButton = flashButton;
	[self.flashButton addTarget:self action:@selector(toggleFlash) forControlEvents:UIControlEventTouchUpInside];
	[self updateFlashButton];
	[self addSubview:self.flashButton];
}

@end
