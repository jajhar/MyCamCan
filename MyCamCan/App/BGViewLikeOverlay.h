//
//  BGViewLikeOverlay.h
//  Blog
//
//  Created by James Ajhar on 9/8/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGView.h"

@interface BGViewLikeOverlay : BGView

- (void)setCurrentLikesCount:(NSUInteger)count;
- (void)addLikeAnimated:(BOOL)animated;
- (void)removeLike;

@end
