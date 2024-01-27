#import "BGView.h"

@class BGViewNavigation;
@class BGViewBanner;

@interface BGViewBase : BGView

@property (strong, nonatomic, readonly) BGViewNavigation *headerView;
@property (strong, nonatomic, readonly) UIView *BGViewNavigation;

- (id)initWithHeaderView:(BGViewNavigation *)headerView
              bannerView:(BGViewBanner *)bannerView
          navigationView:(UIView *)navigationView;

- (void)fullscreenNavigation:(BOOL)fullscreen animated:(BOOL)aniamted;

- (void)hideHeaderView;
- (void)showHeaderView;

@end
