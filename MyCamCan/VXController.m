#import "VXController.h"
#import "VXController_Inner.h"
#import "VXController_Inherit.h"
#import "Flurry.h"
#import "VXStyle.h"

NSString *kVXKeyCapsule = @"VXKeyCapsule";
NSString *kVXKeyMedia = @"VXKeyMedia";
NSString *kVXKeyUser = @"VXKeyUser";

@interface VXController ()

//L1

@property (strong, nonatomic) CAAnimation *overlayAppearAnimation;
@property (strong, nonatomic) CAAnimation *overlayDisappearAnimation;

@end

@implementation VXController

#pragma mark L1

@synthesize canBePresented = _canBePresented;
@synthesize presentationType = _presentationType;
@synthesize visibilityState = _visibilityState;
@synthesize owner = _owner;
@synthesize autoDismissesSelf = _autoDismissesSelf;

@synthesize callbackWillBePresentedBy = _callbackWillBePresentedBy;
@synthesize callbackWasPresentedBy = _callbackWasPresentedBy;
@synthesize callbackWillBeDismissedBy = _callbackWillBeDismissedBy;
@synthesize callbackWasDismissedBy = _callbackWasDismissedBy;

@synthesize overlayAppearAnimation = _overlayAppearAnimation;
@synthesize overlayDisappearAnimation = _overlayDisappearAnimation;

#pragma mark - Inherited

#pragma mark NSObject(UINibLoading)

- (void)awakeFromNib {
    [super awakeFromNib];

    [self commonInit];
}

