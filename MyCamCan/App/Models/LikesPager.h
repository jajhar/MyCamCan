//
//  LikesPager.h
//  RedSoxApp
//
//  Created by Shakuro Developer on 5/29/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//


#import "Pager.h"


@class Like;
@class Media;


@interface LikesPager : Pager

+ (LikesPager *)likesPagerForMedia:(Media *)media;

- (Like *)likeElementAtIndex:(NSUInteger)index;

@end
