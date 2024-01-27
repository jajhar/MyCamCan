#import "BGControllerBase.h"
#import "BGController_Inner.h"
#import "BGController_Inherit.h"
//#import "BGControllerHeader_Owner.h"

#import "AppData.h"
#import "User.h"
//#import "Uploads.h"

#import "BGViewBase.h"
#import "BGControllerNavigation.h"
#import "BGViewNavigation.h"
#import "BG_Requests.h"
#import "LocalSession.h"

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

//#import "UIImage+BGFixOrientation.h"

#import "Media.h"
#import <AVFoundation/AVFoundation.h>

NSString *kBGKeyImagePickerDelegate = @"BGKeyImagePickerDelegate";

const CGFloat kVXControllerBase_AnimationDuration = 0.3f;

__strong static BGControllerBase *_instance = nil;


#pragma mark - ================================================================


NS_INLINE CGPoint CGRectGetCenter(CGRect rect) {
    CGPoint center = CGPointMake(CGRectGetMidX(rect),
                                 CGRectGetMidY(rect));
    return center;
}


@interface BGNavigationTransitioner : NSObject <UIViewControllerAnimatedTransitioning>
{
    UINavigationControllerOperation _operation;
    BGNavigationAnimationDirection  _animationDirection;
}

- (id)initWithOperation:(UINavigationControllerOperation)operation direction:(BGNavigationAnimationDirection)direction;

@end


@implementation BGNavigationTransitioner


#pragma mark - Initialization


- (id)initWithOperation:(UINavigationControllerOperation)operation direction:(BGNavigationAnimationDirection)direction {
    self = [super init];
    if (self) {
        _operation = operation;
        _animationDirection = direction;
    }
    return self;
}


#pragma mark - UIViewControllerAnimatedTransitioning


- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    // get all objects involved
	UIViewController *controllerOut = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	UIViewController *controllerIn = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	UIView *containerView = transitionContext.containerView;
	UIView *viewOut = controllerOut.view;
	UIView *viewIn = controllerIn.view;
    
    CGRect frameFinalIn = [transitionContext finalFrameForViewController:controllerIn];
    
    // add incming view to container
	[containerView addSubview:viewIn];
    
    // perform animation
    if (transitionContext.isAnimated) {
        // all animations are the same - shift
        CGRect frameInititialIn = frameFinalIn;
        CAMediaTimingFunction *timingFunction;
        switch (_operation) {
            case UINavigationControllerOperationPush:
                // animation direction used only for push operations
                switch (_animationDirection) {
                    case kVXNavigationAnimationDirection_FromRight:
                        // shift to left
                        frameInititialIn.origin.x += frameFinalIn.size.width;
                        timingFunction =[CAMediaTimingFunction functionWithControlPoints:0.f :0.4f :0.6f :1.f];
                        break;
                        
                    case kVXNavigationAnimationDirection_FromLeft:
                        // shift to right
                        frameInititialIn.origin.x -= frameFinalIn.size.width;
                        timingFunction =[CAMediaTimingFunction functionWithControlPoints:0.0f :0.6f :0.4f :1.f];
                        break;
                }
                break;
                
            case UINavigationControllerOperationPop:
                // shift to right
                frameInititialIn.origin.x -= frameFinalIn.size.width;
                timingFunction =[CAMediaTimingFunction functionWithControlPoints:0.0f :0.6f :0.4f :1.f];
                break;
                
            default:
                timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                break;
        }
        viewIn.frame = frameInititialIn;
        
        // create complex animation
        [CATransaction begin];
        [CATransaction setAnimationDuration:kVXControllerBase_AnimationDuration];
        [CATransaction setAnimationTimingFunction:timingFunction];
        [CATransaction setCompletionBlock:^{
            [viewOut removeFromSuperview];
            // completed!
            [transitionContext completeTransition:YES];
        }];
        // in-view
        CABasicAnimation *moveInAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        moveInAnimation.fromValue = [NSValue valueWithCGPoint:CGRectGetCenter(frameInititialIn)];
        moveInAnimation.toValue = [NSValue valueWithCGPoint:CGRectGetCenter(frameFinalIn)];
        [viewIn.layer addAnimation:moveInAnimation forKey:@"moveIn"];
        [CATransaction commit];
        // set view properties right now, because layer animation is not what the real values are
        // with this we eliminate glitches at the end of the animation
        viewIn.frame = frameFinalIn;
    } else {
        // no animation
        // set everything to final positions
        viewIn.frame = frameFinalIn;
        [viewOut removeFromSuperview];
        // completed!
        [transitionContext completeTransition:YES];
    }
}


- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
	if (transitionContext.isAnimated) {
		return kVXControllerBase_AnimationDuration;
	} else {
		return (NSTimeInterval)0;
	}
}


@end


#pragma mark - ================================================================


@interface BGControllerBase () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

//L0

- (void)swipeLeftToRight:(UISwipeGestureRecognizer *)gesture;
- (void)swipeRightToLeft:(UISwipeGestureRecognizer *)gesture;

//L1

@property (strong, nonatomic) UIViewController *overlayController;
@property (strong, nonatomic) BGViewNavigation *headerView;
@property (strong, nonatomic) BGViewBanner *bannerView;
//@property (strong, nonatomic) BGViewRecorder *recorderView;
@property (strong, nonatomic) BGControllerNavigation *navigationController;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) NSNumber* allowedMediaTypes;

@property (weak, nonatomic) UISwipeGestureRecognizer *swipeLeftToRight;
@property (weak, nonatomic) UISwipeGestureRecognizer *swipeRightToLeft;;
@property (strong, nonatomic) UIActionSheet *actionSheet;
- (BGController *)showInitialLogin:(BOOL)firstTime;

//L2

- (BOOL)removeControllersRequiringSessionAnimated:(BOOL)animated;

@end


@implementation BGControllerBase


#pragma mark L0


@synthesize pushAnimationDirection = _pushAnimationDirection;


- (void)swipeLeftToRight:(UISwipeGestureRecognizer *)gesture {
   
}

- (void)swipeRightToLeft:(UISwipeGestureRecognizer *)gesture {
    
}

#pragma mark L1

@synthesize overlayController = _overlayController;

@synthesize navigationController = _navigationController;

@synthesize swipeLeftToRight = _swipeLeftToRight;
@synthesize swipeRightToLeft = _swipeRightToLeft;

- (BGController *)showInitialLogin:(BOOL)firstTime {
//   
//    AppData *AppData = [AppData sharedInstance];
//
//    if ([AppData restoreLocalSession] && AppData.localSession.oauthToken != nil && AppData.localUser.theId != nil) {
//        
//        // login anyway just to update the local session
//        [[BGMCC sharedInstance] loggedInUserFor:nil callback:^(User *user) {
//            if(user) {
//                [self.headerView setUser:AppData.localUser animated:NO]; // update the headerview for new login user
//            }
//        }];
//        
//        if(self.initialBlock == nil) {
//            [self presentControllerForPurpose:kBGPurposeCapsules animated:YES fromRight:YES info:nil];
//        } else {
//            self.initialBlock();
//        }
//        
//    }else {
//        //show splash
//        if (firstTime) {
//            [self presentOverlayControllerWithId:kVXControllerSplash animated:NO];
//        }
//        
//        // attempt login
//        [[BGMCC sharedInstance] loggedInUserFor:self callback:^(User *user) {
//            if (user != nil && ![user isKindOfClass:[NSError class]]) {
//                if (user.firstTimeUser) {
//                    [self presentControllerForPurpose:kBGPurposeTutorial animated:YES fromRight:YES info:nil];
//                } else {
//                    [self presentControllerForPurpose:kBGPurposeCapsules animated:YES fromRight:YES info:nil];
//                }
//            }else if(![user isKindOfClass:[NSError class]]){
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Uh Oh!" message:@"We were unable to pull your profile data. Please try again in a few minutes" delegate:self cancelButtonTitle:@"ok" otherButtonTitles:nil];
//                [alert show];
//                [self dismissOverlayControllerWithId:kVXControllerSplash animated:YES];
//                self.view = nil;
//            }else{
//                [self dismissOverlayControllerWithId:kVXControllerSplash animated:YES];
//                self.view = nil;
//            }
//        }];
//    }
//            
    return self;
}

- (void)executeBlock:(MCCBaseControllerBlock)block {
    if(block != nil) {
        block();
    }
}

#pragma mark L2

- (BOOL)removeControllersRequiringSessionAnimated:(BOOL)animated {
//    NSArray *controllers = self.navigationController.viewControllers;
//    NSIndexSet *validControllerIndexes = [controllers indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
//        return ![(BGController *)obj isKindOfClass:[BGControllerUser class]];
//    }];
//    if (validControllerIndexes.count == controllers.count) {
//        return NO;
//    } else {
//        [self.navigationController setViewControllers:[controllers objectsAtIndexes:validControllerIndexes] animated:animated];
//        return YES;
//    }
    return NO;
}


