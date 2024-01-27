@class VXController;

//Basic callback block type for VXController callbacks
//controllerAtAction is VXController calling back
//viewController parameter content may vary
typedef void (^VXControllerCallback)(VXController *controllerAtAction, UIViewController *viewController);

@protocol VXController_Callbacks <NSObject>
@required

//Called when VXController is about to be presented, viewController parameter contains presenting controller
@property (strong, nonatomic) VXControllerCallback callbackWillBePresentedBy;
//Called when VXController just was presented, viewController parameter contains presenting controller
@property (strong, nonatomic) VXControllerCallback callbackWasPresentedBy;
//Called when VXController is about to be dismissed, viewController parameter contains presenting controller
@property (strong, nonatomic) VXControllerCallback callbackWillBeDismissedBy;
//Called when VXController just was dismissed, viewController parameter contains presenting controller
@property (strong, nonatomic) VXControllerCallback callbackWasDismissedBy;

@end
