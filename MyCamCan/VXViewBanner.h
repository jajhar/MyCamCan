#import "VXView.h"
#import "VXViewHeader_Owner.h"

extern const CGFloat kVXViewBannerHeight;

@interface VXViewBanner : VXView

- (void)setTitle:(NSString *)title;

- (void)setSelectedNavItemForOption:(VXViewHeaderOption)option;

@end
