#import "VXViewBanner.h"
#import "VXView_Inherit.h"
#import "VXStyle.h"

@interface VXViewBanner ()

//L1

@property (strong, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) IBOutlet UIButton *notificationsButton;
@property (strong, nonatomic) IBOutlet UIButton *searchButton;
@property (strong, nonatomic) IBOutlet UILabel *notificationsCountLabel;

@end

const CGFloat kVXViewBannerHeight = 25;

@implementation VXViewBanner


#pragma mark L0

- (void)setTitle:(NSString *)title {
    [self.label setText:title];
    [self setBackgroundColor:[[VXStyle sharedInstance] colorWithName:kVXStyle_Color_Banner]];
}

- (IBAction)notificationsPressed:(id)sender {
    VXController *controller = [self.owner presentControllerForPurpose:kVXPurposeNotifications
                                                              animated:YES
                                                             fromRight:YES
                                                                  info:nil];
    if (controller != nil) {
        [self setSelectedNavItemForOption:kVXViewHeaderOptionNotifications];
    }
}

- (IBAction)searchPressed:(id)sender {
    VXController *controller = [self.owner presentControllerForPurpose:kVXPurposeSearch
                                                              animated:YES
                                                             fromRight:YES
                                                                  info:nil];
    if (controller != nil) {
        [self setSelectedNavItemForOption:kVXViewHeaderOptionSearch];
    }
}

- (void)setSelectedNavItemForOption:(VXViewHeaderOption)option {
    switch (option) {
        case kVXViewHeaderOptionFeed:
        case kVXViewHeaderOptionCapsules:
        case kVXViewHeaderOptionNone:
            [self.notificationsButton setSelected:NO];
            [self.searchButton setSelected:NO];
            break;
        case kVXViewHeaderOptionNotifications:
            [self.notificationsButton setSelected:YES];
            [self.searchButton setSelected:NO];
            break;
        case kVXViewHeaderOptionSearch:
            [self.notificationsButton setSelected:NO];
            [self.searchButton setSelected:YES];
            break;
        default:
            DDLogError(@"[VXViewBanner] - Unknown VXViewHeaderOption");
            break;
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    
    if ((self.superview == nil) && (newSuperview != nil)) {
        [self startNotificationPolling];
    }
    if ((newSuperview == nil) && (self.superview != nil)) {
        [self stopNotificationPolling];
    }
}

#pragma mark L1

@synthesize label = _label;

- (void)startNotificationPolling {
    [[VixletData sharedInstance] startNotificationsPollingWithCallback:^(id result, NSError *error) {
        if ((error == nil) && (result != nil)){
            if([[result objectForKey:@"count"] intValue] > 0) {
                [self.notificationsButton setImage:[VXResources imageNamed:@"nav_messages_notification"] forState:UIControlStateNormal];
            }else{
                [self.notificationsButton setImage:[VXResources imageNamed:@"header_messages"] forState:UIControlStateNormal];
            }
            self.notificationsCountLabel.text = [NSString stringWithFormat:@"%d", [[result objectForKey:@"count"] intValue]];
        }
    }];
}

- (void)stopNotificationPolling {
    [[VixletData sharedInstance] stopNotificationsPolling];
}

@end
