//
//  VXCollectionViewCellFeedPost.h
//  Vixlet
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
 *<p>
 * This method returns the height of the FeedPostView based on adding bottomContainerView.frame.origin.y +
 * bottomContainerView.frame.size.height
 */
- (CGFloat)heightOfCellWithMedia:(Media *)media  showFeedDisplay:(BOOL)display;
/**
 * This method is called to add media info to FeedPostView
 */
- (void)setMediaInfo:(Media *)mediaInfo displayFeedView:(BOOL)display showCompactHeader:(BOOL)compactHeader;


@property (strong, nonatomic, readonly) Media *mediaInfo;
@property (strong, nonatomic) IBOutlet BGViewFeedPost *feedPostView;


@end
