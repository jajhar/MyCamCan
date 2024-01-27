//
//  BGViewMyMusicLibrary.m
//  Blog
//
//  Created by James Ajhar on 2/4/16.
//  Copyright © 2016 James Ajhar. All rights reserved.
//

#import "BGViewFeaturedArtist.h"

#import "BGMusicCell.h"
#import "HysteriaPlayer.h"
#import "MusicItem.h"
#import "MBProgressHUD.h"

@import MediaPlayer;

@interface BGViewFeaturedArtist () <UITableViewDataSource, UITableViewDelegate, HysteriaPlayerDataSource, HysteriaPlayerDelegate>


@property (strong, nonatomic) HysteriaPlayer *musicPlayer;
@property (nonatomic, assign) BOOL didSelectItem;

@end


@implementation BGViewFeaturedArtist


- (void)commonInit {
    [super commonInit];
    
    self.musicItems = [NSMutableArray new];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.musicPlayer = [HysteriaPlayer new];
    self.musicPlayer.delegate = self;
    self.musicPlayer.datasource = self;
    [self.musicPlayer setPlayerRepeatMode:HysteriaPlayerRepeatModeOn];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"BGMusicCell" bundle:nil] forCellReuseIdentifier:@"musicCell"];
//    [self getFeaturedMusicList];
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

- (void)getFeaturedMusicList {
    
    
//    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MusicPlist" ofType:@"plist"]];
//    NSArray *array = [dictionary objectForKey:@"Music"];
//    NSMutableArray *musicItems = [NSMutableArray new];
//    
//    for (NSDictionary *dictionary in array) {
//        MusicItem *item = [[MusicItem alloc] init];
//        item.previewURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:[dictionary objectForKey:@"filename"] ofType:@"mp3"]];
//        item.title = [dictionary objectForKey:@"title"];
//        item.artist = @"#MyCamCan";
//        [musicItems addObject:item];
//    }
//    
//    [self.musicPlayer pause];
//    [self.musicPlayer removeAllItems];
//    self.musicItems = musicItems;
//    [self.tableView reloadData];
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
    
    if([self.delegate respondsToSelector:@selector(BGViewFeaturedArtistDidSelectMusicItem:)]) {
        [self.delegate BGViewFeaturedArtistDidSelectMusicItem:[self.musicItems objectAtIndex:indexPath.row]];
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
