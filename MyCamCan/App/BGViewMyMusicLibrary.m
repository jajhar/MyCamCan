//
//  BGViewMyMusicLibrary.m
//  Blog
//
//  Created by James Ajhar on 2/4/16.
//  Copyright © 2016 James Ajhar. All rights reserved.
//

#import "BGViewMyMusicLibrary.h"
#import "BGMusicCell.h"
#import "HysteriaPlayer.h"
#import "MusicItem.h"

@import MediaPlayer;

@interface BGViewMyMusicLibrary () <UITableViewDataSource, UITableViewDelegate, HysteriaPlayerDataSource, HysteriaPlayerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *musicItems;
@property (strong, nonatomic) NSArray *filteredItems;

@property (strong, nonatomic) HysteriaPlayer *musicPlayer;
@property (nonatomic, assign) BOOL didSelectItem;

@end


@implementation BGViewMyMusicLibrary


- (void)commonInit {
    [super commonInit];
    
    self.musicItems = [NSMutableArray new];
    self.filteredItems = [NSArray new];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.musicPlayer = [HysteriaPlayer new];
    self.musicPlayer.delegate = self;
    self.musicPlayer.datasource = self;
    [self.musicPlayer setPlayerRepeatMode:HysteriaPlayerRepeatModeOn];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"BGMusicCell" bundle:nil] forCellReuseIdentifier:@"musicCell"];

    [self checkMediaLibraryPermissions];
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

-(void) checkMediaLibraryPermissions {
    [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus status){
        switch (status) {
            case MPMediaLibraryAuthorizationStatusNotDetermined: {
                // not determined
                break;
            }
            case MPMediaLibraryAuthorizationStatusRestricted: {
                // restricted
                break;
            }
            case MPMediaLibraryAuthorizationStatusDenied: {
                // denied
                break;
            }
            case MPMediaLibraryAuthorizationStatusAuthorized: {
                // authorized
                [self performSelectorInBackground:@selector(fetchMusicLibrary) withObject:nil];
                break;
            }
            default: {
                break;
            }
        }
    }];
}

- (void)fetchMusicLibrary {

    NSNumber *mediaTypeNumber = [NSNumber numberWithInteger:MPMediaTypeMusic]; // == 1
    MPMediaPropertyPredicate *mediaTypePredicate = [MPMediaPropertyPredicate predicateWithValue:mediaTypeNumber
                                                                                    forProperty:MPMediaItemPropertyMediaType];
    
    NSSet *predicateSet = [NSSet setWithObjects:mediaTypePredicate, nil];
    MPMediaQuery *mediaTypeQuery = [[MPMediaQuery alloc] initWithFilterPredicates:predicateSet];
    [mediaTypeQuery setGroupingType:MPMediaGroupingTitle];
    
    NSArray *collections = [mediaTypeQuery collections];
    
    for (MPMediaItemCollection *collection in collections) {
        
        MusicItem *item = [MusicItem new];
        item.previewURL = [collection.representativeItem valueForKey: MPMediaItemPropertyAssetURL];
        
        if (item.previewURL == nil) {
            // ignore assets without urls...can't do anything with them...
            continue;
        }
        
        item.needsExport = YES;
        item.title = [collection.representativeItem valueForProperty: MPMediaItemPropertyTitle];
        item.artist = [collection.representativeItem valueForProperty: MPMediaItemPropertyAlbumArtist];
        MPMediaItemArtwork *artwork = [collection.representativeItem valueForProperty: MPMediaItemPropertyArtwork];
        item.artwork = [artwork imageWithSize:CGSizeMake(150, 150)];        
        [self.musicItems addObject:item];
    }
    
    self.filteredItems = [self.musicItems mutableCopy];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });

}

- (void)searchForContentWithKeyword:(NSString *)keyword {
    if (keyword.length == 0) {
        self.filteredItems = self.musicItems;
        [self.tableView reloadData];
        return;
    }
    
    NSString *predString = [NSString stringWithFormat:@"(title CONTAINS[cd] '%@') || (artist CONTAINS[cd] '%@')", keyword, keyword];
    NSPredicate *pred = [NSPredicate predicateWithFormat:predString];
    self.filteredItems = [self.musicItems filteredArrayUsingPredicate:pred];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.filteredItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    BGMusicCell *cell = [tableView dequeueReusableCellWithIdentifier:@"musicCell"];
    [cell setMusicItem:[self.filteredItems objectAtIndex:indexPath.row]];

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
    
    if([self.delegate respondsToSelector:@selector(BGViewMyMusicLibraryDidSelectMusicItem:)]) {
        [self.delegate BGViewMyMusicLibraryDidSelectMusicItem:[self.filteredItems objectAtIndex:indexPath.row]];
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
    return [self.filteredItems count];
}

- (NSURL *)hysteriaPlayerURLForItemAtIndex:(NSInteger)index preBuffer:(BOOL)preBuffer {
    return [[self.filteredItems objectAtIndex:index] previewURL];
}

- (void)hysteriaPlayerCurrentItemChanged:(AVPlayerItem *)item {
    [self.musicPlayer play];
    _didSelectItem = NO;
}

@end