#pragma mark - Singleton


+ (BGControllerBase *)sharedInstance {
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{
        _instance = [[BGControllerBase alloc] init];
    });
    return _instance;
}


+ (id)alloc {
    @synchronized([BGControllerBase class]) {
        if(_instance != nil) {
            return _instance;
        }
        _instance = [super alloc];
        return _instance;
    }
    return nil;
}


#pragma mark - Inherited

#pragma mark UIViewController

- (void)loadView {
    [super loadView];
 
//    // swipe recognizers
//    __strong UISwipeGestureRecognizer *swipeLeftToRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeftToRight:)];
//    swipeLeftToRight.direction = UISwipeGestureRecognizerDirectionRight;
//    self.swipeLeftToRight = swipeLeftToRight;
//    __strong UISwipeGestureRecognizer *swipeRightToLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRightToLeft:)];
//    swipeRightToLeft.direction = UISwipeGestureRecognizerDirectionLeft;
//    self.swipeRightToLeft = swipeRightToLeft;
//
//    [self.navigationController.view addGestureRecognizer:self.swipeLeftToRight];
//    [self.navigationController.view addGestureRecognizer:self.swipeRightToLeft];
    
    self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:@"Camera", @"From library", nil];

    self.allowedMediaTypes = [NSNumber numberWithInteger:kVXMediaTypePhoto];
    
    self.headerView = [[[NSBundle mainBundle] loadNibNamed:@"BGViewNavigation" owner:nil options:nil] objectAtIndex:0];
    
    self.bannerView = [[[NSBundle mainBundle] loadNibNamed:@"BGViewBanner" owner:nil options:nil] objectAtIndex:0];
    
    self.navigationController = [BGControllerNavigation new];
    self.pushAnimationDirection = kVXNavigationAnimationDirection_FromRight;
    self.navigationController.delegate = self;
    
    BGViewBase *view = [[BGViewBase alloc]initWithHeaderView:self.headerView bannerView:self.bannerView navigationView:self.navigationController.view];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.view = view;
    
    AppData *appData = [AppData sharedInstance];
        
    if([appData restoreLocalSession] &&
       appData.localSession.oauthToken != nil &&
       appData.localUser.theId != nil)
    {
//        // login just to grab the user info and update it (also grabbing a new session key)
//        [[AppData sharedInstance]loginWithEmail:appData.localUser.username
//                                       password:appData.localSession.password
//                                    andCallback:nil];
        
        [self presentControllerForPurpose:kBGPurposeFeed
                                 animated:NO
                                fromRight:YES
                                     info:nil];
    } else {
        [self presentControllerForPurpose:kBGPurposeSplash
                                 animated:NO
                                fromRight:YES
                                     info:nil];
    }
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self addChildViewController:self.navigationController];
}

#pragma mark BGController(Inherit)

- (void)commonInit {
    [super commonInit];
   
}

- (void)setVisibilityState:(BGControllerVisibilityState)visibilityState {
    BGControllerVisibilityState oldState = self.visibilityState;
    [super setVisibilityState:visibilityState];
    BGControllerVisibilityState newState = self.visibilityState;
    if ((oldState == kVXControllerVisibilityStateNot) && BGControllerIsVisible(newState)) {
        //appeared for first time
    }
}

#pragma mark BGController(Requests)

