#import "VXView.h"

@class VXViewHeader;
@class VXViewBanner;

@interface VXViewBase : VXView

@property (strong, nonatomic, readonly) VXViewHeader *headerView;
@property (strong, nonatomic, readonly) UIView *navigationView;
@property (strong, nonatomic, readonly) VXViewBanner *bannerView;

- (id)initWithHeaderView:(VXViewHeader *)headerView
          navigationView:(UIView *)navigationView
              bannerView:(VXViewBanner *)bannerView;

- (void)fullscreenNavigation:(BOOL)fullscreen animated:(BOOL)aniamted;

@end
