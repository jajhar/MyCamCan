#import "WindowHitTest.h"
#import "SystemInfo.h"

NSString *kBGNotificationWindowTapped = @"BGNotificationWindowTapped";

@implementation WindowHitTest

- (id)init {
    self = [super init];
    self.opaque = YES;
    self.backgroundColor = [UIColor whiteColor];
    
    return self;
}

/**
 * Dispatches events sent to the receiver by the UIApplication object to its views.
 */
- (void)sendEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    
    if(touch.phase == UITouchPhaseEnded) {
        [self.hitTestDelegate windowHitTestShouldReturnView:[touch view]];
        [[NSNotificationCenter defaultCenter] postNotificationName:kBGNotificationWindowTapped object:[touch view]];
    }
    
    [super sendEvent:event];
    
}

@end
