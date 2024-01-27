#import "MovieView.h"
#import "SystemInfo.h"

@interface MovieView ()

//L1

+ (MPMoviePlayerController *)reusableMovieController;
+ (void)receivedMemoryWarning;

@property (strong, nonatomic) MPMoviePlayerController *moviePlayerController;

- (void)commonInit;

- (void)pressed:(id)sender;

- (void)durationAvaible:(NSNotification *)notification;
- (void)updateProgress:(NSTimer *)timer;
- (void)playbackStateChanged:(NSNotification *)notification;

- (void)updateImage;

//L2

+ (void)initReusableMovieControllers;

@property (strong, nonatomic) UIActivityIndicatorView *loadingIndicator;
@property (assign, nonatomic) BOOL dontHidePlayerOnNextPause;

- (void)togglePlay;

- (void)installProgressBar;
- (void)removeProgressBar;

- (void)pauseProgressTimer;
- (void)resumeProgressTimer;

//L3

@property (strong, nonatomic) NSTimer *progressTimer;
@property (strong, nonatomic) UISlider *progressBar;

@end

@implementation MovieView

#pragma mark - L0

- (void)setShouldAutoplay:(BOOL)shouldAutoplay {
	if (shouldAutoplay != _shouldAutoplay) {
		_shouldAutoplay = shouldAutoplay;
    self.enabled = !_shouldAutoplay;
		[self updateImage];
		self.moviePlayerController.shouldAutoplay = _shouldAutoplay;

      self.moviePlayerController.repeatMode = MPMovieRepeatModeNone;
	}
}

- (void)setShowLoadingAnimation:(BOOL)showLoadingAnimation {
	if (showLoadingAnimation != _showLoadingAnimation) {
		_showLoadingAnimation = showLoadingAnimation;
		if (_showLoadingAnimation) {
			self.enabled = NO;
			[self.loadingIndicator startAnimating];
		}
		else {
			self.enabled = (self.contentURL != nil);
			[self.loadingIndicator stopAnimating];
		}
	}
}

- (void)setThumbCG:(CGImageRef)thumb animated:(BOOL)animated {
    self.contentMode = UIViewContentModeScaleAspectFit;
    
	if (thumb != _thumb) {
		if (_thumb != NULL) {
			CFRelease(_thumb);
		}
		_thumb = thumb;
		if (_thumb != NULL) {
			CFRetain(_thumb);
		}
		if (animated) {
			[UIView transitionWithView:self
							  duration:0.3
							   options:0
							animations:^{
								self.layer.contents = (__bridge id)thumb;
							}
							completion:NULL];
		}
		else {
			self.layer.contents = (__bridge id)(thumb);
		}
	}
}

- (void)setContentURL:(NSURL *)contentURL {
	if ((_contentURL != contentURL) && (![_contentURL isEqual:contentURL])) {
		_contentURL = contentURL;
		if (_contentURL == nil) {
			self.moviePlayerController = nil;
			self.enabled = NO;
		}
		else {
			if (self.moviePlayerController == nil) {
				//this will set contentURL to new moviePlayerController
				self.moviePlayerController = [[self class] reusableMovieController];
			}
			else {
				self.moviePlayerController.contentURL = _contentURL;
			}
			self.enabled = !self.showLoadingAnimation;
		}
	}
}

#pragma mark - L1

@synthesize moviePlayerController = _moviePlayerController;

- (void)setMoviePlayerController:(MPMoviePlayerController *)moviePlayerController {
	if (moviePlayerController != _moviePlayerController) {
		if (_moviePlayerController != nil) {
			[_moviePlayerController stop];
			[_moviePlayerController.view removeFromSuperview];
		}
		_moviePlayerController = moviePlayerController;
		if (_moviePlayerController != nil) {
			_moviePlayerController.shouldAutoplay = self.shouldAutoplay;
			[_moviePlayerController setAllowsAirPlay:NO];
			[_moviePlayerController setControlStyle:MPMovieControlStyleNone];
            
      [_moviePlayerController setScalingMode:MPMovieScalingModeAspectFit];
			_moviePlayerController.contentURL = self.contentURL;
			UIView *movieView = _moviePlayerController.view;
			movieView.hidden = YES;
			movieView.opaque = YES;
			movieView.userInteractionEnabled = NO;
			movieView.backgroundColor = [UIColor blackColor];
			movieView.frame = self.bounds;
			[self addSubview:movieView];
			[self prepareToPlay];
		}
	}
}

