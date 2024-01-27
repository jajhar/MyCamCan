//
//  BGControllerPostDetails.m
//  Blog
//
//  Created by James Ajhar on 11/9/15.
//  Copyright © 2015 James Ajhar. All rights reserved.
//

#import "BGControllerPostDetails.h"
#import "BGPostContentCell.h"
#import "Media.h"
#import "MediaPlayerViewController.h"
#import "BGViewFeedPost.h"

@interface BGControllerPostDetails () <UITableViewDelegate, UITableViewDataSource, BGViewFeedPostDelegate>

@property (strong, nonatomic) BGViewFeedPost *feedPostView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) Media *media;

@property (strong, nonatomic) FeedPager *feedPager;

@property (strong, nonatomic) MBProgressHUD *progressHUD;

@end


@implementation BGControllerPostDetails

- (void)viewDidLoad {
    [super viewDidLoad];
        
    if (self.configuration == BGPostDetailsConfigurationSinglePost) {
        [self setupForSinglePostViewing];
    } else {
        [self setupForExploreViewing];
    }
}

- (void)setupForExploreViewing {
    
    self.feedPager = [AppData sharedInstance].localUser.globalFeedPager;
    self.feedPager.filter = kBGFeedFilterGlobal;
    
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
    
    [self.navigationItem setTitle:@"Explore"];
}

- (void)setupForSinglePostViewing {
    
    self.title = self.media.caption;

    [self.tableView setHidden:YES];
    
    self.feedPostView = [[[NSBundle mainBundle] loadNibNamed:@"BGViewFeedPost"
                                                       owner:nil
                                                     options:nil] objectAtIndex:0];
    
    [self.feedPostView setMediaInfo:_media displayFeedView:NO showCompactHeader:NO];
    
    CGRect frame = self.feedPostView.frame;
    frame.size.width = self.view.frame.size.width;
    frame.size.height = 300.0;//[self.feedPostView heightOfViewWithMedia:_media showFeedDisplay:NO];
    self.feedPostView.frame = frame;
    self.feedPostView.center = self.view.center;
    [self.view addSubview:self.feedPostView];
    
    [self.feedPostView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant: 0.0].active = true;
    [self.feedPostView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant: 0.0].active = true;
    [self.feedPostView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant: 0.0].active = true;
    [self.feedPostView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant: 0.0].active = true;
    
    NSNotificationCenter *sharedNC = [NSNotificationCenter defaultCenter];
    [sharedNC addObserver:self
                 selector:@selector(notificationMediaUpdated:)
                     name:kAppData_Notification_MediaUpdated
                   object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    NSInteger scrollIndex = [self.feedPager indexOfElement:_media inFilter:kBGFeedFilterGlobal];
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:scrollIndex inSection:0]
                          atScrollPosition:UITableViewScrollPositionMiddle
                                  animated:NO];
}

- (void)setInfo:(NSDictionary *)info animated:(BOOL)animated {
    [super setInfo:info animated:animated];
    
    _media = [info objectForKey:kVXKeyMedia];
}

- (void)getFeedContentForceReload:(BOOL)forceReload {
    
    PagerCompletionBlock completionBlock = ^(NSError *error) {
        
    };
    
    if (forceReload) {
        [_feedPager reloadWithCompletion:completionBlock];
    } else {
        [_feedPager getNextPageWithCompletion:completionBlock];
    }
}

/**
 *<p>
 *  This method will be called via NSNotificationCenter whenever the list of feed media has changed in some way.
 *  It will add, remove, or refresh cells accordingly.
 */
- (void)notificationFeedChanged:(NSNotification *)notification {
    
    if([[notification.userInfo objectForKey:@"FeedFilter"] integerValue] != kBGFeedFilterGlobal) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.tableView reloadData];
    });
}


#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

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
        [cell setMediaInfo:[_feedPager mediaElementAtIndex:indexPath.row forFilter:kBGFeedFilterGlobal]];
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

- (void)notificationMediaUpdated:(NSNotification *)notification {
    if(_media.isDeleted) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
