//
//  BGCollectionViewCellFeedPost.m
//  MCC
//
//  Created by James Ajhar on 7/14/15.
//  Copyright (c) 2015 D9. All rights reserved.
//

#import "BGCollectionViewCellFeedPost.h"


@interface BGCollectionViewCellFeedPost()

//L0

- (void)setMediaInfo:(Media *)mediaInfo displayFeedView:(BOOL)display;

+ (BGCollectionViewCellFeedPost *)referenceCell;


@end


@implementation BGCollectionViewCellFeedPost

#pragma mark L0

- (void)setMediaInfo:(Media *)mediaInfo displayFeedView:(BOOL)display showCompactHeader:(BOOL)compactHeader{
    _mediaInfo = mediaInfo;
    [self.feedPostView setMediaInfo:_mediaInfo displayFeedView:display showCompactHeader:compactHeader];
}

- (void)setMediaInfo:(Media *)mediaInfo displayFeedView:(BOOL)display {
    _mediaInfo = mediaInfo;
    [self.feedPostView setMediaInfo:_mediaInfo displayFeedView:display showCompactHeader:NO];
}


+ (BGCollectionViewCellFeedPost *)referenceCell {
    
    if (ReferenceCell == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            UINib *nib = [UINib nibWithNibName:@"BGPostContentCell" bundle:[NSBundle mainBundle]];
            ReferenceCell = [[nib instantiateWithOwner:self options:nil] objectAtIndex:0];
        });
        
    }
    return ReferenceCell;

}

#pragma mark L1

static BGCollectionViewCellFeedPost *ReferenceCell = nil;


- (void)prepareForReuse {
    [super prepareForReuse];
    [self.feedPostView prepareForReuse];
}

#pragma mark BGView
/**
 * Proper initialization of FeedPostView xib
 */

- (void)commonInit {
    [super commonInit];
    
    self.feedPostView = [[[NSBundle mainBundle] loadNibNamed:@"BGViewFeedPost"
                                                       owner:nil
                                                     options:nil] objectAtIndex:0];
    
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    
    [self.contentView addSubview:self.feedPostView];
    
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.feedPostView setFrame:self.contentView.frame];
    
}


@end