- (BGController *)presentControllerForPurpose:(BGPurpose)purpose animated:(BOOL)animated fromRight:(BOOL)animationFromRight info:(id)info {
    
    if (purpose == kBGPurposeMediaCreate) {
        
        self.delegate = [info objectForKey:kBGKeyImagePickerDelegate];
        [self.actionSheet showInView:self.view];
        
        return nil;
    }
    
    if(purpose == kBGPurposeMediaPicker) {
        self.delegate = [info objectForKey:kBGKeyMediaPickerDelegate];
        self.allowedMediaTypes = [info objectForKey:kVXKeyMediaTypesAllowed];
        [self startMediaBrowserFromViewController:[BGControllerBase topMostController] usingDelegate:self.delegate];
        return nil;
    }
    
    BOOL dismissAllIfNotFound;
    NSDictionary *infoToCheckVersus;
    BOOL valid = YES;
   
    switch (purpose) {
        case kBGPurposeMediaPicker:
        case kBGPurposePostDetails:
        case kBGPurposeRegister:
        case kBGPurposeMusicPicker:
        case kBGPurposeSplash:
        case kBGPurposeImageCropper:
        case kBGPurposeOnboarding:
        case kBGPurposeContacts:
        case kBGPurposeLikes:
        {
            BGController *controller;
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"BlogStoryboard" bundle:nil];
            
            controller = [storyboard instantiateViewControllerWithIdentifier:[self controllerIdForPurpose:purpose]];
            
            [controller setInfo:info
                       animated:animated];
            
            controller.providesPresentationContextTransitionStyle = YES;
            controller.definesPresentationContext = YES;
            [controller setModalPresentationStyle:UIModalPresentationOverCurrentContext];
            
            [[BGControllerBase topMostController] presentViewController:controller animated:animated completion:^{
                
            }];
            
            return nil;
        }
        case kBGPurposeUsers:
            infoToCheckVersus = info;
            //these are not base controllers
            dismissAllIfNotFound = NO;
            break;
        
        case kBGPurposeProfile:
            infoToCheckVersus = info;

            if(info == nil || [info objectForKey:kVXKeyUser] == [AppData sharedInstance].localUser) {
                dismissAllIfNotFound = YES;
            } else {
                dismissAllIfNotFound = NO;
            }
            
            break;
        case kBGPurposeLogin:
        case kBGPurposeFeed:
        case kBGPurposeNotifications:
        case kBGPurposeSearch:
        {
            // base controllers
            infoToCheckVersus = nil;
            dismissAllIfNotFound = YES;
            break;
        }
        case kBGPurposeCamera:
            // modal view controllers
        {
            BGController *controller;
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"BlogStoryboard" bundle:nil];
            
            controller = [storyboard instantiateViewControllerWithIdentifier:[self controllerIdForPurpose:kBGPurposeCamera]];
            
            [controller setInfo:info
                       animated:animated];
            
            [[BGControllerBase topMostController] presentViewController:controller animated:animated completion:^{
                
            }];
            
            return nil;
        }
        default:
        
#if defined(DEBUG)
            NSAssert(NO, @"Should not happen");
#endif
            dismissAllIfNotFound = NO;
            infoToCheckVersus = info;
            valid = NO;
            break;
    }

    if (!valid) {
        return nil;
    }
//        [self.headerView closeMenusAnimated:animated];
    
    NSString *controllerId = [self controllerIdForPurpose:purpose];
    
    BOOL hasOverlay = (self.overlayController != nil);
    
    BGController *controller = [self dismissControllerWithId:controllerId
                                                withInfoLike:infoToCheckVersus
                                                 dismissType:kVXControllerDismissTypeToController
                                        dismissAllIfNotFound:dismissAllIfNotFound
                                             animatedIfFound:(animated && !hasOverlay)
                                          animatedIfNotFound:NO];
    

    
    BOOL controllerWasAvailable = (controller != nil);
    
    if (!controllerWasAvailable) {
        controller = [self controllerForId:controllerId];
    }
    
    [controller setInfo:info animated:(animated && controllerWasAvailable)];

    if (controllerWasAvailable) {
        // dat is so lame
//            if ([controller isKindOfClass:[BGControllerFeed class]]) {
//                [(BGControllerFeed *)controller scrollToTop];
//            } else if ([controller isKindOfClass:[BGControllerCapsules class]]) {
//                [(BGControllerCapsules *)controller scrollToTop];
//            } else if ([controller isKindOfClass:[BGControllerNotifications class]]) {
//                [(BGControllerNotifications *)controller scrollToTop];
//            }

        self.pushAnimationDirection = kVXNavigationAnimationDirection_FromLeft;

    } else {
        if (animationFromRight) {
            self.pushAnimationDirection = kVXNavigationAnimationDirection_FromRight;
        } else {
            self.pushAnimationDirection = kVXNavigationAnimationDirection_FromLeft;
        }
        
        if (!controllerWasAvailable && dismissAllIfNotFound) {
            [self.navigationController setViewControllers:[NSArray arrayWithObject:controller] animated:(!hasOverlay && animated)];
        } else {
            [self.navigationController pushViewController:controller animated:animated];
        }
    }
    
