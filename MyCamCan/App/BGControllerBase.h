
#import "BGController.h"
#import "BGViewBanner.h"

// warning: make decendant of BGControllerUser, update base controllers on user change


typedef NS_ENUM(NSUInteger, BGNavigationAnimationDirection) {
    kVXNavigationAnimationDirection_FromRight = 0,
    kVXNavigationAnimationDirection_FromLeft = 1
};

typedef void (^MCCBaseControllerBlock)();


extern NSString *kBGKeyImagePickerDelegate;


@protocol BGImagePickerDelegate <NSObject>

@required

- (void)imagePickerDidFinishPickingMedia:(NSArray *)media;

@end


@interface BGControllerBase : BGController<UIActionSheetDelegate>

//-- singleton
+ (BGControllerBase *)sharedInstance;

@property (nonatomic, assign) BGNavigationAnimationDirection pushAnimationDirection;
@property (nonatomic, copy) MCCBaseControllerBlock initialBlock;
@property (nonatomic, assign) id delegate;

- (void)executeBlock:(MCCBaseControllerBlock)block;
- (void)showBackButton:(BGViewBannerBackButtonCallback)callback animated:(BOOL)animated;
- (void)setHeaderTitle:(NSString *)title;
- (void)setHeaderColor:(UIColor *)color;
+ (UIViewController*) topMostController;

@end
