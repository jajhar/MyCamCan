#import "VXView.h"
#import "VXView_Inherit.h"

@interface VXView () <VXView_Inherit> {
    //L1
    id<VX_Requests> _owner;
}

@end

@implementation VXView

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

#pragma mark - Protocols

#pragma mark VX_HasOwner

- (id<VX_Requests>)owner {
    return _owner;
}

- (void)setOwner:(id<VX_Requests>)owner {
    _owner = owner;
}

#pragma mark VXView_Inherit

- (void)commonInit {
    //nop
}

@end