#pragma mark UIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) != nil) {
        [self commonInit];
    }
    return self;
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    if (parent == nil) {
        if (self.presentationType == kVXControllerPresentationTypeNavigationChild) {
            self.presentationType = kVXControllerPresentationTypeNot;
        } else if (self.presentationType == kVXControllerPresentationTypeOverlay) {
            self.presentationType = kVXControllerPresentationTypeNot;
        }
    } else if ((parent != nil) && (self.presentationType == kVXControllerPresentationTypeNot)) {
        self.presentationType = kVXControllerPresentationTypeNavigationChild;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    if ((self.presentationType == kVXControllerPresentationTypeNot) && (self.presentingViewController != nil)) {
        self.presentationType = kVXControllerPresentationTypeModally;
    }

    [super viewWillAppear:animated];

    if (animated) {
        self.visibilityState = kVXControllerVisibilityStateAppearing;
    }
    if (self.callbackWillBePresentedBy != nil) {
        switch (self.presentationType) {
            case kVXControllerPresentationTypeNot:
                self.callbackWillBePresentedBy(self,nil);
                break;
            case kVXControllerPresentationTypeNavigationChild:
                self.callbackWillBePresentedBy(self,self.parentViewController);
                break;
            case kVXControllerPresentationTypeModally:
                self.callbackWillBePresentedBy(self,self.presentingViewController);
                break;
            case kVXControllerPresentationTypeOverlay:
                self.callbackWillBePresentedBy(self,self.parentViewController);
                break;
        }

    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.visibilityState = kVXControllerVisibilityStateVisible;
    if (self.callbackWasPresentedBy != nil) {
        switch (self.presentationType) {
            case kVXControllerPresentationTypeNot:
                self.callbackWasPresentedBy(self,nil);
                break;
            case kVXControllerPresentationTypeNavigationChild:
                self.callbackWasPresentedBy(self,self.parentViewController);
                break;
            case kVXControllerPresentationTypeModally:
                self.callbackWasPresentedBy(self,self.presentingViewController);
                break;
            case kVXControllerPresentationTypeOverlay:
                self.callbackWasPresentedBy(self,self.parentViewController);
                break;
        }

    }
}

- (void)viewWillDisappear:(BOOL)animated {
    if (self.callbackWillBeDismissedBy != nil) {
        switch (self.presentationType) {
            case kVXControllerPresentationTypeNot:
                self.callbackWillBeDismissedBy(self,nil);
                break;
            case kVXControllerPresentationTypeNavigationChild:
                self.callbackWillBeDismissedBy(self,self.parentViewController);
                break;
            case kVXControllerPresentationTypeModally:
                self.callbackWillBeDismissedBy(self,self.presentingViewController);
                break;
            case kVXControllerPresentationTypeOverlay:
                self.callbackWillBeDismissedBy(self,self.parentViewController);
                break;
        }

    }
    if (animated) {
        self.visibilityState = kVXControllerVisibilityStateDisappearing;
    }

    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    if (self.callbackWasDismissedBy != nil) {
        switch (self.presentationType) {
            case kVXControllerPresentationTypeNot:
                self.callbackWasDismissedBy(self,nil);
                break;
            case kVXControllerPresentationTypeNavigationChild:
                self.callbackWasDismissedBy(self,self.parentViewController);
                break;
            case kVXControllerPresentationTypeModally:
                self.callbackWasDismissedBy(self,self.presentingViewController);
                break;
            case kVXControllerPresentationTypeOverlay:
                self.callbackWasDismissedBy(self,self.parentViewController);
                break;
        }

    }
    self.visibilityState = kVXControllerVisibilityStateDisappeared;

    [super viewDidDisappear:animated];

    if (self.presentationType == kVXControllerPresentationTypeModally) {
        self.presentationType = kVXControllerPresentationTypeNot;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [Flurry logAllPageViewsForTarget:self];
    
    self.view.backgroundColor = [[VXStyle sharedInstance] colorWithName:kVXStyle_Color_AppBackground];
}

#pragma mark - Protocols

#pragma mark VXController

- (void)setInfo:(NSDictionary *)info animated:(BOOL)animated {
    //nop
}

- (BOOL)hasInfoLike:(NSDictionary *)info {
    return YES;
}

#pragma mark VX_HasOwner

- (id<VX_Requests>)owner {
    return _owner;
}

- (void)setOwner:(id<VX_Requests>)owner {
    _owner = owner;
}

#pragma mark VX_Requests

- (NSString *)controllerIdForPurpose:(VXPurpose)purpose {
    return [self.owner controllerIdForPurpose:purpose];
}

- (VXController *)controllerForId:(NSString *)controllerId {
    return [self.owner controllerForId:controllerId];
}

- (VXController *)presentControllerForPurpose:(VXPurpose)purpose animated:(BOOL)animated fromRight:(BOOL)animationFromRight info:(id)info {
    return [self.owner presentControllerForPurpose:purpose animated:animated fromRight:animationFromRight info:info];
}

- (void)dismissController:(VXController *)controller animated:(BOOL)animated info:(id)info {
    [self.owner dismissController:controller animated:animated info:info];
}

#pragma mark VXController_Presentation

- (void)presentOnNavigationStack:(UINavigationController *)navigationController animated:(BOOL)animated {
    if (self.canBePresented) {
        if (navigationController != nil) {
            [navigationController pushViewController:self animated:animated];
        }
    } else {
        DDLogError(@"%@ reports it cannot be presented",self);
    }
}

- (void)presentModallyOnController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.canBePresented) {
        if (viewController != nil) {
            [viewController presentViewController:self animated:animated completion:nil];
        }
    } else {
        DDLogError(@"%@ reports it cannot be presented",self);
    }
}

- (void)presentAsOverlayOnController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.canBePresented) {
        self.presentationType = kVXControllerPresentationTypeOverlay;

        [viewController addChildViewController:self];
        [self viewWillAppear:animated];
        self.view.frame = viewController.view.bounds;
        CGRect frame = self.view.frame;
        frame.origin.y -= 32.0; /* whyyy this? figure out later */
        self.view.frame = frame;
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [viewController.view addSubview:self.view];

        if (animated) {
            CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            alphaAnimation.duration = 0.25;
            alphaAnimation.fromValue = [NSNumber numberWithFloat:[(CALayer *)[self.view.layer presentationLayer] opacity]];
            alphaAnimation.toValue = [NSNumber numberWithFloat:1];
            alphaAnimation.delegate = self;
            [self.view.layer addAnimation:alphaAnimation forKey:@"opacity"];
            self.overlayAppearAnimation = alphaAnimation;

            self.view.layer.opacity = 1;
        } else {
            self.view.layer.opacity = 1;

            [self.view.layer removeAnimationForKey:@"opacity"];

            [self viewDidAppear:NO];
            [self didMoveToParentViewController:viewController];
        }
    } else {
        DDLogError(@"%@ reports it cannot be presented",self);
    }
}

