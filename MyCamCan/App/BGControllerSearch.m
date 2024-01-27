//
//  BGControllerSearch.m
//  Blog
//
//  Created by James Ajhar on 9/4/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGControllerSearch.h"
#import "BGViewSearchAll.h"
#import "ILRemoteSearchBar.h"
#import "WindowHitTest.h"

NSString *kBGControllerSearch = @"BGControllerSearch";

@interface BGControllerSearch () <UISearchBarDelegate, ILRemoteSearchBarDelegate>
{
    NSInteger _page;
}

@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) BGViewSearchAll *searchAllView;

@end

@implementation BGControllerSearch

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.searchBar = [[ILRemoteSearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 64)];
    self.searchBar.showsCancelButton = NO;
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search users";
//    self.navigationItem.titleView = self.searchBar;
    
    BGViewSearchAll *slide1View = (BGViewSearchAll *)[[[NSBundle mainBundle] loadNibNamed:@"BGViewSearchAll" owner:self options:nil] objectAtIndex:0];
    slide1View.frame = self.view.bounds;
    slide1View.autoresizingMask = self.view.autoresizingMask;
    self.searchAllView = slide1View;
    [self.view addSubview:slide1View];
    
    [self.navigationItem setTitle:@"Explore"];
    
    // Notifications
    NSNotificationCenter *sharedNC = [NSNotificationCenter defaultCenter];
    [sharedNC addObserver:self
                 selector:@selector(notificationWindowHitTest:)
                     name:kBGNotificationWindowTapped
                   object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [[BGControllerBase sharedInstance] setHeaderTitle:@"Search"];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Helpers

- (void)scrollUIScrollView:(UIScrollView*)scrollView toPage:(NSInteger)page {
    
    CGFloat pageWidth = scrollView.frame.size.width;
    CGFloat pageHeight = scrollView.frame.size.height;
    CGRect scrollTarget = CGRectMake(page * pageWidth, 0, pageWidth, pageHeight);
    [scrollView scrollRectToVisible:scrollTarget animated:YES];
}

#pragma mark - Interface Actions


- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UISearchBarDelegate

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
    [self.searchAllView searchForContentWithKeyword:searchText];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar resignFirstResponder];
}

#pragma mark Notifications

- (void)notificationWindowHitTest:(NSNotification *)notification {
    UIView *touchedView = [notification object];
    
    if ([self.searchBar isFirstResponder] && touchedView != self.searchBar) {
        [self.searchBar resignFirstResponder];
    }
}



@end
