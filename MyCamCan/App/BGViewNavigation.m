//
//  BGViewNavigation.m
//  Blog
//
//  Created by James Ajhar on 12/1/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//

#import "BGViewNavigation.h"
#import "BGView_Inherit.h"

const CGFloat kBGViewHeaderHeight = 60;

@interface BGViewNavigation()
{
    UIColor *_defaultTintColor;
    BGNavigationBarOption _selectedNavigationOption;
}

@property (strong, nonatomic) IBOutlet UIView *bottomView;
@property (strong, nonatomic) IBOutlet UIButton *uploadButton;
@property (strong, nonatomic) IBOutlet UIButton *feedButton;
@property (strong, nonatomic) IBOutlet UIButton *searchButton;
@property (strong, nonatomic) IBOutlet UIButton *notificationsButton;
@property (strong, nonatomic) IBOutlet UIButton *profileButton;

@end

@implementation BGViewNavigation


#pragma mark - BGView


- (void)commonInit {
    [super commonInit];
    
    NSNotificationCenter *sharedNC = [NSNotificationCenter defaultCenter];
    [sharedNC addObserver:self
                 selector:@selector(userUpdated:)
                     name:kAppData_Notification_UserUpdated
                   object:nil];
    
    [self startNotificationPolling];
    
    _selectedNavigationOption = kNavigationOptionNone;
    
    self.uploadButton.layer.cornerRadius = CGRectGetWidth(self.uploadButton.frame) / 2.0;
    
    _defaultTintColor = [UIColor lightGrayColor];
    
    [self.feedButton setImage:[[UIImage imageNamed:@"tab-home"]
                               imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.searchButton setImage:[[UIImage imageNamed:@"tab-search"]
                                 imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.notificationsButton setImage:[[UIImage imageNamed:@"tab-notifications"]
                                        imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.profileButton setImage:[[UIImage imageNamed:@"tab-profile"]
                                  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
}

#pragma mark - Notifications

- (void)userUpdated:(NSNotification *)notification {
    if([[notification userInfo] objectForKey:kAppData_NotificationKey_User] == [AppData sharedInstance].localUser) {
        if([AppData sharedInstance].localUser.totalUnreadNotifications > 0) {
            [self.notificationsButton setSelected:YES];
        } else {
            [self.notificationsButton setSelected:NO];
        }
    }
}

#pragma mark - Actions


- (IBAction)feedPressed:(UIButton *)button {
    [[BGControllerBase sharedInstance] presentControllerForPurpose:kBGPurposeFeed
                                                          animated:YES
                                                         fromRight:NO
                                                              info:nil];
}

- (IBAction)cameraPressed:(id)sender {
    [[BGControllerBase sharedInstance] presentControllerForPurpose:kBGPurposeMusicPicker
                                                          animated:YES
                                                         fromRight:YES
                                                              info:nil];

}

- (IBAction)profilePressed:(id)sender {
    
    BOOL fromRight = _selectedNavigationOption == kNavigationOptionHome ||
    _selectedNavigationOption == kNavigationOptionSearch ||
    _selectedNavigationOption == kNavigationOptionNotifications;
    
    [[BGControllerBase sharedInstance] presentControllerForPurpose:kBGPurposeProfile
                                                          animated:YES
                                                         fromRight:fromRight
                                                              info:@{kVXKeyUser: [AppData sharedInstance].localUser}];
}

- (IBAction)notificationsPressed:(id)sender {
    
    BOOL fromRight = _selectedNavigationOption == kNavigationOptionHome ||
                    _selectedNavigationOption == kNavigationOptionSearch;

    [[BGControllerBase sharedInstance] presentControllerForPurpose:kBGPurposeNotifications
                                                          animated:YES
                                                         fromRight:fromRight
                                                              info:nil];
}

- (IBAction)searchPressed:(id)sender {
    
    BOOL fromRight = _selectedNavigationOption == kNavigationOptionHome;
    
    [[BGControllerBase sharedInstance] presentControllerForPurpose:kBGPurposeSearch
                                                          animated:YES
                                                         fromRight:fromRight
                                                              info:nil];
}

- (void)setSelectedNavigationOption:(BGNavigationBarOption)option {
    
    _selectedNavigationOption = option;
    
    switch (option) {
        case kNavigationOptionHome:
            [self.feedButton setTintColor:[UIColor orangeColor]];
            [self.notificationsButton setTintColor:_defaultTintColor];
            [self.searchButton setTintColor:_defaultTintColor];
            [self.profileButton setTintColor:_defaultTintColor];
            break;
        case kNavigationOptionNotifications:
            [self.feedButton setTintColor:_defaultTintColor];
            [self.notificationsButton setTintColor:[UIColor orangeColor]];
            [self.searchButton setTintColor:_defaultTintColor];
            [self.profileButton setTintColor:_defaultTintColor];
            break;
        case kNavigationOptionProfile:
            [self.feedButton setTintColor:_defaultTintColor];
            [self.notificationsButton setTintColor:_defaultTintColor];
            [self.searchButton setTintColor:_defaultTintColor];
            [self.profileButton setTintColor:[UIColor orangeColor]];
            break;
        case kNavigationOptionSearch:
            [self.feedButton setTintColor:_defaultTintColor];
            [self.notificationsButton setTintColor:_defaultTintColor];
            [self.searchButton setTintColor:[UIColor orangeColor]];
            [self.profileButton setTintColor:_defaultTintColor];
            break;
        case kNavigationOptionNone:
            [self.feedButton setTintColor:_defaultTintColor];
            [self.notificationsButton setTintColor:_defaultTintColor];
            [self.searchButton setTintColor:_defaultTintColor];
            [self.profileButton setTintColor:_defaultTintColor];
            break;
        default:
            break;
    }
}

#pragma mark Hit Test
/**
 * Returns the farthest descendant of the receiver in the view hierarchy (including itself) that contains a specified point
 */
-(id)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    id hitView = [super hitTest:point withEvent:event];
    
    if (hitView == self.bottomView || point.y >= self.bottomView.frame.origin.y || hitView == self.uploadButton) {
        return hitView;
    } else {
        return nil;
    }
}


- (void)removeFromSuperview {
    
    [self stopNotificationPolling];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super removeFromSuperview];
}

/**
 *This method helps to pull all notifications received by the user.
 */

- (void)startNotificationPolling {
    
    __block BGViewNavigation *blockSelf = self;
    
    [[AppData sharedInstance] startNotificationsPollingWithCallback:^(id result, NSError *error) {
        if ((error == nil) && (result != nil)){
            if([AppData sharedInstance].localUser.totalUnreadNotifications > 0) {
                [blockSelf.notificationsButton setSelected:YES];
            } else {
                [blockSelf.notificationsButton setSelected:NO];
            }
        }
    }];
}

/**
 *This method stops pulling notification when user navigates away from the notification page.
 */

- (void)stopNotificationPolling {
    [[AppData sharedInstance] stopNotificationsPolling];
}

@end
