//
//  BGCollectionViewCellFeedPost.h
//  MCC
//
//  Created by James Ajhar on 7/14/15.
//  Copyright (c) 2015 D9. All rights reserved.
//

#import "BGViewCVItem.h"
#import "BGViewFeedPost.h"

@interface BGCollectionViewCellFeedPost : BGViewCVItem

/**
 * Proper initialization of FeedPostCell xib
 */

+ (BGCollectionViewCellFeedPost *)referenceCell;

/**
 * This method is called to add media info to FeedPostView
 */
- (void)setMediaInfo:(Media *)mediaInfo displayFeedView:(BOOL)display showCompactHeader:(BOOL)compactHeader;


@property (strong, nonatomic, readonly) Media *mediaInfo;
@property (strong, nonatomic) IBOutlet BGViewFeedPost *feedPostView;


@end
