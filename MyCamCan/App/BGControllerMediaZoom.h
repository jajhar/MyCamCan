/**
* ZoomingViewController.h
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

#import <UIKit/UIKit.h>
#import "Media.h"
#import "BGView.h"

@protocol BGZoomingViewControllerDelegate

@required

- (BOOL)shouldEnterFullScreen;

@optional

- (void)didEnterFullScreen;
- (void)didExitFullScreen;
- (void)interfaceShown;
- (void)interfaceHidden;
- (void)orientationDidChange:(UIDeviceOrientation)orientation;

@end

@interface BGControllerMediaZoom : BGView <UIGestureRecognizerDelegate>

@property (nonatomic, strong, readonly) UIView *proxyView;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, assign) id delegate;

/**
 *This method is called to update media information
 */
- (void)updateWithMedia:(Media *)media;
/**
 *This method is called to animate zoom in and zoom out
 */
- (void)toggleZoom;
/**
 *This method is called to show full screen
 */
- (void)showFullscreenView;
/**
 *This method is called to dismiss the full screen
 */
- (void)dismissFullscreenView;
- (void)hideInterfaceControlsAnimated:(BOOL)animated;
- (void)showInterfaceControlsAnimated:(BOOL)animated;

@end
