#import <UIKit/UIKit.h>

@protocol WindowHitTestDelegate <NSObject>

@required
- (UIView *)windowHitTestShouldReturnView:(UIView *)view;

@end

extern NSString *kBGNotificationWindowTapped;

@interface WindowHitTest : UIWindow

@property (weak, nonatomic) id<WindowHitTestDelegate> hitTestDelegate;

@end
