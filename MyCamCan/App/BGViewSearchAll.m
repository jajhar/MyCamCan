//
//  BGViewSearchAll.m
//  Blog
//
//  Created by James Ajhar on 11/9/15.
//  Copyright © 2015 James Ajhar. All rights reserved.
//

#import "BGViewSearchAll.h"

#import "SearchPager.h"
#import "MBProgressHUD.h"
#import "BGViewCellUser.h"
#import "WindowHitTest.h"
#import "FeedPager.h"
#import "BGViewCellLoader.h"
#import "BGViewCVItemMedia.h"
#import "CollectionLoadingCell.h"
#import "ILRemoteSearchBar.h"
#import "BGViewSearchCollectionCellHeader.h"
#import "BGControllerPostDetails.h"

@interface BGViewSearchAll () <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, ILRemoteSearchBarDelegate>

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) MBProgressHUD *progressHUD;
@property (strong, nonatomic) SearchPager *searchPager;
@property (strong, nonatomic) FeedPager *feedPager;
@property (strong, nonatomic) id activePager;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) UIRefreshControl *refreshControl2;

@property (strong, nonatomic) UIRefreshControl *refreshControl;

@end


@implementation BGViewSearchAll

- (void)commonInit {
    [super commonInit];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    [self.tableView registerNib:[UINib nibWithNibName:@"BGViewCellUser" bundle:nil] forCellReuseIdentifier:@"UserCell"];
    [self.tableView registerClass:[BGViewCellLoader class] forCellReuseIdentifier:@"LoadingCell"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"BGViewCVItemMedia" bundle:nil] forCellWithReuseIdentifier:@"BGViewCVItemMedia"];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"BGViewSearchCollectionCellHeader" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"SectionHeader"];
    [self.collectionView registerClass:[CollectionLoadingCell class] forCellWithReuseIdentifier:@"LoadingCell"];
     
    self.searchPager = [SearchPager new];
    self.searchPager.filter = kBGSearchFilterAll;
    self.feedPager = [AppData sharedInstance].localUser.globalFeedPager;
    self.feedPager.filter = kBGFeedFilterGlobal;
    self.searchBar.delegate = self;
    
    self.tableView.scrollsToTop = NO;
    
    self.activePager = self.feedPager;
     
    // Notifications
    NSNotificationCenter *sharedNC = [NSNotificationCenter defaultCenter];
    [sharedNC addObserver:self
                 selector:@selector(notificationSearchResultsChanged:)
                     name:kAppData_Notification_Pager_Search
                   object:nil];
    
    [sharedNC addObserver:self
                 selector:@selector(notificationWindowHitTest:)
                     name:kBGNotificationWindowTapped
                   object:nil];
    
    [sharedNC addObserver:self
                 selector:@selector(notificationFeedChanged:)
                     name:kAppData_Notification_FeedChanged
                   object:nil];
    
    // refresh control
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshView:) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl setTintColor:[UIColor whiteColor]];
    tableViewController.refreshControl = self.refreshControl;
    
    self.refreshControl2 = [[UIRefreshControl alloc] init];
    [self.refreshControl2 addTarget:self action:@selector(refreshView:) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl2];
    [self.refreshControl2 setTintColor:[UIColor whiteColor]];
    [self.collectionView sendSubviewToBack:self.refreshControl2];
    
    [self.searchBar resignFirstResponder];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    /*
    self.tableView.contentInset = UIEdgeInsetsMake([[AppData sharedInstance].navigationManager.selectedViewController navigationBar].frame.size.height + 20.0,0,50,0);
    self.collectionView.contentInset = UIEdgeInsetsMake([[AppData sharedInstance].navigationManager.selectedViewController navigationBar].frame.size.height + 20.0,0,50,0);
     */
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showGlobalFeed {
    self.activePager = self.feedPager;
}

- (void)showUserSearch {
    self.activePager = self.searchPager;
}

- (void)searchForContentWithKeyword:(NSString *)keyword {
    if(keyword.length > 0 && ![keyword isEqualToString:_searchPager.keyword]) {
        [self.searchPager clearStateAndElements];
        [self.tableView reloadData];
        
        self.searchPager.keyword = keyword;
        self.activePager = self.searchPager;
        self.collectionView.hidden = YES;
        
        [self reloadContentForceReload:YES];
        
    } else if(keyword.length == 0) {
        self.collectionView.hidden = NO;
        self.activePager = self.feedPager;
        _searchPager.keyword = @"";
    }
}

- (void)reloadContentForceReload:(BOOL)forceReload {
    
    if(self.activePager == self.searchPager) {
        [MBProgressHUD showHUDAddedTo:self animated:YES];
    }
    
    PagerCompletionBlock completionBlock = ^(NSError *error) {
        // hide all spinners
        [self.refreshControl endRefreshing];
        [self.refreshControl2 endRefreshing];
        [MBProgressHUD hideAllHUDsForView:self animated:NO];

    };
    
    if (forceReload) {
        [self.activePager reloadWithCompletion:completionBlock];
    } else {
        [self.activePager getNextPageWithCompletion:completionBlock];
    }
}

/**
 * callback of the refresh control
 */
- (void)refreshView:(UIRefreshControl *)refresh {
    [self reloadContentForceReload:YES];
}

#pragma mark Notifications


