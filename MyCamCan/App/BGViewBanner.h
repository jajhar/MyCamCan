#import "BGView.h"

extern const CGFloat kBGViewBannerHeight;

typedef void (^BGViewBannerBackButtonCallback)(void);

@interface BGViewBanner : BGView

- (void)setTitle:(NSString *)title;
- (void)setColor:(UIColor *)color;

- (void)showBackButton:(BGViewBannerBackButtonCallback)callback animated:(BOOL)animated;
- (void)hideBackButtonAnimated:(BOOL)animated;

@end
