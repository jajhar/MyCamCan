/**
*  BGViewFeedPostDetails.h
*  MCC
*  @author  James Ajhar
*  @since 10/9/14.
*  Copyright (c) 2014 D9. All rights reserved.
*/

#import "BGView.h"

@class BGViewFeedPost;

@protocol BGViewFeedPostDelegate

- (void)feedView:(BGViewFeedPost *)view mediaItemTapped:(Media *)media;

@end

@interface BGViewFeedPost : BGView <UIActionSheetDelegate, UIScrollViewDelegate>

/**
 *<p>
 * This method returns the height of the FeedPostView based on adding bottomContainerView.frame.origin.y +
 * bottomContainerView.frame.size.height
 */

- (CGFloat)heightOfViewWithMedia:(Media *)media showFeedDisplay:(BOOL)display;

/**
 * This method is called to add media info to FeedPostView
 */

- (void)prepareForReuse;

- (void)setMediaInfo:(Media *)mediaInfo displayFeedView:(BOOL)display showCompactHeader:(BOOL)compactHeader;
/**
*<p> 
* Media is DataModalObject which contains the complete info about each media like dictionary info,media name,media 
* type,id,etc...
 
*/
@property (strong, nonatomic, readonly) Media *mediaInfo;
/**
 * delegate method for BGViewFeedPostDelegate protocal
 */
@property (assign, nonatomic) id delegate;

@property (strong, nonatomic) UIProgressView *progressView;

@end