- (void)notificationWindowHitTest:(NSNotification *)notification {
    UIView *touchedView = [notification object];
    
    if ([self.searchBar isFirstResponder] && touchedView != self.searchBar) {
        [self.searchBar resignFirstResponder];
    }
}


#pragma mark Notifications


/**
 *<p>
 *  This method will be called via NSNotificationCenter whenever the list of feed media has changed in some way.
 *  It will add, remove, or refresh cells accordingly.
 */
- (void)notificationFeedChanged:(NSNotification *)notification {
    
    if(_feedPager.filter != kBGFeedFilterGlobal || [[notification.userInfo objectForKey:@"FeedFilter"] integerValue] != kBGFeedFilterGlobal) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
    });
}

/**
 *<p>
 *  This method will be called via NSNotificationCenter whenever the list of feed media has changed in some way.
 *  It will add, remove, or refresh cells accordingly.
 */
- (void)notificationSearchResultsChanged:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - UITableViewDataSource, UITableViewDelegate


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchPager.elementsCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [_feedPager elementsCountForFilter:kBGFeedFilterGlobal]) {
        // refreshing cell
        return 75.0;
    }
    
    return 75.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // User cell
    BGViewCellUser *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell"];
    [cell setupWithUser:[self.searchPager elementAtIndex:indexPath.row]];
    
    return cell;

}

#pragma mark - UICollectionViewDelegate

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    if ([self.feedPager isEndOfPagesForFilter:kBGFeedFilterGlobal]) {
        return [_feedPager elementsCountForFilter:kBGFeedFilterGlobal];
    } else {
        return [_feedPager elementsCountForFilter:kBGFeedFilterGlobal] + 1;  // last cell - refreshing spinner. When scrolled to, it will trigger a fetch of the next page
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if (indexPath.row >= [_feedPager elementsCountForFilter:kBGFeedFilterGlobal]) {
        // refresh cell
        UICollectionViewCell *cell = nil;
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LoadingCell" forIndexPath:indexPath];
        
        // MBProgressHUD
        [_progressHUD removeFromSuperview];
        _progressHUD = [[MBProgressHUD alloc] init];
        _progressHUD.color = [UIColor clearColor];
        _progressHUD.activityIndicatorColor = [UIColor whiteColor];
        _progressHUD.opacity = 1.0f;
        [cell.contentView addSubview:_progressHUD];
        [_progressHUD show:YES];
        
        // when this cell gets shown to user, we start loading new portion of feed data
        [self reloadContentForceReload:NO];
        
        return cell;
        
    } else {
        
        BGViewCVItemMedia *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"BGViewCVItemMedia" forIndexPath:indexPath];
        
        [cell setupWithMedia:[_feedPager elementAtIndex:indexPath.row forFilter:kBGFeedFilterGlobal]];
        
        return cell;
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"SectionHeader" forIndexPath:indexPath];
        
        reusableview = headerView;
    }
    
    return reusableview;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(self.frame.size.width, 60.0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(([UIScreen mainScreen].bounds.size.width/3)-1.0, ([UIScreen mainScreen].bounds.size.width/3)-1.0);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{    
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 1.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 1.0;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if(indexPath.row > [_feedPager elementsCountForFilter:kBGFeedFilterGlobal]) {
        return;
    }
    
    Media *media = [_feedPager elementAtIndex:indexPath.row forFilter:kBGFeedFilterGlobal];
    
    BGControllerPostDetails *vc = (BGControllerPostDetails *)[[AppData sharedInstance].navigationManager
                                                              presentControllerForPurpose:kBGPurposePostDetails
                                                              info:@{kVXKeyMedia: media}
                                                              showTabBar:YES
                                                              pushImmediately:NO];
    
    vc.configuration = BGPostDetailsConfigurationExplore;
    
    [(UINavigationController *)[AppData sharedInstance].navigationManager.selectedViewController pushViewController:vc animated:YES];
}

#pragma mark - UISearchBarDelegate



- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.collectionView.hidden = NO;
    self.tableView.scrollsToTop = NO;
    self.collectionView.scrollsToTop = YES;
    self.activePager = self.feedPager;
    [searchBar resignFirstResponder];
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if(searchText.length == 0) {
        self.collectionView.hidden = NO;
        self.tableView.scrollsToTop = NO;
        self.collectionView.scrollsToTop = YES;
        self.activePager = self.feedPager;
        _searchPager.keyword = @"";
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
//    [self.searchPager clearStateAndElements];
//    [self.tableView reloadData];
//    [self.searchBar resignFirstResponder];
//    
//    self.searchPager.keyword = searchBar.text;
//    self.activePager = self.searchPager;
//    self.collectionView.hidden = YES;
//    
//    [self reloadContentForceReload:YES];
}

# pragma mark - ILRemoteSearchBarDelegate

- (void)remoteSearchBar:(ILRemoteSearchBar *)searchBar
          textDidChange:(NSString *)searchText
{
    if(searchText.length > 0 && ![searchText isEqualToString:_searchPager.keyword]) {
        [self.searchPager clearStateAndElements];
        [self.tableView reloadData];
        
        self.searchPager.keyword = searchBar.text;
        self.activePager = self.searchPager;
        self.collectionView.hidden = YES;
        self.tableView.scrollsToTop = YES;
        self.collectionView.scrollsToTop = NO;
        [self reloadContentForceReload:YES];
    }
}

@end