//        if (hasOverlay) {
//            if (animated) {
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                    [self dismissOverlayControllerWithId:kVXControllerSplash animated:YES];
//                });
//            } else {
//                [self dismissOverlayControllerWithId:kVXControllerSplash animated:NO];
//            }
//        }
    
    
    if (self.navigationController.viewControllers.count <= 1) {
        [self.bannerView hideBackButtonAnimated:NO];
    }
    
    return controller;
}

- (void)dismissController:(BGController *)controller animated:(BOOL)animated info:(id)info {
    [self dismissControllerWithId:NSStringFromClass(controller.class)
                     withInfoLike:info
                      dismissType:kVXControllerDismissTypeControllerOnly
             dismissAllIfNotFound:NO
                  animatedIfFound:animated
               animatedIfNotFound:NO];
}

#pragma mark BGController_Inner

- (void)presentOverlayControllerWithId:(NSString *)controllerId animated:(BOOL)animated {
    if ((controllerId != nil) && (self.overlayController == nil)) {
//        if ([controllerId isEqualToString:kVXControllerSplash]) {
//            BGControllerSplash *splash = [BGControllerSplash new];
//            [splash presentAsOverlayOnController:self animated:animated];
//            self.overlayController = splash;
//        }
        return;
    }
}

- (void)dismissOverlayControllerWithId:(NSString *)controllerId animated:(BOOL)animated {
    UIViewController<BGController> *presentedController = (UIViewController<BGController> *)self.overlayController;
    if ((controllerId != nil) && (presentedController != nil)) {
        if ([NSStringFromClass(presentedController.class) isEqualToString:controllerId]) {
            self.overlayController = nil;
            [presentedController dismissAnimated:animated];
        }
    }
}

- (BGController *)dismissControllerWithId:(NSString *)controllerId
                             withInfoLike:(NSDictionary *)infoLike
                              dismissType:(BGControllerDismissType)dismissType
                     dismissAllIfNotFound:(BOOL)dismissAll
                          animatedIfFound:(BOOL)animatedIfFound
                       animatedIfNotFound:(BOOL)animatedIfNotFound {
    if (controllerId != nil) {
        NSArray *controllers = self.navigationController.viewControllers;
        NSUInteger n = controllers.count;
        if (n > 0) {
            NSUInteger i = n;
            NSUInteger found = NSNotFound;
            BGController *foundController = nil;
            do {
                --i;
                foundController = [controllers objectAtIndex:i];
                if ([NSStringFromClass(foundController.class) isEqualToString:controllerId]) {
                    if ([foundController hasInfoLike:infoLike]) {
                        found = i;
                        break;
                    }
                }
            } while (i > 0);

            if (found == NSNotFound) {
                if (dismissAll) {
                    [self.navigationController setViewControllers:[NSArray arrayWithObject:self.navigationController.topViewController] animated:animatedIfNotFound];
                }
                return nil;
            } else {
                switch (dismissType) {
                    case kVXControllerDismissTypeToController:
                        ++found;
                        if (found == n) {
                            break;
                        }
                    case kVXControllerDismissTypeToControllerBehind:
                        if (found == 0) {
                            [self.navigationController setViewControllers:[NSArray new] animated:animatedIfFound];
                        } else if (found == 1) {
                            [self.navigationController popToRootViewControllerAnimated:animatedIfFound];
                        } else {
                            [self.navigationController popToViewController:[controllers objectAtIndex:(found - 1)] animated:animatedIfFound];
                        }
                        break;
                    case kVXControllerDismissTypeControllerOnly: {
                        NSMutableArray *newControllers = [controllers mutableCopy];
                        [newControllers removeObjectAtIndex:found];
                        [self.navigationController setViewControllers:newControllers animated:animatedIfFound];
                        break;
                    }
                }
                return foundController;
            }
        } else {
            return nil;
        }
    } else {
        return nil;
    }


    if (controllerId != nil) {
        NSArray *controllers = self.navigationController.viewControllers;
        NSUInteger n = controllers.count;
        if (n > 0) {
            NSUInteger i;
            NSUInteger found = NSNotFound;
            UIViewController *controller;
            for (i = 0;i < n;++i) {
                controller = [controllers objectAtIndex:i];
                if ([NSStringFromClass(controller.class) isEqualToString:controllerId]) {
                    found = i;
                    break;
                }
            }
            if (found == NSNotFound) {
                if (dismissAll) {
                    [self.navigationController setViewControllers:[NSArray arrayWithObject:self.navigationController.topViewController] animated:animatedIfNotFound];
                }
                return nil;
            } else {
                BGController *controller = [controllers objectAtIndex:found];
                [self.navigationController popToViewController:controller animated:animatedIfFound];
                return controller;
            }
        } else {
            return nil;
        }
    } else {
        if (dismissAll) {
            [self.navigationController setViewControllers:[NSArray new] animated:animatedIfNotFound];
        }
        return nil;
    }
}

