/**
 *  BGViewCVItem.h
 *  MCC
 *
 */
#import "BGViewCVItem.h"

@interface BGViewCVItem ()

@end

@implementation BGViewCVItem

#pragma mark - Inherited

#pragma mark UIView

/**
 * Initializes and returns a newly allocated view object with the specified frame rectangle.
 *
 * @param frame: The frame rectangle for the view, measured in points.
 * @return An initialized view object or nil if the object couldn't be created.
 */
- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame]) != nil) {
        [self commonInit];
    }
    return self;
}
/**
* Prepares the receiver for service after it has been loaded from an Interface Builder archive, or nib file.
 */
- (void)awakeFromNib {
    [super awakeFromNib];
    [self commonInit];
}

- (void)commonInit {
    //nop
}

@end
