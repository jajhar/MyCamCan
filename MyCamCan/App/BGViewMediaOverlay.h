/**
*  BGViewMediaOverlay.h
*  MCC
*@author James Ajhar 
*@since  10/15/14.
*  Copyright (c) 2014 D9. All rights reserved.
*/

#import "BGView.h"

@protocol BGViewMediaOverlayDelegate <UIActionSheetDelegate>

@optional
- (void)donePressed:(UIButton *)button;
- (void)interfaceHidden;
- (void)interfaceShown;

@end

@interface BGViewMediaOverlay : BGView
/**
 * This method is called to update the media infos.
 */
- (void)updateWithMedia:(Media *)media;
/**
 * This method is called to show/hide media overlay.
 */
- (void)toggleInterfaceControls;

/**
 * This method is called to hide the interface control.
 */
- (void)hideInterfaceControlsAnimated:(BOOL)animated;
/**
 * This method is called to show the interface control.
 */
- (void)showInterfaceControlsAnimated:(BOOL)animated;

@property (assign, nonatomic) id delegate;

@end
