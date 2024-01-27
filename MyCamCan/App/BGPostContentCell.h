/**
*  BGViewCellFeedPost.h
*  MCC
*  @author  James Ajhar
*  @since 10/9/14.
*  Copyright (c) 2014 D9. All rights reserved.
*/

#import "BGViewCell.h"
#import "BGViewFeedPost.h"

@interface BGPostContentCell : BGViewCell <UITextViewDelegate, UIAlertViewDelegate>

/**
 * Proper initialization of FeedPostCell xib
 */

+ (BGPostContentCell *)referenceCell;

@property (strong, nonatomic) Media *mediaInfo;
@property (strong, nonatomic) BGViewFeedPost *feedView;


@end
