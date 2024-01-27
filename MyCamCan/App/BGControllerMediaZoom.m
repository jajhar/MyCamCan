/**
 * ZoomingViewController.m
 * TapZoomRotate
 *@author Matt Gallagher
 *@since  2010/09/27.
 *Copyright 2010 Matt Gallagher. All rights reserved.
 *  Permission is given to use this source code file, free of charge, in any
 *  project, commercial or otherwise, entirely at your risk, with the condition
 * that any redistribution (in part or whole) of source code must retain
 *  this copyright and permission notice. Attribution in compiled projects is
 *  appreciated but not required.
 */

#import "BGControllerMediaZoom.h"
#import "BGViewMediaOverlay.h"

#import "BGViewMovieSlider.h"

@interface BGControllerMediaZoom () <BGViewMediaOverlayDelegate>
{
    CGFloat _lastScale;
    UITapGestureRecognizer *singleTapGestureRecognizer;
    UIPanGestureRecognizer *_panGestureRecognizer;
    CGFloat firstX;
    CGFloat firstY;
    CGAffineTransform _originalTransform;
    UIColor *_originalBackgroundColor;
}

// interface
@property (strong, nonatomic) BGViewMediaOverlay *overlayView;

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *proxyView;

// data
@property (strong, nonatomic) Media *media;

@end

@implementation BGControllerMediaZoom

/**
* Proper initalization for media overlay.
*/
- (void)commonInit {
    [super commonInit];
    
    _backgroundView = [[UIView alloc] initWithFrame:self.view.window.frame];
    _overlayView = [[BGViewMediaOverlay alloc] initWithFrame:self.view.window.frame];
    
    _overlayView = [[[NSBundle mainBundle] loadNibNamed:@"BGViewMediaOverlay"
                                   owner:nil
                                 options:nil] objectAtIndex:0];
    
    _overlayView.delegate = self;
}

- (void)updateWithMedia:(Media *)media {
    _media = media;
    
    [self.overlayView updateWithMedia:_media];
    
    [self setupView];
}

- (void)setupView {
    
}
/**
*<p>
* This method checks the orientation of the device and if the orientation is landscape it returns a new affine
* transformation matrix.
 */
