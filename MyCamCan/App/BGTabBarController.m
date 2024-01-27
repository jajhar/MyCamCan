//
//  BGTabBarController.m
//  Blog
//
//  Created by James Ajhar on 1/20/16.
//  Copyright © 2016 James Ajhar. All rights reserved.
//

#import "BGTabBarController.h"

// Controllers
#import "BGControllerLogin.h"
#import "BGControllerFeed.h"
#import "BGControllerProfile.h"
#import "BGControllerRegister.h"
#import "BGControllerMediaPicker.h"
#import "BGControllerCamera.h"
#import "BGControllerMusicPicker.h"
#import "BGControllerSplash.h"
#import "BGControllerNotifications.h"
#import "BGControllerSearch.h"
#import "BGControllerImageCropper.h"
#import "BGControllerContacts.h"
#import "BGControllerOnboarding.h"
#import "BGControllerLikes.h"
#import "BGControllerPostDetails.h"

@implementation BGTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    NSNotificationCenter *sharedNC = [NSNotificationCenter defaultCenter];
    [sharedNC addObserver:self
                 selector:@selector(notificationNotificationsReceived:)
                     name:kAppData_Notification_NotificationsReceived
                   object:nil];
    
    CGRect frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, 50);
    UIView *v = [[UIView alloc] initWithFrame:frame];
    [v setBackgroundColor:[UIColor colorWithRed:216.0/255.0 green:216.0/255.0 blue:216.0/255.0 alpha:1.0]];
    [[self tabBar] addSubview:v];
    [self.tabBar sendSubviewToBack:v];
    
    [self.tabBar setTintColor:[UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1.0]];
    
    UIImage *image = [[UIImage imageNamed:@"tab-capture"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UITabBarItem *item2 = [[UITabBarItem alloc] initWithTitle:nil image:image selectedImage:image];
    item2.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    UIViewController *controller = [self.viewControllers objectAtIndex:2];
    controller.tabBarItem = item2;
}

- (void)notificationNotificationsReceived:(NSNotification *)notification {
    User *user = [[notification userInfo] objectForKey:kAppData_NotificationKey_User];
    
    if ([DataModelObject modelObject:user isEqualTo:[AppData sharedInstance].localUser]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
        
            UITabBarItem *notificationTab = [[self.tabBar items] objectAtIndex:3];
            
            if(user.totalUnreadNotifications > 0) {
                notificationTab.badgeValue = [NSString stringWithFormat:@"%lu", user.totalUnreadNotifications];
            } else {
                notificationTab.badgeValue = nil;
            }
        });
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)resetNotificationBadge {
    UITabBarItem *notificationTab = [[self.tabBar items] objectAtIndex:3];
    notificationTab.badgeValue = nil;
}


- (UIViewController *)presentControllerForPurpose:(BGPurpose)purpose info:(id)info showTabBar:(BOOL)show {
    return [self presentControllerForPurpose:purpose info:info showTabBar:show pushImmediately:YES];
}

- (UIViewController *)presentControllerForPurpose:(BGPurpose)purpose
                                             info:(id)info
                                       showTabBar:(BOOL)show
                                  pushImmediately:(BOOL)pushImmediately {
    
    if (purpose == kBGPurposeLogin) {
        [self dismissSelf];
        return nil;
    }
    
    BGController *controller = (BGController *)[self controllerForPurpose:purpose];
    [controller setInfo:info animated:YES];
    
    BGController *topController = (BGController *)[(UINavigationController *)self.selectedViewController topViewController];
    
    if ([controller class] == [topController class] &&
        [controller.info isEqualToDictionary:topController.info])
    {
        // Attempting to navigate to the same controller, STOP
        return nil;
    }
    
    BOOL animated = YES;
    
    //    UIViewController *currentController = [(UINavigationController *)self.selectedViewController topViewController];
    
    //    BOOL currentPushValue = currentController.hidesBottomBarWhenPushed;
    //    currentController.hidesBottomBarWhenPushed = NO;
    
    controller.hidesBottomBarWhenPushed = !show;
    
    if(purpose == kBGPurposeCamera ||
       purpose == kBGPurposeImageCropper) {
        // full screen view controllers
        [self.selectedViewController setNavigationBarHidden:YES animated:YES];
        
        CATransition *transition = [CATransition animation];
        transition.duration = 0.3;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        [self.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];
        animated = NO;
        
    } else {
        [self.selectedViewController setNavigationBarHidden:NO animated:YES];
    }
    
    if (pushImmediately) {
        [(UINavigationController *)self.selectedViewController pushViewController:controller animated:animated];
    }
    
    return controller;
    
    //    currentController.hidesBottomBarWhenPushed = currentPushValue;
}

