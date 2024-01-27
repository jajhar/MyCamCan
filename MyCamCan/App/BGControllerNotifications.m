//
//  BGControllerNotifications.m
//  Blog
//
//  Created by James Ajhar on 9/4/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGControllerNotifications.h"
#import "NotificationPager.h"
#import "MBProgressHUD.h"
#import "BGViewCellNotification.h"
#import "Notification.h"
#import "BGControllerPostDetails.h"

NSString *kBGControllerNotifications = @"BGControllerNotifications";

@interface BGControllerNotifications () <UITableViewDataSource, UITableViewDelegate>

// Interface
@property (strong, nonatomic) IBOutlet UITableView *tableView;

// Data
@property (strong, nonatomic) NotificationPager *notificationPager;
@property (strong, nonatomic) MBProgressHUD *progressHUD;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIView *emptyView;
@property (weak, nonatomic) IBOutlet UIImageView *downArrowImageView;

@end

@implementation BGControllerNotifications

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.notificationPager = [AppData sharedInstance].localUser.notificationPager;

    NSNotificationCenter *sharedNC = [NSNotificationCenter defaultCenter];
    [sharedNC addObserver:self
                 selector:@selector(notificationNotificationsListChanged:)
                     name:kAppData_Notification_Pager_Notifications
                   object:nil];
    
    // refresh control
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshView:) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl setTintColor:[UIColor whiteColor]];
    tableViewController.refreshControl = self.refreshControl;
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 100, 0);

    self.refreshButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.refreshButton.layer.borderWidth = 1.0f;
    
    [self.downArrowImageView setImage:[[UIImage imageNamed:@"drawn-arrow-down-rev"]
                                       imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.downArrowImageView setTintColor:[UIColor whiteColor]];
    
    self.navigationItem.title = @"Notifications";
    
    [self.tableView reloadData];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    if(_notificationPager.elementsCount == 0 && _notificationPager.isEndOfPages) {
        self.emptyView.hidden = NO;
    } else {
        self.emptyView.hidden = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[AppData sharedInstance].navigationManager resetNotificationBadge];
}

#pragma mark Notifications


/**
 *<p>
 *  This method will be called via NSNotificationCenter whenever the list of notifications has changed in some way.
 *  It will add, remove, or refresh cells accordingly.
 */
- (void)notificationNotificationsListChanged:(NSNotification *)notification {
    /**
     kMCCData_Notification_Pager_Feed
     */
    // feed is only one - no need to check
    // type of change
    
    dispatch_async(dispatch_get_main_queue(), ^{

        if(_notificationPager.elementsCount == 0 && [_notificationPager isEndOfPages]) {
            self.emptyView.hidden = NO;
        }
            
        [self.tableView reloadData];
    });
}


#pragma mark - Interface Actions


- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)refreshButtonPressed:(id)sender {
    [self getNotificationsForceReload:YES];
}

/**
 * callback of the refresh control
 */
- (void)refreshView:(UIRefreshControl *)refresh {
    [self getNotificationsForceReload:YES];
}

- (void)getNotificationsForceReload:(BOOL)forceReload {
    PagerCompletionBlock completionBlock = ^(NSError *error) {
        // hide all spinners
        [self.refreshControl endRefreshing];
        
    };
    
    if (forceReload) {
        [_notificationPager reloadWithCompletion:completionBlock];
    } else {
        [_notificationPager getNextPageWithCompletion:completionBlock];
    }
}

#pragma mark - UITableViewDelegate/Datasource


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 75.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if([_notificationPager isEndOfPages]) {
        return [_notificationPager elementsCount];
    } else {
        return [_notificationPager elementsCount] + 1;  // last cell - refreshing spinner. When scrolled to, it will trigger a fetch of the next page
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [_notificationPager elementsCount]) {
        // refresh cell
        UITableViewCell *cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:@"TableLoadingCell"];
        
        // MBProgressHUD
        [_progressHUD removeFromSuperview];
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        _progressHUD.color = [UIColor clearColor];
        _progressHUD.activityIndicatorColor = [UIColor whiteColor];
        _progressHUD.opacity = 1.0f;
        [cell.contentView addSubview:_progressHUD];
        [_progressHUD show:YES];
        
        // when this cell gets shown to user, we start loading new portion of feed data
        [self getNotificationsForceReload:NO];
        
        return cell;
    } else {
        // feed cell
        BGViewCellNotification *cell = [tableView dequeueReusableCellWithIdentifier:@"NotificationCell"];
        [cell setupWithNotification:[_notificationPager elementAtIndex:indexPath.row]];
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row >= [_notificationPager elementsCount]) {
        // loading cell, do nothing
        return;
    }

    Notification *notification = [self.notificationPager elementAtIndex:indexPath.row];
    
    switch (notification.type) {
        case kNotificationTypeLikedMedia:
        {
            if(notification.media != nil) {
                
                BGControllerPostDetails *vc = (BGControllerPostDetails *)[[AppData sharedInstance].navigationManager
                                                                          presentControllerForPurpose:kBGPurposePostDetails
                                                                          info:@{kVXKeyMedia: notification.media}
                                                                          showTabBar:YES
                                                                          pushImmediately:NO];
                
                vc.configuration = BGPostDetailsConfigurationSinglePost;
                
                [self.navigationController pushViewController:vc animated:YES];

            } else {
                NSLog(@"Error: Notification %@ media object is nil", notification.theId);
            }

            break;
        }
        case kNotificationTypeFriendJoined:
            
            [[AppData sharedInstance].navigationManager presentControllerForPurpose:kBGPurposeProfile info:@{kVXKeyUser: notification.fromUser} showTabBar:YES];
            break;
            
        case kNotificationTypeWasFollowed:
            [[AppData sharedInstance].navigationManager presentControllerForPurpose:kBGPurposeProfile info:@{kVXKeyUser: notification.fromUser} showTabBar:YES];
            break;
        default:
            break;
    }
}

@end