+ (UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

#pragma mark - Protocols


#pragma mark UINavigationControllerDelegate


- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    //header setup
//    [self.headerView closeMenusAnimated:animated];

//    if ([viewController isKindOfClass:[BGControllerHeader class]]) {
//        [(BGControllerHeader *)viewController setHeaderView:self.headerView];
//        [(BGControllerHeader *)viewController setBannerView:self.bannerView];
//    }
    
    // hide iOS status bar on camera only
    if([navigationController isKindOfClass:[UIImagePickerController class]]) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }

    //header interaction
//    self.headerView.userInteractionEnabled = NO;

    //recorder setup

    //swipes interaction
    self.swipeRightToLeft.enabled = NO;
    self.swipeLeftToRight.enabled = NO;

    //select header's button for base controllers
    if ([viewController isKindOfClass:[BGController class]]) {
        
            //check controller type and select appropriate button
            if ([viewController isKindOfClass:[BGControllerFeed class]]) {
                //feed
                [self.headerView setSelectedNavigationOption:kNavigationOptionHome];
            } else if ([viewController isKindOfClass:[BGControllerSearch class]]) {
                //capsules
                [self.headerView setSelectedNavigationOption:kNavigationOptionSearch];
            } else if ([viewController isKindOfClass:[BGControllerNotifications class]]) {
                //notifications
                [self.headerView setSelectedNavigationOption:kNavigationOptionNotifications];
            } else if ([viewController isKindOfClass:[BGControllerProfile class]]) {
                //search
                [self.headerView setSelectedNavigationOption:kNavigationOptionProfile];
            } else {
                //unknown, no button to select
                [self.headerView setSelectedNavigationOption:kNavigationOptionNone];
            }
    } else {
        [self.headerView setSelectedNavigationOption:kNavigationOptionNone];
    }

    //fillscreen
    if ([viewController isKindOfClass:[BGControllerLogin class]] ||
        [viewController isKindOfClass:[BGControllerRegister class]] ||
        [viewController isKindOfClass:[BGControllerCamera class]] ||
        [viewController isKindOfClass:[BGControllerMusicPicker class]] ||
        [viewController isKindOfClass:[BGControllerSplash class]] ||
//        [viewController isKindOfClass:[BGControllerNotifications class]] ||
//        [viewController isKindOfClass:[BGControllerSearch class]] ||
        [viewController isKindOfClass:[BGControllerMediaPicker class]] ||
        [viewController isKindOfClass:[BGControllerImageCropper class]] ||
        [viewController isKindOfClass:[BGControllerOnboarding class]]  ||
//        [viewController isKindOfClass:[BGControllerLikes class]] ||
        [viewController isKindOfClass:[BGControllerContacts class]])
    {
        [(BGViewBase *)self.view fullscreenNavigation:YES animated:animated];
    } else {
        [(BGViewBase *)self.view fullscreenNavigation:NO animated:animated];
    }
    
//    if ([viewController isKindOfClass:[BGControllerCamera class]] ||
//        [viewController isKindOfClass:[BGControllerMusicPicker class]]) {
//        [(BGViewBase *)self.view hideHeaderView];
//    } else {
//        [(BGViewBase *)self.view showHeaderView];
//    }
    
    if (navigationController.viewControllers.count <= 1) {
        [self.bannerView hideBackButtonAnimated:NO];
    }
}


- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    //header interaction
//    self.headerView.userInteractionEnabled = YES;
}


- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC {
#pragma unused(navigationController)
#pragma unused(fromVC)
#pragma unused(toVC)
	return [[BGNavigationTransitioner alloc] initWithOperation:operation direction:self.pushAnimationDirection];
}


- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                         interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
#pragma unused(navigationController)
#pragma unused(animationController)
	return nil;
}


- (UIInterfaceOrientation)navigationControllerPreferredInterfaceOrientationForPresentation:(UINavigationController *)navigationController {
#pragma unused(navigationController)
	return UIInterfaceOrientationPortrait;
}