- (void)dismissAnimated:(BOOL)animated {
    switch (self.presentationType) {
        case kVXControllerPresentationTypeNot:
            //nop
            break;
        case kVXControllerPresentationTypeNavigationChild: {
            UINavigationController *navigationController = (UINavigationController *)self.parentViewController;
            if (navigationController != nil) {
                NSMutableArray *newControllers = [navigationController.viewControllers mutableCopy];
                [newControllers removeObject:self];
                [navigationController setViewControllers:newControllers animated:animated];
            }
            break;
        }
        case kVXControllerPresentationTypeModally:
            [self.presentingViewController dismissViewControllerAnimated:animated completion:nil];
            break;
        case kVXControllerPresentationTypeOverlay:
            //strictly this call order
            [self viewWillDisappear:animated];

            if (animated) {
                CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
                alphaAnimation.duration = 0.25;
                alphaAnimation.fromValue = [NSNumber numberWithFloat:[(CALayer *)[self.view.layer presentationLayer] opacity]];
                alphaAnimation.toValue = [NSNumber numberWithFloat:0];
                alphaAnimation.delegate = self;
                [self.view.layer addAnimation:alphaAnimation forKey:@"opacity"];
                self.overlayDisappearAnimation = alphaAnimation;

                self.view.layer.opacity = 0;
            } else {
                self.view.layer.opacity = 0;

                [self.view.layer removeAnimationForKey:@"opacity"];

                [self.view removeFromSuperview];
                [self viewDidDisappear:animated];
                [self removeFromParentViewController];
            }
            break;
    }
}

- (VXControllerPresentationType)presentationType {
    return _presentationType;
}

- (VXControllerVisibilityState)visibilityState {
    return _visibilityState;
}

- (BOOL)autoDismissesSelf {
    return _autoDismissesSelf;
}

- (void)setAutoDismissesSelf:(BOOL)autoDismissesSelf {
    _autoDismissesSelf = autoDismissesSelf;
}

#pragma mark VXController_Callbacks

- (VXControllerCallback)callbackWillBePresentedBy {
    return _callbackWillBePresentedBy;
}

- (void)setCallbackWillBePresentedBy:(VXControllerCallback)callbackWillBePresentedBy {
    _callbackWillBePresentedBy = callbackWillBePresentedBy;
}

- (VXControllerCallback)callbackWasPresentedBy {
    return _callbackWasPresentedBy;
}

- (void)setCallbackWasPresentedBy:(VXControllerCallback)callbackWasPresentedBy {
    _callbackWasPresentedBy = callbackWasPresentedBy;
}

- (VXControllerCallback)callbackWillBeDismissedBy {
    return _callbackWillBeDismissedBy;
}

- (void)setCallbackWillBeDismissedBy:(VXControllerCallback)callbackWillBeDismissedBy {
    _callbackWillBeDismissedBy = callbackWillBeDismissedBy;
}

- (VXControllerCallback)callbackWasDismissedBy {
    return _callbackWasDismissedBy;
}

- (void)setCallbackWasDismissedBy:(VXControllerCallback)callbackWasDismissedBy {
    _callbackWasDismissedBy = callbackWasDismissedBy;
}

#pragma mark VXController_Inherit

- (void)commonInit {
    self.canBePresented = YES;
    self.presentationType = kVXControllerPresentationTypeNot;
    self.visibilityState = kVXControllerVisibilityStateNot;
}

#pragma mark VXController_Inner

- (void)presentOverlayControllerWithId:(NSString *)controllerId animated:(BOOL)animated {
    //nop
}

- (void)dismissOverlayControllerWithId:(NSString *)controllerId animated:(BOOL)animated {
    //nop
}

- (VXController *)dismissControllerWithId:(NSString *)controllerId
                             withInfoLike:(NSDictionary *)infoLike
                              dismissType:(VXControllerDismissType)dismissType
                     dismissAllIfNotFound:(BOOL)dismissAll
                          animatedIfFound:(BOOL)animatedIfFound
                       animatedIfNotFound:(BOOL)animatedIfNotFound {
    //nop
    return nil;
}

#pragma mark CAAnimation delegate methods

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (anim == self.overlayAppearAnimation) {
        [self viewDidAppear:NO];
        [self didMoveToParentViewController:self.parentViewController];
        self.overlayAppearAnimation = nil;
    } else if (anim == self.overlayDisappearAnimation) {
        [self.view removeFromSuperview];
        [self viewDidDisappear:NO];
        [self removeFromParentViewController];
        self.overlayDisappearAnimation = nil;
    }
}

@end
