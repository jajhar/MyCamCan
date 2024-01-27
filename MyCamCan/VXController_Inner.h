#import "VXController.h"

typedef NS_ENUM(NSUInteger, VXControllerDismissType) {
    kVXControllerDismissTypeToController,
    kVXControllerDismissTypeToControllerBehind,
    kVXControllerDismissTypeControllerOnly
};

@protocol VXController_Inner <VXController>

@required

- (void)presentOverlayControllerWithId:(NSString *)controllerId animated:(BOOL)animated;
- (void)dismissOverlayControllerWithId:(NSString *)controllerId animated:(BOOL)animated;

//will return last controller with given name and info alike or nil, regardless of whether animation took place
- (VXController *)dismissControllerWithId:(NSString *)controllerName
                             withInfoLike:(NSDictionary *)infoLike
                              dismissType:(VXControllerDismissType)dismissType
                     dismissAllIfNotFound:(BOOL)dismissAll
                          animatedIfFound:(BOOL)animatedIfFound
                       animatedIfNotFound:(BOOL)animatedIfNotFound;

@end

@interface VXController () <VXController_Inner>

@end
