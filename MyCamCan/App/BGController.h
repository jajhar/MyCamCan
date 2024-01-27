#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


//Collective protocol for any BGController to support
@protocol BGController <NSObject>
@required

- (void)setInfo:(NSDictionary *)info animated:(BOOL)animated;
@optional
- (BOOL)hasInfoLike:(NSDictionary *)info;

@end

//Template implementation of BGController protocol
//This class can be used or subclassed
@interface BGController : UIViewController<BGController>

@property (strong, nonatomic, readonly) NSDictionary *info;

@end
