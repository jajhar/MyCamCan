#import "CaptureView.h"

@interface CaptureView ()

//L1

@property (strong, nonatomic) GPUImageVideoCamera *videoCamera;

//do not use 'commonInit', it is taken by
- (void)_commonInit;

- (void)tryPrepareToCapture;

- (void)applicationWillResignActive;
- (void)applicationDidBecomeActive;

//L2

@property (strong, nonatomic) GPUImageOutput *source;

@property (assign, nonatomic, readonly) int preferredCaptureDevicePosition;
@property (strong, nonatomic, readonly) NSString *capturePresset;
@property (assign, nonatomic, readonly) BOOL isPreparedToCapture;

//L3

@property (assign, atomic) BOOL captureInteruptedByMovingToBg;

- (void)startBeingTargetOfSource:(GPUImageOutput *)source;
- (void)stopBeingTargetOfSource:(GPUImageOutput *)source;

@end

@implementation CaptureView

#pragma mark L0
- (BOOL)isCapturing {
	return self.videoCamera.captureSession.running;
}

- (void)rotateCamera {
    [self.videoCamera rotateCamera];
//    self.devicePosition = self.videoCamera.cameraPosition;
}

- (void)prepareToCapture {
	[self tryPrepareToCapture];
}

- (void)startCapture {
	[self tryPrepareToCapture];
	[self.videoCamera startCameraCapture];
}

- (void)stopCapture {
	[self.videoCamera stopCameraCapture];
}

#pragma mark L1

- (void)_commonInit {
	self.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
	self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:self.capturePresset cameraPosition:self.preferredCaptureDevicePosition];
	self.videoCamera.outputImageOrientation = AVCaptureVideoOrientationPortrait;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)tryPrepareToCapture {
	self.source = self.videoCamera;
}

- (void)applicationWillResignActive {
	self.captureInteruptedByMovingToBg = self.isCapturing;
	[self stopCapture];
}

- (void)applicationDidBecomeActive {
	if (self.captureInteruptedByMovingToBg) {
		self.captureInteruptedByMovingToBg = NO;
		[self startCapture];
	}
}

#pragma mark L2

@synthesize source = _source;

- (void)setSource:(GPUImageOutput *)source {
	if (source != _source) {
		[self stopBeingTargetOfSource:_source];
		_source = source;
		[self startBeingTargetOfSource:_source];
	}
}

- (int)preferredCaptureDevicePosition {
	return AVCaptureDevicePositionBack;
}

- (NSString *)capturePresset {
	return AVCaptureSessionPresetHigh;
}

- (BOOL)isPreparedToCapture {
	return [self.videoCamera.targets containsObject:self];
}

#pragma mark L3

@synthesize captureInteruptedByMovingToBg = _captureInteruptedByMovingToBg;

- (void)startBeingTargetOfSource:(GPUImageOutput *)source {
	if (![[source targets] containsObject:self]) {
		[source addTarget:self];
	}
}

- (void)stopBeingTargetOfSource:(GPUImageOutput *)source {
	[source removeTarget:self];
}

#pragma mark - Inherited

#pragma mark NSObject

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];

	self.source = nil;
}

#pragma mark UIView

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame]) != nil) {
		[self _commonInit];
	}
	return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	[self _commonInit];
}

//- (id)initWithCoder:(NSCoder *)aDecoder {
//	if ((self = [super initWithCoder:aDecoder]) != nil) {
//		[self _commonInit];
//	}
//	return self;
//}

@end
