#import <UIKit/UIKit.h>
#import "VX_HasOwner.h"

@protocol VXView <VX_HasOwner>

@required

@end

@interface VXView : UIView<VXView>

@end
