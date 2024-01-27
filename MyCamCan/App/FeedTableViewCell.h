//
//  FeedTableViewCell.h
//  Blog
//
//  Created by James Ajhar on 5/29/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Post.h"

@interface FeedTableViewCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource>

@property (strong, nonatomic, readonly) Post *post;

- (void)setPost:(Post *)post;

@end
