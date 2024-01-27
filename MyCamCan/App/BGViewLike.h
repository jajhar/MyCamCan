//
//  BGViewLike.h
//  Blog
//
//  Created by James Ajhar on 9/8/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGView.h"

@class BGViewLike;

@protocol BGViewLikeDelegate

- (BOOL)shouldKeepAnimating:(BGViewLike *)likeView;

@end


@interface BGViewLike : BGView

@property (nonatomic, assign) id delegate;

- (void)setImage:(UIImage *)image;
- (void)startAnimating;

@end
