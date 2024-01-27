

#import "BGPostContentCell.h"


@interface BGPostContentCell()

//L0

+ (BGPostContentCell *)referenceCell;




@end


static BGPostContentCell *ReferenceCell = nil;


@implementation BGPostContentCell


#pragma mark L0


- (void)setMediaInfo:(Media *)mediaInfo {
    _mediaInfo = mediaInfo;
    
    [self.feedView setMediaInfo:_mediaInfo displayFeedView:YES showCompactHeader:NO];
}

+ (BGPostContentCell *)referenceCell {
    
    if (ReferenceCell == nil) {
        UINib *nib = [UINib nibWithNibName:@"BGPostContentCell" bundle:[NSBundle mainBundle]];
        ReferenceCell = [[nib instantiateWithOwner:self options:nil] objectAtIndex:0];
    }
    return ReferenceCell;
}

#pragma mark BGView
/**
 * Proper initialization of FeedPostView xib
 */

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.feedView = [[[NSBundle mainBundle] loadNibNamed:@"BGViewFeedPost"
                                                       owner:nil
                                                     options:nil] objectAtIndex:0];
    
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.feedView.frame = self.contentView.bounds;
    [self.contentView addSubview:self.feedView];

    [self.feedView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant: 0.0].active = true;
    [self.feedView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant: 0.0].active = true;
    [self.feedView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant: 0.0].active = true;
    [self.feedView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant: 0.0].active = true;

    [self layoutIfNeeded];
    [self.contentView layoutIfNeeded];
    [self.feedView layoutIfNeeded];
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.contentView layoutIfNeeded];
    [self.feedView layoutIfNeeded];

}

@end