- (BGController *)controllerForPurpose:(BGPurpose)purpose {
    
    NSString *controllerId = [self controllerIdForPurpose:purpose];
    
    UIStoryboard *storyboard;

    if (purpose == kBGPurposePostEdit ||
        purpose == kBGPurposePostDetails) {
        // autolayout type controllers
        storyboard = [UIStoryboard storyboardWithName:@"BlogAutolayoutStoryboard" bundle:nil];
    } else if (purpose == kBGPurposeMusicPicker) {
        storyboard = [UIStoryboard storyboardWithName:@"MusicPickerStoryboard" bundle:nil];
    } else if (purpose == kBGPurposeCamera) {
        storyboard = [UIStoryboard storyboardWithName:@"CameraStoryboard" bundle:nil];
    
    } else if (purpose == kBGPurposeMusicTrim) {
        storyboard = [UIStoryboard storyboardWithName:@"MusicTrimStoryboard" bundle:nil];
        
    } else if (purpose == kBGPurposeLogin ||
               purpose == kBGPurposeRegister) {
        storyboard = [UIStoryboard storyboardWithName:@"LoginStoryboard" bundle:nil];
    } else {
        storyboard = [UIStoryboard storyboardWithName:@"BlogStoryboard" bundle:nil];
    }
    
    if (storyboard == nil) {
        NSLog(@"Could not find storyboard");
    }
    
    BGController *result = (BGController *)[storyboard instantiateViewControllerWithIdentifier:controllerId];
    return result;
}



- (NSString *)controllerIdForPurpose:(BGPurpose)purpose {
    switch (purpose) {
            
        case kBGPurposeLogin:
            return kBGControllerLogin;
        case kBGPurposeFeed:
            return kBGControllerFeed;
        case kBGPurposeProfile:
            return kBGControllerProfile;
        case kBGPurposeRegister:
            return kBGControllerRegister;
        case kBGPurposeImageCropper:
            return kBGControllerImageCropper;
        case kBGPurposeLikes:
            return kBGControllerLikes;
        case kBGPurposeCamera:
            return kBGControllerCamera;
        case kBGPurposeMusicPicker:
            return kBGControllerMusicPicker;
        case kBGPurposeSplash:
            return kBGControllerSplash;
        case kBGPurposeNotifications:
            return kBGControllerNotifications;
        case kBGPurposeContacts:
            return kBGControllerContacts;
        case kBGPurposeOnboarding:
            return kBGControllerOnboarding;
        case kBGPurposePostDetails:
            return @"BGControllerPostDetails";
        case kBGPurposeUsers:
            return @"BGControllerUsers";
        case kBGPurposePostEdit:
            return @"BGControllerPostEdit";
        case kBGPurposeWebBrowser:
            return @"BGControllerWebBrowser";
        case kBGPurposeMusicTrim:
            return @"BGControllerMusicTrim";
        default:
#if defined(DEBUG)
            NSAssert(NO, @"Snape kills dumbledore...");
#endif
            return nil;
            break;
    }
}

