//
//  BGViewMyMusicLibrary.h
//  Blog
//
//  Created by James Ajhar on 2/4/16.
//  Copyright © 2016 James Ajhar. All rights reserved.
//

#import "BGView.h"

@class MusicItem;

@protocol BGViewFeaturedArtistDelegate <NSObject>

- (void)BGViewFeaturedArtistDidSelectMusicItem:(MusicItem *)item;

@end

@interface BGViewFeaturedArtist : BGView

@property (nonatomic, assign) id delegate;
@property (strong, nonatomic) NSMutableArray *musicItems;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (void)pausePlayer;

@end
