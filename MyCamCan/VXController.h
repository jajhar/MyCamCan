#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "VX_Requests.h"
#import "VX_HasOwner.h"
#import "VXController_Presentation.h"
#import "VXController_Callbacks.h"

//Collective protocol for any VXController to support
@protocol VXController <NSObject, VXController_Presentation, VXController_Callbacks, VX_Requests, VX_HasOwner>
@required

- (void)setInfo:(NSDictionary *)info animated:(BOOL)animated;
@optional
- (BOOL)hasInfoLike:(NSDictionary *)info;

@end

extern NSString *kVXKeyCapsule;
extern NSString *kVXKeyMedia;
extern NSString *kVXKeyUser;

//Template implementation of VXController protocol
//This class can be used or subclassed
@interface VXController : UIViewController<VXController>

@end