- (CGAffineTransform)orientationTransformFromSourceBounds:(CGRect)sourceBounds
{
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	if (orientation == UIDeviceOrientationFaceUp ||
		orientation == UIDeviceOrientationFaceDown)
	{
		orientation = (UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation;
	}
	
	if (orientation == UIDeviceOrientationPortraitUpsideDown)
	{
		return CGAffineTransformMakeRotation(M_PI);
	}
	else if (orientation == UIDeviceOrientationLandscapeLeft)
	{
		CGRect windowBounds = self.view.window.bounds;
		CGAffineTransform result = CGAffineTransformMakeRotation(0.5 * M_PI);
		result = CGAffineTransformTranslate(result,
			0.5 * (windowBounds.size.height - sourceBounds.size.width),
			0.5 * (windowBounds.size.height - sourceBounds.size.width));
		return result;
	}
	else if (orientation == UIDeviceOrientationLandscapeRight)
	{
		CGRect windowBounds = self.view.window.bounds;
		CGAffineTransform result = CGAffineTransformMakeRotation(-0.5 * M_PI);
		result = CGAffineTransformTranslate(result,
			0.5 * (windowBounds.size.width - sourceBounds.size.height),
			0.5 * (windowBounds.size.width - sourceBounds.size.height));
		return result;
	}

	return CGAffineTransformIdentity;
}
/**
* for landscape mode it resize the screen size. */
- (CGRect)rotatedWindowBounds
{
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	if (orientation == UIDeviceOrientationFaceUp ||
		orientation == UIDeviceOrientationFaceDown)
	{
		orientation = (UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation;
	}
	
	if (orientation == UIDeviceOrientationLandscapeLeft ||
		orientation == UIDeviceOrientationLandscapeRight)
	{
		CGRect windowBounds = self.view.window.bounds;
		return CGRectMake(0, 0, windowBounds.size.height, windowBounds.size.width);
	}

	return self.view.window.bounds;
}
/**
 * This method is called action to device rotate
 */
//- (void)deviceRotated:(NSNotification *)aNotification
//{
//    
//    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
//    
//    if (orientation == UIDeviceOrientationFaceUp ||
//        orientation == UIDeviceOrientationFaceDown ||
//        orientation == UIDeviceOrientationPortraitUpsideDown)
//    {
//        return;
//    }
//    
//	if (_proxyView)
//	{
//		if (aNotification)
//		{
//			CGRect windowBounds = self.view.window.bounds;
//			UIView *blankingView =
//				[[UIView alloc] initWithFrame:
//					CGRectMake(-0.5 * (windowBounds.size.height - windowBounds.size.width),
//						0, windowBounds.size.height, windowBounds.size.height)];
//			blankingView.backgroundColor = [UIColor blackColor];
//			[self.view.superview insertSubview:blankingView belowSubview:self.view];
//			
//            
//            
//			[UIView animateWithDuration:0.25 animations:^{
//				self.view.bounds = [self rotatedWindowBounds];
//				self.view.transform = [self orientationTransformFromSourceBounds:self.view.bounds];
//                
//                self.overlayView.bounds = [self rotatedWindowBounds];
//                self.overlayView.transform = [self orientationTransformFromSourceBounds:self.overlayView.bounds];
//                
//			} completion:^(BOOL complete){
//                [blankingView removeFromSuperview];
//			}];
//		}
//		else
//		{
//			self.view.bounds = [self rotatedWindowBounds];
//			self.view.transform = [self orientationTransformFromSourceBounds:self.view.bounds];
//            
//            self.overlayView.bounds = [self rotatedWindowBounds];
//            self.overlayView.transform = [self orientationTransformFromSourceBounds:self.overlayView.bounds];
//		}
//	}
//	else
//	{
//		self.view.transform = CGAffineTransformIdentity;
//        self.overlayView.transform = CGAffineTransformIdentity;
//	}
//    
//    // set original transform to new orientation
//    _originalTransform = self.view.transform;
//    
//    [self.delegate orientationDidChange:orientation];
//}

/**
* This method is called to show/hide media overlay.
 */
- (void)toggleOverlay {
    [self.overlayView toggleInterfaceControls];
}

- (void)toggleZoom {
    [self toggleZoom:nil];
}
/**
* This method is called to toggle zoom/overlay.
 */
- (void)toggleZoomOrOverlay {
    if(_proxyView) {
        // full screen
        [self.overlayView toggleInterfaceControls];
    } else {
        // not full screen
        [self toggleZoom];
    }
}
/**
* This method toggle full screen of the view.
*/
- (void)toggleZoom:(UITapGestureRecognizer *)gestureRecognizer
{
	if (_proxyView)  // hide view (initial size)
	{
        [self dismissFullscreenView];
	}
	else    // show view (full-screen)
	{
        [self showFullscreenView];
	}
	
//	[self deviceRotated:nil];
}

- (void)showFullscreenView {
    
    if (_proxyView || ![self.delegate shouldEnterFullScreen]) {
        return;
    }
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         
                         self.view.alpha = 0.0;
                         
                     } completion:^(BOOL finished) {
                         
                         _proxyView = [[UIView alloc] initWithFrame:self.view.frame];
                         _backgroundView = [[UIView alloc] initWithFrame:self.view.window.frame];
                         
                         _proxyView.hidden = YES;
                         _proxyView.autoresizingMask = self.view.autoresizingMask;
                         [self.view.superview addSubview:_proxyView];
                         
                         [self.view.window addSubview:self.backgroundView];
                         [self.view.window addSubview:self.view];
                         [self.view.window addSubview:self.overlayView];
                         
                         self.backgroundView.backgroundColor = [UIColor blackColor];
                         self.backgroundView.alpha = 0.0;
                         
                         self.view.frame = self.view.window.bounds;
                         _overlayView.frame = self.view.window.bounds;
                         
                         self.view.backgroundColor = [UIColor clearColor];
                         
                         [self.delegate didEnterFullScreen];
                         
                         [self showInterfaceControlsAnimated:YES];

                         [UIView animateWithDuration:0.3
                                          animations:^{
                                              self.view.alpha = 1.0;
                                              self.backgroundView.alpha = 1.0;
                                              self.overlayView.alpha = 1.0;
                                          }];
                     }];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(deviceRotated:)
//                                                     name:UIDeviceOrientationDidChangeNotification
//                                                   object:[UIDevice currentDevice]];
    
//        [self.view addGestureRecognizer:_panGestureRecognizer];
        
}

//- (void)setOwner:(id<BG_Requests>)owner {
//    _owner = owner;
//    [_overlayView setOwner:owner];
//}

- (void)dismissFullscreenView
{
	if (!_proxyView) {
        return;
    }

//        CGRect frame = [_proxyView.superview convertRect:self.view.frame fromView:self.view.window];
//        self.view.frame = frame;
    
    CGRect proxyViewFrame = _proxyView.frame;
    
    [UIView animateWithDuration:0.3
     animations:^{
         self.view.alpha = 0.0;
         self.proxyView.alpha = 0.0;
         self.backgroundView.alpha = 0.0;
         self.overlayView.alpha = 0.0;
         self.view.transform = CGAffineTransformIdentity;
         self.transform = CGAffineTransformIdentity;
         
     } completion:^(BOOL finished) {
         
         [_proxyView.superview addSubview:self.view];
         [_proxyView removeFromSuperview];
         _proxyView = nil;
         
         self.view.frame = proxyViewFrame;

         [self.backgroundView removeFromSuperview];
         [self.overlayView removeFromSuperview];

         [self.delegate didExitFullScreen];
         self.view.backgroundColor = _originalBackgroundColor;

         // Make it appear in its original location
         [UIView animateWithDuration:0.3
                          animations:^{
                              self.view.alpha = 1.0;
                              
                          } completion:^(BOOL finished) {
                              
                          }];
     }];        
    
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:[UIDevice currentDevice]];
    
//        [self.view removeGestureRecognizer:_panGestureRecognizer];

}

/**
 *  This method will hide the interface on the overlay view
 */