- (UIInterfaceOrientationMask)navigationControllerSupportedInterfaceOrientations:(UINavigationController *)navigationController {
#pragma unused(navigationController)
	return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - UIImagePickerController Presentation


- (BOOL) startMediaBrowserFromViewController: (UIViewController*) controller

                               usingDelegate: (id <UIImagePickerControllerDelegate,
                                               
                                               UINavigationControllerDelegate>) delegate {
    
    if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == NO) ||
        (delegate == nil) ||
        (controller == nil))
    {
        
        return NO;
    }
    
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    
    mediaUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    // Displays saved pictures and movies, if both are available, from the
    
    // Camera Roll album.
    
    // media types are video and image
    NSMutableArray *allowedTypes = [NSMutableArray new];
    
    switch([self.allowedMediaTypes integerValue])
    {
        case kVXMediaTypeAll:
            [allowedTypes addObject:(NSString *)kUTTypeImage];
            [allowedTypes addObject:(NSString *)kUTTypeMovie];
            break;
        case kVXMediaTypePhoto:
            [allowedTypes addObject:(NSString *)kUTTypeImage];
            break;
        case kVXMediaTypeVideo:
            [allowedTypes addObject:(NSString *)kUTTypeMovie];
            break;
        case kVXMediaTypeNone:
            // default everything
            [allowedTypes addObject:(NSString *)kUTTypeImage];
            [allowedTypes addObject:(NSString *)kUTTypeMovie];
        default:
            [allowedTypes addObject:(NSString *)kUTTypeImage];
            [allowedTypes addObject:(NSString *)kUTTypeMovie];
            break;
    }
    
    mediaUI.mediaTypes = allowedTypes;
    
    // Hides the controls for moving & scaling pictures, or for
    
    // trimming movies. To instead show the controls, use YES.
    
    mediaUI.allowsEditing = NO;
    
    mediaUI.delegate = self;
    
    [controller presentViewController:mediaUI animated:YES completion:nil];
    
    return YES;
    
}



#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    bool cancelled = false;
    
    __block NSInteger sourceTypeToUse = 0;
    
    // has the user opted to show the photo gallery or the camera?
    switch ( buttonIndex )
    {
        case 1:
        {
            __block BGControllerBase *weakSelf = self;
            
            ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
            
            if (status != ALAuthorizationStatusNotDetermined && status != ALAuthorizationStatusAuthorized) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Camera Roll Access Denied!" message:@"Please enable camera roll access! Go to Settings -> Privacy -> Camera roll -> Enable \"Blog\"" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil, nil];
                [alert show];
            }
            else
            {

                [weakSelf presentControllerForPurpose:kBGPurposeMediaPicker
                                             animated:YES
                                            fromRight:YES
                                                 info:@{kBGKeyMediaPickerDelegate: self.delegate}];
                
            }
            
            return;
            break;
        }
        case 0:
        {
            //Granted access to mediaType
            sourceTypeToUse = UIImagePickerControllerSourceTypeCamera;
            
            AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            if (authStatus == AVAuthorizationStatusAuthorized) {
                // successful
                NSString *mediaAudio = AVMediaTypeAudio;
                [AVCaptureDevice requestAccessForMediaType:mediaAudio completionHandler:^(BOOL grantedAudio) {
                    if (grantedAudio)
                    {
                        //Granted access to mediaType
                        // sourceTypeToUse = UIImagePickerControllerSourceTypeCamera;
                    }
                    else
                    {
                        //Not granted access to mediaType
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[[UIAlertView alloc] initWithTitle:@"Microphone Access Denied!"
                                                        message:@"Please enable microphone access! Go to Settings -> Privacy -> Microphone -> Enable \"Blog\""
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil] show];
                        });
                    }
                }];
                
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Camera access Denied!"
                                            message:@"Please enable camera access! Go to Settings -> Privacy -> Camera -> Enable \"Blog\""
                                           delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];

            }
            
        }
            break;
        default:
            cancelled = YES;
            break;
    }
    if ( cancelled == NO )
    {
        UIImagePickerController * imagePickerController = [[UIImagePickerController alloc] init];
        
        imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
        
        imagePickerController.sourceType = sourceTypeToUse;
        
        // media types are video and image
        NSMutableArray *allowedTypes = [NSMutableArray new];
        
        switch([self.allowedMediaTypes integerValue])
        {
            case kVXMediaTypeAll:
                [allowedTypes addObject:(NSString *)kUTTypeImage];
                [allowedTypes addObject:(NSString *)kUTTypeMovie];
                break;
            case kVXMediaTypePhoto:
                [allowedTypes addObject:(NSString *)kUTTypeImage];
                break;
            case kVXMediaTypeVideo:
                [allowedTypes addObject:(NSString *)kUTTypeMovie];
                break;
            case kVXMediaTypeNone:
            default:
                [allowedTypes addObject:(NSString *)kUTTypeImage];
                [allowedTypes addObject:(NSString *)kUTTypeMovie];
                break;
        }

        imagePickerController.mediaTypes = allowedTypes;
        
        imagePickerController.delegate = self;
        
        self.imagePickerController = imagePickerController;
        
        UIViewController *rootController = [UIApplication sharedApplication].delegate.window.rootViewController;
        [rootController presentViewController:self.imagePickerController animated:YES completion:nil];
    }
}


