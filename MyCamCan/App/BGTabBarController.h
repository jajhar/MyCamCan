//
//  BGTabBarController.h
//  Blog
//
//  Created by James Ajhar on 1/20/16.
//  Copyright © 2016 James Ajhar. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BGImagePickerDelegate <NSObject>

@required

- (void)imagePickerDidFinishPickingMedia:(NSArray *)media;

@end

typedef NS_OPTIONS(NSUInteger, BGAllowedPickerMediaTypes) {
    kBGAllowedTypesAll,
    kBGAllowedTypesPhoto,
    kBGAllowedTypesVideo
};

@class BGController;

//Requests' purpose constants
typedef NS_ENUM(NSUInteger, BGPurpose) {
    kBGPurposeLogin,
    kBGPurposeFeed,
    kBGPurposeMediaCreate,
    kBGPurposeCamera,
    kBGPurposePostDetails,
    kBGPurposeProfile,
    kBGPurposeRegister,
    kBGPurposeMusicPicker,
    kBGPurposeSplash,
    kBGPurposeNotifications,
    kBGPurposeSearch,
    kBGPurposeImageCropper,
    kBGPurposeContacts,
    kBGPurposeOnboarding,
    kBGPurposeLikes,
    kBGPurposeUsers,
    kBGPurposePostEdit,
    kBGPurposeWebBrowser,
    kBGPurposeMusicTrim
};

@interface BGTabBarController : UITabBarController

- (UIViewController *)presentControllerForPurpose:(BGPurpose)purpose
                                             info:(id)info
                                       showTabBar:(BOOL)show;

- (UIViewController *)presentControllerForPurpose:(BGPurpose)purpose
                                             info:(id)info
                                       showTabBar:(BOOL)show
                                  pushImmediately:(BOOL)pushImmediately;

- (BOOL)presentMediaPickerWithAllowedMediaTypes:(BGAllowedPickerMediaTypes)allowedMediaTypes
                                  usingDelegate: (id <UIImagePickerControllerDelegate, UINavigationControllerDelegate>) delegate;

- (void)presentCameraWithCaptureMode:(UIImagePickerControllerCameraCaptureMode)captureMode
                   allowedMediaTypes:(BGAllowedPickerMediaTypes)allowedMediaTypes
                            delegate:(id <UIImagePickerControllerDelegate, UINavigationControllerDelegate>)delegate;

- (BGController *)controllerForPurpose:(BGPurpose)purpose;

- (void)resetNotificationBadge;

@end