- (void)hideInterfaceControlsAnimated:(BOOL)animated {
    [self.overlayView hideInterfaceControlsAnimated:animated];
}

/**
 *  This method will show the interface on the overlay view
 */
- (void)showInterfaceControlsAnimated:(BOOL)animated {
    [self.overlayView showInterfaceControlsAnimated:animated];
}

/**
 *  This method will be called via delegate once the overlay has fully shown its interface controls
 */
- (void)interfaceShown {
    [self.delegate interfaceShown];
}

/**
 *  This method will be called via delegate once the overlay has fully hidden its interface controls
 */
- (void)interfaceHidden {
    [self.delegate interfaceHidden];
}
/**
* This method is called to add pinch & tab gesture to view.
*/
- (void)setView:(UIView *)newView
{
	if (_view)
	{
		[self toggleZoom:nil];
		[_view removeGestureRecognizer:singleTapGestureRecognizer];
//        [_view removeGestureRecognizer:_panGestureRecognizer];
//        _panGestureRecognizer = nil;
		singleTapGestureRecognizer = nil;
    }
	
	_view = newView;
	
	singleTapGestureRecognizer =
		[[UITapGestureRecognizer alloc]
			initWithTarget:self action:@selector(toggleZoomOrOverlay)];
	singleTapGestureRecognizer.numberOfTapsRequired = 1;
	
	[self.view addGestureRecognizer:singleTapGestureRecognizer];
    
//    _panGestureRecognizer = [[UIPanGestureRecognizer alloc]
//                               initWithTarget:self
//                               action:@selector(handlePanGesture:)];
    
//    [_panGestureRecognizer setMinimumNumberOfTouches:1];
//    [_panGestureRecognizer setMaximumNumberOfTouches:1];
//    _panGestureRecognizer.delegate = self;

    _originalTransform = self.view.transform;
    _originalBackgroundColor = self.view.backgroundColor;
}
/**
* deallocates the memory occupaid by the proxyView.
*/
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[_proxyView removeFromSuperview];
}

/**
 * This method will handle any panning gestures done to the view. If the user pans the view far enough, it will dismiss the fullscreen view.
 */
-(void)handlePanGesture:(UIPanGestureRecognizer *)sender {
    CGPoint translatedPoint = [sender translationInView:[sender view]];
    
    if ([sender state] == UIGestureRecognizerStateBegan) {
        firstX = [[sender view] center].x;
        firstY = [[sender view] center].y;
        
        [self.overlayView hideInterfaceControlsAnimated:YES];
    }
    
    if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation])) {
        translatedPoint = CGPointMake(firstX+translatedPoint.x, firstY+translatedPoint.y);
    } else if([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft){
        translatedPoint = CGPointMake(firstX-translatedPoint.y, firstY+translatedPoint.x);
    } else if([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight) {
        translatedPoint = CGPointMake(firstX+translatedPoint.y, firstY-translatedPoint.x);
    } else {
        translatedPoint = CGPointMake(firstX+translatedPoint.x, firstY+translatedPoint.y);
    }
    
    [[sender view] setCenter:translatedPoint];
    
    // Get the pan touch's distance from the origin.
    CGFloat a, b, distanceFromOrigin;
    a = firstX - translatedPoint.x;
    b = translatedPoint.y - firstY;
    distanceFromOrigin = sqrt((a*a) + (b*b));
    
    // fade out the background as we drag further from point of origin
    self.backgroundView.alpha = 1 - (distanceFromOrigin / 350.0);
    
    if ([sender state] == UIGestureRecognizerStateEnded) {
        
        CGFloat velocityX = (0.2*[sender velocityInView:self.view].x);
        
        self.backgroundView.alpha = 1.0;

//        CGFloat finalX = translatedPoint.x + velocityX;
//        CGFloat finalY = translatedPoint.y + (.35*[(UIPanGestureRecognizer*)sender velocityInView:self.view].y);
        CGFloat animationDuration = (ABS(velocityX)*.0002)+.2;

        if (distanceFromOrigin > 150.0) {
            [self dismissFullscreenView];
        } else {
            [self.overlayView showInterfaceControlsAnimated:YES];
        }
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:animationDuration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDelegate:self];
        [[sender view] setCenter:CGPointMake(firstX, firstY)];
        [UIView commitAnimations];
    }
}

/**
 * This method defines what touches the pan gesture recognizer will listen to.
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // Ignore touches from the video slider view and UISlider or the user has zoomed in on the media    
    if([[touch view] isKindOfClass:[BGViewMovieSlider class]] ||
       [[touch view] isKindOfClass:[UISlider class]] ||
       [(UIScrollView *)_view zoomScale] != 1.0) {
        return NO;
    }
    
    if([[touch view] isKindOfClass:[UIScrollView class]] && [(UIScrollView *)touch.view zoomScale] != 1.0) {
        return NO;
    }
    
    return YES;
}

#pragma mark - BGViewMediaOverlayDelegate
/**
* This method is called to dismiss the fullscreen view.
*/
- (void)donePressed:(UIButton *)button {
    [self dismissFullscreenView];
}



@end

