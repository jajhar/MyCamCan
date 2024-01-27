//
//  BGControllerUsers.m
//  Blog
//
//  Created by James Ajhar on 12/2/15.
//  Copyright © 2015 James Ajhar. All rights reserved.
//

#import "BGControllerUsers.h"
#import "FollowersPager.h"
#import "FolloweesPager.h"
#import "MBProgressHUD.h"
#import "BGViewCellUser.h"
#import "UIView+Gradient.h"

NSString *kBGKeyUsersFilter = @"BGKeyUsersFilter";

@interface BGControllerUsers () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *gradientView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;

@property (assign, nonatomic) BGControllerUsersFilterType filterType;
@property (strong, nonatomic) Pager *pager;
@property (strong, nonatomic) User *user;
@property (strong, nonatomic) MBProgressHUD *progressHUD;
@property (strong, nonatomic) UIRefreshControl *refreshControl;

@end

@implementation BGControllerUsers

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"BGViewCellUser" bundle:nil] forCellReuseIdentifier:@"UserCell"];

    //--interface
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlCallback:) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl setTintColor:[UIColor whiteColor]];
    tableViewController.refreshControl = self.refreshControl;

    // Notifications
    NSNotificationCenter *sharedNC = [NSNotificationCenter defaultCenter];
    
    if ([self.pager isKindOfClass:[FolloweesPager class]]) {
        [sharedNC addObserver:self
                     selector:@selector(pagerListChanged:)
                         name:kAppData_Notification_Pager_Following
                       object:nil];
        
        self.titleLabel.text = @"friends";
        
        self.backgroundView.backgroundColor = [UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1.0];
        [UIView addLinearGradientToView:self.gradientView withColor:self.backgroundView.backgroundColor transparentToOpaque:NO];

    } else if ([self.pager isKindOfClass:[FollowersPager class]]) {
        [sharedNC addObserver:self
                     selector:@selector(pagerListChanged:)
                         name:kAppData_Notification_Pager_Followers
                       object:nil];
        
        self.titleLabel.text = @"followers";
        
        self.backgroundView.backgroundColor = [UIColor colorWithRed:70.0/255.0 green:70.0/255.0 blue:70.0/255.0 alpha:1.0];
        [UIView addLinearGradientToView:self.gradientView withColor:self.backgroundView.backgroundColor transparentToOpaque:NO];

    }
    
    [self.pager reloadWithCompletion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];

//    if ([self.pager isKindOfClass:[FolloweesPager class]]) {
//        [[BGControllerBase sharedInstance] setHeaderTitle:@"Following"];
//    } else if ([self.pager isKindOfClass:[FollowersPager class]]) {
//        [[BGControllerBase sharedInstance] setHeaderTitle:@"Followers"];
//
//    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 * callback from refresh control
 */
- (void)refreshControlCallback:(UIRefreshControl *)refresh {
    [self.pager clearStateAndElements];
    [self reloadTableDataSource:YES];
}

#pragma mark - Interface Actions

- (IBAction)backButtonPressed:(id)sender {
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [self.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

/**
 *<p>
 *  This method will be called via NSNotificationCenter.
 *  It will add, remove, or refresh cells accordingly.
 */
- (void)pagerListChanged:(NSNotification *)notification {
    /**
     kMCCData_Notification_Pager_Followers
     */
    User *user = notification.userInfo[kAppData_NotificationKey_User];
    
    if (user == nil || ![DataModelObject modelObject:user isEqualTo:self.user]) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark BGController
/**
 *<p>
 *  This method overrides the setInfo method of BGController. It will setup the media,capsule, filtertype based on the
 *  information given.
 */
- (void)setInfo:(NSDictionary *)info animated:(BOOL)animated {
    [super setInfo:info animated:animated];
    
    User *user = [info objectForKey:kVXKeyUser];
    if (user != nil) {
        self.user = user;
    } else
    {
        NSLog(@"Warning: user info not available");
    }
    
    NSNumber *filterType = [info objectForKey:kBGKeyUsersFilter];
    self.filterType = [filterType unsignedIntegerValue];
    
    
    switch (self.filterType) {
        case kBGControllerUsersFilterTypeFollowers:
            self.pager = self.user.followersPager;
            break;
        
        case kBGControllerUsersFilterTypeFollowees:
            self.pager = self.user.followeesPager;
            break;
            
        default:
            break;
    }
}

/**
 * This method will be called to reload table
 */
- (void)reloadTableDataSource:(BOOL)forceReload {
    // completion block
    PagerCompletionBlock completionBlock = ^(NSError *error) {
        // hide spinner
        [self.refreshControl endRefreshing];
    };
    
    if (forceReload) {
        [self.pager reloadWithCompletion:completionBlock];
    } else {
        [self.pager getNextPageWithCompletion:completionBlock];
    }
}


#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger count = [_pager elementsCount];
    
    if(![_pager isEndOfPages]) {
        count++;
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [_pager elementsCount]) {
        // refreshed cell
        UITableViewCell *cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:@"kRefresherCell"];
        
        // MBProgressHUD
        [_progressHUD removeFromSuperview];
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        _progressHUD.color = [UIColor clearColor];
        _progressHUD.activityIndicatorColor = [UIColor whiteColor];
        _progressHUD.opacity = 1.0;
        [cell.contentView addSubview:_progressHUD];
        [_progressHUD show:YES];
        
        cell.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor clearColor];
        
        // get new data
        [self reloadTableDataSource:NO];
        
        return cell;
        
    } else {
        BGViewCellUser *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell"];
        
        [cell setupWithUser:(User *)[self.pager elementAtIndex:indexPath.row]];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [_pager elementsCount]) {
        // refreshing cell
        return 75.0;
    }
    
    return 75.0;
}

@end
