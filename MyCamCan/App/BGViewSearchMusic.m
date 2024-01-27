//
//  BGViewSearchAll.m
//  Blog
//
//  Created by James Ajhar on 11/9/15.
//  Copyright © 2015 James Ajhar. All rights reserved.
//

#import "BGViewSearchMusic.h"

#import "MBProgressHUD.h"
#import "WindowHitTest.h"
#import "BGMusicCell.h"
#import "HysteriaPlayer.h"
#import "MusicItem.h"
#import "ILRemoteSearchBar.h"

@interface BGViewSearchMusic () <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, HysteriaPlayerDataSource, HysteriaPlayerDelegate, ILRemoteSearchBarDelegate>

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *musicItems;
@property (strong, nonatomic) HysteriaPlayer *musicPlayer;
@property (nonatomic, assign) BOOL didSelectItem;

@end


@implementation BGViewSearchMusic

- (void)commonInit {
    [super commonInit];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.musicPlayer = [HysteriaPlayer new];
    self.musicPlayer.delegate = self;
    self.musicPlayer.datasource = self;
    [self.musicPlayer setPlayerRepeatMode:HysteriaPlayerRepeatModeOn];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"BGMusicCell" bundle:nil] forCellReuseIdentifier:@"musicCell"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notificationWindowHitTest:)
                                                 name:kBGNotificationWindowTapped
                                               object:nil];
    
    [self.searchBar resignFirstResponder];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.musicPlayer pause];
    [self.musicPlayer removeAllItems];
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
    
    [self.musicPlayer pause];
    [self.musicPlayer removeAllItems];
}

- (void)pausePlayer {
    [self.musicPlayer pause];
    [self.musicPlayer removeAllItems];
}

- (void)searchForContentWithKeyword:(NSString *)keyword {
    
    [MBProgressHUD showHUDAddedTo:self animated:YES];
    
    [[AppData sharedInstance] searchMusicWithKeyword:keyword
                                            callback:^(id result, NSError *error) {
                                               
                                                [MBProgressHUD hideAllHUDsForView:self animated:YES];
                                                
                                                if(!error && result) {
                                                    [self.musicPlayer pause];
                                                    [self.musicPlayer removeAllItems];
                                                    
                                                    self.musicItems = result;
                                                    [self.tableView reloadData];
                                                }
                                            }];
}

#pragma mark Notifications


- (void)notificationWindowHitTest:(NSNotification *)notification {
    UIView *touchedView = [notification object];
    
    if ([self.searchBar isFirstResponder] && touchedView != self.searchBar) {
        [self.searchBar resignFirstResponder];
    }
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.musicItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    BGMusicCell *cell = [tableView dequeueReusableCellWithIdentifier:@"musicCell"];
    [cell setMusicItem:[self.musicItems objectAtIndex:indexPath.row]];
    
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1.0];
    [cell setSelectedBackgroundView:bgColorView];
    
    [cell setSelectedBackgroundView:bgColorView];
    
    if(indexPath.row % 2 == 0) {
        // even colored cell
        cell.backgroundColor = [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1.0];
    } else {
        // odd colored cell
        cell.backgroundColor = [UIColor whiteColor];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if([self.delegate respondsToSelector:@selector(BGViewSearchMusicDidSelectMusicItem:)]) {
        [self.delegate BGViewSearchMusicDidSelectMusicItem:[self.musicItems objectAtIndex:indexPath.row]];
    }
    
    BGMusicCell *cell = (BGMusicCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:YES];
    
    _didSelectItem = YES;
    
    [self.musicPlayer fetchAndPlayPlayerItem:indexPath.row];

}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    BGMusicCell *cell = (BGMusicCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:NO];
}


#pragma mark - UISearchBarDelegate 


- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar resignFirstResponder];
    [self searchForContentWithKeyword:searchBar.text];
}

# pragma mark - ILRemoteSearchBarDelegate

- (void)remoteSearchBar:(ILRemoteSearchBar *)searchBar
          textDidChange:(NSString *)searchText
{
    if(searchText.length > 0) {
        [self searchForContentWithKeyword:searchBar.text];
    }
}

#pragma mark - HysteriaPlayerDataSource


- (NSInteger)hysteriaPlayerNumberOfItems {
    return [self.musicItems count];
}

- (NSURL *)hysteriaPlayerURLForItemAtIndex:(NSInteger)index preBuffer:(BOOL)preBuffer {
    return [[self.musicItems objectAtIndex:index] previewURL];
}

- (void)hysteriaPlayerCurrentItemChanged:(AVPlayerItem *)item {
    [self.musicPlayer play];
    _didSelectItem = NO;
}

@end

