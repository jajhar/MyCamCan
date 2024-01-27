//
//  BGControllerLikes.m
//  Blog
//
//  Created by James Ajhar on 9/25/15.
//  Copyright © 2015 James Ajhar. All rights reserved.
//

#import "BGControllerLikes.h"
#import "MBProgressHUD.h"
#import "LikesPager.h"
#import "Media.h"
#import "UIView+Gradient.h"
#import "Like.h"
#import "BGViewCellLike.h"

NSString *kBGControllerLikes = @"BGControllerLikes";

@interface BGControllerLikes () <UITableViewDataSource, UITableViewDelegate>

// Interface
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *gradientView;

// Data
@property (strong, nonatomic) LikesPager *likesPager;
@property (strong, nonatomic) MBProgressHUD *progressHUD;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) Media *media;

@end


@implementation BGControllerLikes

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.likesPager = _media.likesPager;
    
    [UIView addLinearGradientToView:self.gradientView withColor:[UIColor colorWithRed:255.0/255.0 green:200.0/255.0 blue:0.0/255.0 alpha:1.0] transparentToOpaque:NO];
    
    NSNotificationCenter *sharedNC = [NSNotificationCenter defaultCenter];
    [sharedNC addObserver:self
                 selector:@selector(notificationLikesListChanged:)
                     name:kAppData_Notification_Pager_Likes
                   object:nil];
    
    // refresh control
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshView:) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl setTintColor:[UIColor whiteColor]];
    tableViewController.refreshControl = self.refreshControl;
    
    [self.tableView reloadData];
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];

}

- (void)setInfo:(NSDictionary *)info animated:(BOOL)animated {
    [super setInfo:info animated:animated];
    
    _media = [info objectForKey:kVXKeyMedia];
}

#pragma mark Notifications


/**
 *<p>
 *  This method will be called via NSNotificationCenter whenever the list of notifications has changed in some way.
 *  It will add, remove, or refresh cells accordingly.
 */
- (void)notificationLikesListChanged:(NSNotification *)notification {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}


#pragma mark - Interface Actions

- (IBAction)closeButtonPressed:(id)sender {
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [self.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];

    if (self.navigationController) {
    
        [self.navigationController popViewControllerAnimated:NO];
        
    } else {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

/**
 * callback of the refresh control
 */
- (void)refreshView:(UIRefreshControl *)refresh {
    [self getLikesForceReload:YES];
}

- (void)getLikesForceReload:(BOOL)forceReload {
    PagerCompletionBlock completionBlock = ^(NSError *error) {
        // hide all spinners
        [self.refreshControl endRefreshing];
        
    };
    
    if (forceReload) {
        [_likesPager reloadWithCompletion:completionBlock];
    } else {
        [_likesPager getNextPageWithCompletion:completionBlock];
    }
}

#pragma mark - UITableViewDelegate/Datasource


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 75.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if([_likesPager isEndOfPages]) {
        return [_likesPager elementsCount];
    } else {
        return [_likesPager elementsCount] + 1;  // last cell - refreshing spinner. When scrolled to, it will trigger a fetch of the next page
    }
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    
//    if(indexPath.row < _likesPager.elementsCount) {
//        [[BGControllerBase sharedInstance] presentControllerForPurpose:kBGPurposeProfile
//                                                              animated:YES
//                                                             fromRight:YES
//                                                                  info:@{kVXKeyUser: .owner}];
//    }
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (indexPath.row >= [_likesPager elementsCount]) {
        return;
    }
    
    Like *like = [_likesPager elementAtIndex:indexPath.row];
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [self.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];
    
    [self dismissViewControllerAnimated:NO completion:nil];
    
    [[AppData sharedInstance].navigationManager presentControllerForPurpose:kBGPurposeProfile info:@{kVXKeyUser: like.owner} showTabBar:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [_likesPager elementsCount]) {
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
        [self getLikesForceReload:NO];
        
        return cell;
    } else {
        // feed cell
        BGViewCellLike *cell = [tableView dequeueReusableCellWithIdentifier:@"LikeCell"];
        [cell setupWithLike:[_likesPager elementAtIndex:indexPath.row]];
        
//        if(indexPath.row % 2 != 0) {
//            [cell.contentView setBackgroundColor:[UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0]];
//        } else {
//            [cell.contentView setBackgroundColor:[UIColor whiteColor]];
//        }
        
        return cell;
    }
}

@end