#pragma mark - UIImagePickerControllerDelegate

// TODO: HD: all of this camera impl needs to move out of the base class

// This method is called when an image has been chosen from the library or taken from the camera
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    Media * media = nil;

    // determine the media type
    NSString * mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    if ( CFStringCompare((__bridge CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo )
    {
        NSURL * videoUrl = (NSURL*)[info objectForKey:UIImagePickerControllerMediaURL];
        NSString * moviePath = [videoUrl path];

        // extract the media
        media = [Media mediaWithMovieAtPath:moviePath];
        
        // save to library
        if (picker.sourceType != UIImagePickerControllerSourceTypePhotoLibrary && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(moviePath) ) {
            UISaveVideoAtPathToSavedPhotosAlbum(moviePath, nil, nil, nil);
        }
        else {
            // TODO: HD: log info here
        }
    }
    else if ( CFStringCompare((__bridge CFStringRef) mediaType, kUTTypeImage, 0) == kCFCompareEqualTo )
    {
        UIImage * image = [info valueForKey:UIImagePickerControllerOriginalImage];
        
        //image = [image fixOrientation];
        
        // extract the media
        media = [Media mediaWithImage:image];

        
        if(picker.sourceType != UIImagePickerControllerSourceTypePhotoLibrary) {
            // save to library
            UIImageWriteToSavedPhotosAlbum(image,
                                           self,
                                           @selector(file:didFinishSavingWithError:contextInfo:),
                                           @selector(file:didFinishSavingWithError:contextInfo:));
        }

    }
    else
    {
        // TODO: HD: log error here, new type that we are not handling!
    }

    [[BGControllerBase topMostController] dismissViewControllerAnimated:YES completion:^{
        if (media != nil) {
            [self.delegate imagePickerDidFinishPickingMedia:[NSArray arrayWithObjects:media, nil]];
        }
    }];//     {
    
        //self.defaultRecorderCallback(nil, [NSArray arrayWithObject:media], nil);
    
         // TODO: HD: see if this class cleans up the original image when the uplaod is complete
//     }];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    UIViewController *rootController = [UIApplication sharedApplication].delegate.window.rootViewController;

    [rootController dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)file:(NSString *)filePath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if(error) {
        NSLog(@"Error saving to camera roll: %@", error);
    } else {
        NSLog(@"Finished saving file to path: %@", filePath);
    }
}


#pragma mark Banner

- (void)showBackButton:(BGViewBannerBackButtonCallback)callback animated:(BOOL)animated {
    [self.bannerView showBackButton:callback animated:animated];
}

#pragma mark BG_Requests

- (BGController *)controllerForId:(NSString *)controllerId {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"BlogStoryboard" bundle:[NSBundle mainBundle]];
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
        case kBGPurposeMediaPicker:
            return kBGControllerMediaPicker;
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
        case kBGPurposeSearch:
            return kBGControllerSearch;
        case kBGPurposeContacts:
            return kBGControllerContacts;
        case kBGPurposeOnboarding:
            return kBGControllerOnboarding;
        case kBGPurposePostDetails:
            return @"BGControllerPostDetails";
        case kBGPurposeUsers:
            return @"BGControllerUsers";
        default:
#if defined(DEBUG)
            NSAssert(NO, @"Snape kills dumbledore...");
#endif
            return nil;
            break;
    }
}

- (void)setHeaderTitle:(NSString *)title {
    [self.bannerView setTitle:title];
}

- (void)setHeaderColor:(UIColor *)color {
    [self.bannerView setColor:color];
}


@end
