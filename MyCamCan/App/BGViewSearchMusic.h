//
//  BGViewSearchAll.h
//  Blog
//
//  Created by James Ajhar on 11/9/15.
//  Copyright © 2015 James Ajhar. All rights reserved.
//

#import "BGView.h"

@class MusicItem;

@protocol BGViewSearchMusicDelegate <NSObject>

- (void)BGViewSearchMusicDidSelectMusicItem:(MusicItem *)item;

@end

@interface BGViewSearchMusic : BGView

@property (nonatomic, assign) id delegate;

- (void)pausePlayer;
- (void)searchForContentWithKeyword:(NSString *)keyword;

@end