- (void)commonInit {
	self.opaque = YES;
	self.backgroundColor = [UIColor blackColor];
	self.layer.contentsScale = [UIScreen mainScreen].scale;
	self.layer.contentsGravity = kCAGravityResizeAspect;

	[self addTarget:self action:@selector(pressed:) forControlEvents:UIControlEventTouchUpInside];

	self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	self.loadingIndicator.hidesWhenStopped = YES;
	CGRect bounds = self.bounds;
	self.loadingIndicator.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
	self.loadingIndicator.autoresizingMask =
		UIViewAutoresizingFlexibleTopMargin |
		UIViewAutoresizingFlexibleBottomMargin |
		UIViewAutoresizingFlexibleLeftMargin |
		UIViewAutoresizingFlexibleRightMargin;
	[self addSubview:self.loadingIndicator];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStateChanged:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(durationAvaible:) name:MPMovieDurationAvailableNotification object:nil];
}

- (void)pressed:(id)sender {
	[self togglePlay];
}

//have to maintain two players because during animation two players may be shown at same time
static NSArray *ReusableMovieControllers = nil;
static NSUInteger LastPlayer = 0;

+ (MPMoviePlayerController *)reusableMovieController {
	if (ReusableMovieControllers == nil)
		[self initReusableMovieControllers];
    LastPlayer = (LastPlayer + 1) % 2;
    return [ReusableMovieControllers objectAtIndex:LastPlayer];
}

+ (void)receivedMemoryWarning {
	ReusableMovieControllers = nil;
}

- (void)durationAvaible:(NSNotification *)notificatio {
	self.progressBar.maximumValue = self.moviePlayerController.duration;
}

const NSTimeInterval ProgressTrackingInterval = 0.3;
const NSTimeInterval ProgressPresentationOffset = 0.1;

- (void)updateProgress:(NSTimer *)timer {
	NSTimeInterval nextPlaybackTime = (self.moviePlayerController.currentPlaybackTime + ProgressTrackingInterval + ProgressPresentationOffset);
	[UIView animateWithDuration:(ProgressTrackingInterval + ProgressPresentationOffset)
						  delay:0.0
						options:(UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction)
					 animations:^{
						 self.progressBar.value = nextPlaybackTime;
					 }
					 completion:NULL];
}

- (void)playbackStateChanged:(NSNotification *)notification {
  MPMoviePlaybackState state = [(MPMoviePlayerController *)notification.object playbackState];

  [self.delegate movieView:self changedPlaybackStateTo:state];
  //notify delegate

	switch (state) {
		case MPMoviePlaybackStatePaused:
			if (self.dontHidePlayerOnNextPause) {
				self.dontHidePlayerOnNextPause = NO;
				break;
			}
            
            self.moviePlayerController.view.hidden = YES;
            [self removeProgressBar];

            break;
		case MPMoviePlaybackStateStopped:
			self.dontHidePlayerOnNextPause = NO;
            self.moviePlayerController.view.hidden = YES;
            [self removeProgressBar];
			break;
		case MPMoviePlaybackStatePlaying:
            //for repeat mode to actually work, one have to 'spend enuogh time' somewhere around this callback
            //guess it's some iOS async issue due to player startup time
            usleep(50000);

            self.moviePlayerController.view.hidden = NO;
			break;
		case MPMoviePlaybackStateSeekingForward:
		case MPMoviePlaybackStateSeekingBackward:
		case MPMoviePlaybackStateInterrupted:
			break;
	}
}

- (void)updateImage {
	if (self.enabled && !self.shouldAutoplay) {
//		[self setImage:[VXResources imageNamed:@"icon_play.png"] forState:UIControlStateNormal];
	}
	else {
		[self setImage:nil forState:UIControlStateNormal];
	}
}

#pragma mark - L2

+ (void)initReusableMovieControllers {
	ReusableMovieControllers = [NSArray arrayWithObjects:[MPMoviePlayerController new], [MPMoviePlayerController new], nil];
}

