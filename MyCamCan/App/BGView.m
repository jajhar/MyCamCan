#import "BGView.h"

@implementation BGView

#pragma mark - Inherited

#pragma mark UIView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame]) != nil) {
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self commonInit];
}

- (BOOL)translatesAutoresizingMaskIntoConstraints {
    return NO;
}

- (void)commonInit {
    //nop
}

@end
