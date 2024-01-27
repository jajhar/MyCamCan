#import "VXControllerNavigation.h"
#import "VXController_Inherit.h"
#import "VXController_Inner.h"


@interface VXControllerNavigation () <VXController_Inherit, VXController_Inner, UINavigationControllerDelegate>

//L1

@property (strong, nonatomic) CABasicAnimation *overlayAppearAnimation;
@property (strong, nonatomic) CABasicAnimation *overlayDisappearAnimation;

@end

@implementation VXControllerNavigation

#pragma mark L1

@synthesize canBePresented = _canBePresented;

- (void)setCanBePresented:(BOOL)canBePresented {
    if (_canBePresented != canBePresented) {
        _canBePresented = canBePresented;
        if (!_canBePresented) {
            [self dismissAnimated:YES];
        }
    }
}

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
                self.callbackWillBePresentedBy((VXController *)self,nil);
                break;
            case kVXControllerPresentationTypeNavigationChild:
                self.callbackWillBePresentedBy((VXController *)self,self.parentViewController);
                break;
            case kVXControllerPresentationTypeModally:
                self.callbackWillBePresentedBy((VXController *)self,self.presentingViewController);
                break;
            case kVXControllerPresentationTypeOverlay:
                self.callbackWillBePresentedBy((VXController *)self,self.parentViewController);
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
                self.callbackWasPresentedBy((VXController *)self,nil);
                break;
            case kVXControllerPresentationTypeNavigationChild:
                self.callbackWasPresentedBy((VXController *)self,self.parentViewController);
                break;
            case kVXControllerPresentationTypeModally:
                self.callbackWasPresentedBy((VXController *)self,self.presentingViewController);
                break;
            case kVXControllerPresentationTypeOverlay:
                self.callbackWasPresentedBy((VXController *)self,self.parentViewController);
                break;
        }

    }
}

- (void)viewWillDisappear:(BOOL)animated {
    if (self.callbackWillBeDismissedBy != nil) {
        switch (self.presentationType) {
            case kVXControllerPresentationTypeNot:
                self.callbackWillBeDismissedBy((VXController *)self,nil);
                break;
            case kVXControllerPresentationTypeNavigationChild:
                self.callbackWillBeDismissedBy((VXController *)self,self.parentViewController);
                break;
            case kVXControllerPresentationTypeModally:
                self.callbackWillBeDismissedBy((VXController *)self,self.presentingViewController);
                break;
            case kVXControllerPresentationTypeOverlay:
                self.callbackWillBeDismissedBy((VXController *)self,self.parentViewController);
                break;
        }

    }
    if (animated) {
        self.visibilityState = kVXControllerVisibilityStateDisappearing;
    }
    [super viewWillDisappear:animated];

    if (self.presentationType == kVXControllerPresentationTypeModally) {
        self.presentationType = kVXControllerPresentationTypeNot;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    if (self.callbackWasDismissedBy != nil) {
        switch (self.presentationType) {
            case kVXControllerPresentationTypeNot:
                self.callbackWasDismissedBy((VXController *)self,nil);
                break;
            case kVXControllerPresentationTypeNavigationChild:
                self.callbackWasDismissedBy((VXController *)self,self.parentViewController);
                break;
            case kVXControllerPresentationTypeModally:
                self.callbackWasDismissedBy((VXController *)self,self.presentingViewController);
                break;
            case kVXControllerPresentationTypeOverlay:
                self.callbackWasDismissedBy((VXController *)self,self.parentViewController);
                break;
        }

    }
    self.visibilityState = kVXControllerVisibilityStateDisappeared;
    [super viewDidDisappear:animated];
}

#pragma mark UINavigationController

- (instancetype)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass {
    if ((self = [super initWithNavigationBarClass:navigationBarClass toolbarClass:toolbarClass]) != nil) {
        [self commonInit];
    }
    return self;
}

- (id)initWithRootViewController:(UIViewController *)rootViewController {
    if ((self = [super initWithRootViewController:rootViewController]) != nil) {
        [self commonInit];
    }
    return self;
}

#pragma mark - Protocols

#pragma mark VXController

- (void)setInfo:(NSDictionary *)info animated:(BOOL)animated {
    //nop
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

#pragma mark VX_HasOwner

- (id<VX_Requests>)owner {
    return _owner;
}

- (void)setOwner:(id<VX_Requests>)owner {
    _owner = owner;
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
    self.canBePresented = NO;
    self.presentationType = kVXControllerPresentationTypeNot;
    self.visibilityState = kVXControllerVisibilityStateNot;
    [self setNavigationBarHidden:YES];
}

#pragma mark VXController_Inner

- (void)presentOverlayControllerWithId:(NSString *)controllerId animated:(BOOL)animated {
    //nop
}

- (void)dismissOverlayControllerWithId:(NSString *)controllerId animated:(BOOL)animated {
    //nop
}

- (VXController *)dismissControllerWithId:(NSString *)controllerName
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
