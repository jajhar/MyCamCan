#import "VXViewTouchless.h"

@implementation VXViewTouchless

#pragma mark L0

@synthesize enableTouches = _enableTouches;

#pragma mark - Inherited

#pragma mark UIView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    id result = nil;
    if ([self pointInside:point withEvent:event]) {
        result = [super hitTest:point withEvent:event];
    }
    if (!self.enableTouches && (result == self)) {
        result = nil;
    }
    return result;
}

@end