- (void)togglePlay {
    if (_delegate && [_delegate respondsToSelector:@selector(movieViewWillTogglePlay:play:)]) {
        [_delegate movieViewWillTogglePlay:self play:self.moviePlayerController.playbackState != MPMoviePlaybackStatePlaying];
    }
	if (self.moviePlayerController.playbackState == MPMoviePlaybackStatePlaying) {
		[self pause];
	}
	else {
		[self setCurrentPlaybackTime:0.0];
		[self play];
	}
}

- (void)installProgressBar {
	if (self.progressTimer == nil) {
		self.progressTimer = [NSTimer timerWithTimeInterval:ProgressTrackingInterval target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES];
		[[NSRunLoop currentRunLoop] addTimer:self.progressTimer forMode:NSDefaultRunLoopMode];
	}
	if (self.progressBar == nil) {
		UISlider *progressBar = [UISlider new];
		self.progressBar = progressBar;
		self.progressBar.autoresizingMask = UIViewAutoresizingNone;
		
		[self.progressBar sizeToFit];

    self.progressBar.userInteractionEnabled = NO;

		self.progressBar.maximumValue = self.moviePlayerController.duration;
		[self insertSubview:self.progressBar aboveSubview:self.moviePlayerController.view];
	}

  [self.progressBar.layer removeAllAnimations];
  [self.progressBar setValue:0.0 animated:NO];
}

- (void)removeProgressBar {
	if (self.progressTimer != nil) {
		[self.progressTimer invalidate];
        [self.progressBar removeFromSuperview];
		self.progressBar = nil;
		self.progressTimer = nil;
	}
}

#pragma mark - L3

- (void)pauseProgressTimer {
	[self.progressTimer setFireDate:[NSDate distantFuture]];
}

- (void)resumeProgressTimer {
	[self.progressTimer setFireDate:[NSDate date]];
}

#pragma mark - Inherited

#pragma mark NSObject

+ (void)initialize {
	[self initReusableMovieControllers];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)dealloc {
  [self setThumbCG:nil animated:NO];

	[[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:MPMovieDurationAvailableNotification object:nil];
}

#pragma mark UIView

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super initWithCoder:aDecoder]) != nil) {
		[self commonInit];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame]) != nil) {
		[self commonInit];
	}
	return self;
}

- (void)layoutSubviews {
//#warning edit this when assets ready
	[super layoutSubviews];

	if (self.progressBar != nil) {
		CGRect frame = self.bounds;
		frame.origin.x += 7.0;
		frame.size.width -= 14.0;
		frame.origin.y = CGRectGetMaxY(frame) - 21.0 - self.progressBar.frame.size.height;
		frame.size.height = self.progressBar.frame.size.height;
		self.progressBar.frame = frame;
	}
}

#pragma mark UIControl

- (void)setEnabled:(BOOL)enabled {
	[super setEnabled:enabled];
	[self updateImage];
}

#pragma mark - Protocols

- (void)play {
	[self.moviePlayerController play];
}

- (void)pause {
	[self.moviePlayerController pause];
}

- (void)stop {
	[self.moviePlayerController stop];
}

- (void)prepareToPlay {
	[self.moviePlayerController prepareToPlay];
}

- (BOOL)isPreparedToPlay {
	return [self.moviePlayerController isPreparedToPlay];
}

- (void)beginSeekingBackward {
	[self.moviePlayerController beginSeekingBackward];
}

- (void)beginSeekingForward {
	[self.moviePlayerController beginSeekingForward];
}

- (void)endSeeking {
	[self.moviePlayerController endSeeking];
}

- (float)currentPlaybackRate {
	return [self.moviePlayerController currentPlaybackRate];
}

- (void)setCurrentPlaybackRate:(float)currentPlaybackRate {
	[self.moviePlayerController setCurrentPlaybackRate:currentPlaybackRate];
}

- (NSTimeInterval)currentPlaybackTime {
	return [self.moviePlayerController currentPlaybackTime];
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime {
	[self.moviePlayerController setCurrentPlaybackTime:currentPlaybackTime];
}

@end
