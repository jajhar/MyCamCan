#import "VX_Requests.h"

@class VXController;

//These constants define VXController's presentation type
typedef NS_ENUM(NSUInteger, VXControllerPresentationType) {
    kVXControllerPresentationTypeNot = 0,   //controller is not presented
    kVXControllerPresentationTypeNavigationChild,   //controller has navigation parent controller presenting it
    kVXControllerPresentationTypeModally,           //controller is presented modally
    kVXControllerPresentationTypeOverlay            //controller is presented is direct child controller and his view is setup as direct subview
};


//These constants define VXController view's visibility state
//Controller having one of visible states can still have its view hidden due to overlapping views or view setup
typedef NS_ENUM(NSUInteger, VXControllerVisibilityState) {
    kVXControllerVisibilityStateNot = 0,        //controller's view is not visible
    kVXControllerVisibilityStateAppearing,      //controller's view is appearing with animation
    kVXControllerVisibilityStateVisible,        //controller's view is visible
    kVXControllerVisibilityStateDisappearing,   //controller's view is disappearing with animation
    kVXControllerVisibilityStateDisappeared,    //controller's view was visible and has disappeared (it may appear again)
};

#define VXControllerIsVisible(__state) \
((__state != kVXControllerVisibilityStateNot) && (__state != kVXControllerVisibilityStateDisappeared))

#define VXControllerBecameVisible(__oldState, __newState) \
!VXControllerIsVisible(__oldState) && VXControllerIsVisible(__newState)

#define VXControllerBecameInvisible(__oldState, __newState) \
VXControllerIsVisible(__oldState) && !VXControllerIsVisible(__newState)

#define VXControllerIsAboutToBecomeInvisible(__oldState, __newState) \
( \
    ((__oldState == kVXControllerVisibilityStateAppearing) || (__oldState == kVXControllerVisibilityStateVisible)) && \
    ((__newState == kVXControllerVisibilityStateDisappearing) || (__newState == kVXControllerVisibilityStateDisappeared)) \
)

//Protocol for presentation interface of VXController
@protocol VXController_Presentation <NSObject>
@required

//This property reflects whether controller is set up and ready to be presented
//Controllers should not be presented and may be removed when its canBePresented property is NO
@property (assign, nonatomic) BOOL canBePresented;

//This tells VXController to present itself on navigation stack of given navigation controller
- (void)presentOnNavigationStack:(UINavigationController *)navigationController animated:(BOOL)animated;

//This tells VXController to present itself modally on given controller
- (void)presentModallyOnController:(UIViewController *)viewController animated:(BOOL)animated;

//This tells VXController to present itself on given controller by installing itself as direct child controller and its view as direct subview
- (void)presentAsOverlayOnController:(UIViewController *)viewController animated:(BOOL)animated;

//This tells controller to dismiss itself
- (void)dismissAnimated:(BOOL)animated;


//Presentation type of VXController
@property (assign, nonatomic, readonly) VXControllerPresentationType presentationType;

//Visibility state of VXController
@property (assign, nonatomic, readonly) VXControllerVisibilityState visibilityState;

//Allows VXController to dismiss itself when appropriate
@property (assign, nonatomic) BOOL autoDismissesSelf;

@end
