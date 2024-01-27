//
//  FeedViewController.m
//  Blog
//
//  Created by James Ajhar on 5/29/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//

#import "BGControllerFeed.h"
#import "BGControllerProfile.h"
#import "FeedPager.h"
#import "BGPostContentCell.h"
#import "MBProgressHUD.h"
#import "BGViewFeedPost.h"
#import "MediaPlayerViewController.h"

NSString *kBGControllerFeed = @"BGControllerFeed";

//CGFloat _lastFeedScrollOffsetY = 0;

@interface BGControllerFeed () <BGViewFeedPostDelegate>
{
    AppData *_appData;
    User *_localUser;
    FeedPager *_feedPager;
    
    BOOL _reloadTableOnAppear;
    BOOL _refreshTableOnAppear;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) MBProgressHUD *progressHUD;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (weak, nonatomic) IBOutlet UIView *emptyView;
@property (weak, nonatomic) IBOutlet UIImageView *downArrowImageView;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;

- (BOOL)isVisible;

@end

@implementation BGControllerFeed


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _appData = [AppData sharedInstance];
    
    NSNotificationCenter *sharedNC = [NSNotificationCenter defaultCenter];
    [sharedNC addObserver:self
                 selector:@selector(notificationFeedChanged:)
                     name:kAppData_Notification_FeedChanged
                   object:nil];
    
    UINib *nib = [UINib nibWithNibName:@"BGPostContentCell"
                                bundle:nil];
    // Register this Nib, which contains the cell
    [self.tableView registerNib:nib
         forCellReuseIdentifier:@"BGPostContentCell"];
        
    self.refreshButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.refreshButton.layer.borderWidth = 1.0f;
    
    [self.downArrowImageView setImage:[[UIImage imageNamed:@"drawn-arrow-down"]
                               imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.downArrowImageView setTintColor:[UIColor whiteColor]];

    // refresh control
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshView:) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl setTintColor:[UIColor whiteColor]];
    tableViewController.refreshControl = self.refreshControl;
    
    _feedPager = [AppData sharedInstance].localUser.feedPager;
    
    self.tableView.contentInset = UIEdgeInsetsMake(10, 0, 10, 0);
    
//    UIImage *img = [UIImage imageNamed:@"MyCamCan_Header"];
//    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 150, 50)];
//    [imgView setImage:img];
//    [imgView setContentMode:UIViewContentModeCenter];
//    self.navigationItem.titleView = imgView;
    [self.navigationItem setTitle:@"#MyCamCan"];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];

    _feedPager.filter = kBGFeedFilterDefault;
    
//    self.tableView.contentOffset = CGPointMake(0, _lastFeedScrollOffsetY);
    
    if(_feedPager.elementsCount == 0 && _feedPager.isEndOfPages) {
        self.emptyView.hidden = NO;
    } else {
        self.emptyView.hidden = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
//    _lastFeedScrollOffsetY = self.tableView.contentOffset.y;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

}

- (IBAction)refreshButtonPressed:(id)sender {
    [self getFeedContentForceReload:YES];
}

#pragma mark Notifications


/**
 *<p>
 *  This method will be called via NSNotificationCenter whenever the list of feed media has changed in some way.
 *  It will add, remove, or refresh cells accordingly.
 */
- (void)notificationFeedChanged:(NSNotification *)notification {
    
    if([[notification.userInfo objectForKey:@"FeedFilter"] integerValue] != kBGFeedFilterDefault) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{

        if(_feedPager.elementsCount == 0 && [_feedPager isEndOfPages]) {
            self.emptyView.hidden = NO;
        } else {
            self.emptyView.hidden = YES;
        }
        
        [self.tableView reloadData];
    });
}


#pragma mark - Internal

- (BOOL)isVisible {
    return [self isViewLoaded] && self.view.window;
}

- (void)updateTableOnAppear {
    [self.tableView reloadData];
}


- (void)resetFeed {
    [_feedPager clearStateAndElements];
    [self.tableView reloadData];
    self.emptyView.hidden = YES;

}

/**
 * callback of the refresh control
 */
- (void)refreshView:(UIRefreshControl *)refresh {
    [self getFeedContentForceReload:YES];
}

- (void)getFeedContentForceReload:(BOOL)forceReload {
    PagerCompletionBlock completionBlock = ^(NSError *error) {
        // hide all spinners
        [self.refreshControl endRefreshing];
        
    };

    if (forceReload) {
        [_feedPager reloadWithCompletion:completionBlock];
    } else {
        [_feedPager getNextPageWithCompletion:completionBlock];
    }
}


#pragma mark - UITableViewDataSource, UITableViewDelegate


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_feedPager.isEndOfPages) {
        return [_feedPager elementsCount];
    } else {
        return [_feedPager elementsCount] + 1;  // last cell - refreshing spinner. When scrolled to, it will trigger a fetch of the next page
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [_feedPager elementsCount]) {
        // refreshing cell
        return 75.0;
    }

    return 320.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [_feedPager elementsCount]) {
        // refresh cell
        UITableViewCell *cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:@"TableLoadingCell"];
        
        // MBProgressHUD
        [_progressHUD removeFromSuperview];
        _progressHUD = [[MBProgressHUD alloc] init];
        _progressHUD.color = [UIColor clearColor];
        _progressHUD.activityIndicatorColor = [UIColor whiteColor];
        _progressHUD.opacity = 1.0f;
        [cell.contentView addSubview:_progressHUD];
        [_progressHUD show:YES];
        
        // when this cell gets shown to user, we start loading new portion of feed data
        [self getFeedContentForceReload:NO];
        
        return cell;
    } else {
        // feed cell
        BGPostContentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BGPostContentCell"];
        cell.feedView.delegate = self;
        [cell setMediaInfo:[_feedPager mediaElementAtIndex:indexPath.row forFilter:kBGFeedFilterDefault]];
        return cell;
    }
}

- (void)feedView:(id)view mediaItemTapped:(Media *)media {
    
    UINib *mediaPlayerNib = [UINib nibWithNibName:@"MediaPlayerViewController" bundle:nil];
    MediaPlayerViewController *mediaPlayerController = [mediaPlayerNib instantiateWithOwner:self options:nil].firstObject;

    [mediaPlayerController setModalPresentationStyle:UIModalPresentationCustom];
    [mediaPlayerController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];

    [mediaPlayerController setMediaInfo:media];
    [self presentViewController:mediaPlayerController animated:YES completion:nil];
}

@end
