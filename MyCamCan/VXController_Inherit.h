#import "VXController.h"

@protocol VXController_Inherit <VXController>

- (void)commonInit;

@property (assign, nonatomic) BOOL canBePresented;
@property (assign, nonatomic) VXControllerPresentationType presentationType;
@property (assign, nonatomic) VXControllerVisibilityState visibilityState;

@end

@interface VXController () <VXController_Inherit>

@end