- (void)dismissSelf {
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [self.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - UIImagePickerController Presentation


- (BOOL)presentMediaPickerWithAllowedMediaTypes:(BGAllowedPickerMediaTypes)allowedMediaTypes
                                  usingDelegate: (id <UIImagePickerControllerDelegate, UINavigationControllerDelegate>) delegate {
    
    if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == NO) ||
        (delegate == nil))
    {
        return NO;
    }
    
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    
    //    [mediaUI.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    //    [mediaUI.navigationBar setTitleTextAttributes:nil];
    //    [mediaUI.navigationBar setBarTintColor:nil];
    
    mediaUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    // Displays saved pictures and movies, if both are available, from the Camera Roll album.
    
    // media types are video and image
    NSMutableArray *allowedTypes = [NSMutableArray new];
    
    switch(allowedMediaTypes)
    {
        case kBGAllowedTypesAll:
            [allowedTypes addObject:(NSString *)kUTTypeImage];
            [allowedTypes addObject:(NSString *)kUTTypeMovie];
            break;
        case kBGAllowedTypesPhoto:
            [allowedTypes addObject:(NSString *)kUTTypeImage];
            break;
        case kBGAllowedTypesVideo:
            [allowedTypes addObject:(NSString *)kUTTypeMovie];
            break;
            
        default:
            [allowedTypes addObject:(NSString *)kUTTypeImage];
            [allowedTypes addObject:(NSString *)kUTTypeMovie];
            break;
    }
    
    mediaUI.mediaTypes = allowedTypes;
    
    // Hides the controls for moving & scaling pictures, or for
    
    // trimming movies. To instead show the controls, use YES.
    
    mediaUI.allowsEditing = NO;
    
    mediaUI.delegate = delegate;
    
    [[(UINavigationController *)self.selectedViewController topViewController] presentViewController:mediaUI animated:YES completion:nil];
    
    return YES;
    
}

- (void)presentCameraWithCaptureMode:(UIImagePickerControllerCameraCaptureMode)captureMode
                   allowedMediaTypes:(BGAllowedPickerMediaTypes)allowedMediaTypes
                            delegate:(id <UIImagePickerControllerDelegate, UINavigationControllerDelegate>)delegate
{
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if (authStatus == AVAuthorizationStatusAuthorized) {
        // successful
        NSString *mediaAudio = AVMediaTypeAudio;
        [AVCaptureDevice requestAccessForMediaType:mediaAudio completionHandler:^(BOOL grantedAudio) {
            if (!grantedAudio) {
                // Not granted access to mediaType
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Microphone access denied!",@"Microphone access disabled alert message")
                                                message:NSLocalizedString(@"Please enable microphone access! Go to Setting -> Privacy -> Microphone to allow access.",@"Message displays steps to enable Microphone access")
                                               delegate:self
                                      cancelButtonTitle:NSLocalizedString(@"Ok",@"Option for cancel the alert message")
                                      otherButtonTitles:nil] show];
                    return;
                });
            }
        }];
        
    } else if(authStatus == AVAuthorizationStatusDenied) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Camera access denied!",@"Camera access disabled")
                                    message:NSLocalizedString(@"Please enable camera access! Go to Setting -> Privacy -> Camera to allow access.",@"Message displays steps to enable camera access ")
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"Ok",@"Option for cancel the alert message")
                          otherButtonTitles:nil] show];
        return;
    }
    
    UIImagePickerController * imagePickerController = [[UIImagePickerController alloc] init];
    
    // media types are video and image
    NSMutableArray *allowedTypes = [NSMutableArray new];
    
    switch(allowedMediaTypes)
    {
        case kBGAllowedTypesAll:
            [allowedTypes addObject:(NSString *)kUTTypeImage];
            [allowedTypes addObject:(NSString *)kUTTypeMovie];
            break;
        case kBGAllowedTypesPhoto:
            [allowedTypes addObject:(NSString *)kUTTypeImage];
            break;
        case kBGAllowedTypesVideo:
            [allowedTypes addObject:(NSString *)kUTTypeMovie];
            break;
            
        default:
            [allowedTypes addObject:(NSString *)kUTTypeImage];
            [allowedTypes addObject:(NSString *)kUTTypeMovie];
            break;
    }
    
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.mediaTypes = allowedTypes;
    
    switch (captureMode) {
        case UIImagePickerControllerCameraCaptureModeVideo:
            [imagePickerController setCameraCaptureMode:UIImagePickerControllerCameraCaptureModeVideo];
            break;
        case UIImagePickerControllerCameraCaptureModePhoto:
            [imagePickerController setCameraCaptureMode:UIImagePickerControllerCameraCaptureModePhoto];
        default:
            break;
    }
    
    imagePickerController.delegate = delegate;
    imagePickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
    
    [[(UINavigationController *)self.selectedViewController topViewController] presentViewController:imagePickerController
                                                                                            animated:YES
                                                                                          completion:nil];
    
}

@end
