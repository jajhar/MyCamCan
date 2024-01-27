

#import "BGViewCell.h"

@interface BGViewCell ()


@end

@implementation BGViewCell

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
* Initializes a table cell with a style and a reuse identifier and returns it to the caller.
 */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) != nil) {
        [self commonInit];
    }
    return self;
}
/**
* Prepares the receiver for service after it has been loaded from an Interface Builder archive, or nib file.
 */
- (void)awakeFromNib {
    [super awakeFromNib];
}
/**
* The view’s autoresizing mask is translated into constraints for the constraint-based layout system.
 */
- (BOOL)translatesAutoresizingMaskIntoConstraints {
    return YES;
}

- (void)commonInit {
    //nop
}

@end
