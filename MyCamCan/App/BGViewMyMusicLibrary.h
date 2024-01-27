//
//  BGViewMyMusicLibrary.h
//  Blog
//
//  Created by James Ajhar on 2/4/16.
//  Copyright © 2016 James Ajhar. All rights reserved.
//

#import "BGView.h"

@class MusicItem;

@protocol BGViewMyMusicLibraryDelegate <NSObject>

- (void)BGViewMyMusicLibraryDidSelectMusicItem:(MusicItem *)item;

@end

@interface BGViewMyMusicLibrary : BGView

@property (nonatomic, assign) id delegate;

- (void)pausePlayer;
- (void)fetchMusicLibrary;
- (void)searchForContentWithKeyword:(NSString *)keyword;

@end
