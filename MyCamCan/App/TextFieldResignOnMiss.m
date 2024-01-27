#import "TextFieldResignOnMiss.h"

@implementation TextFieldResignOnMiss

#pragma mark - Inherited

#pragma mark NSObject

- (void)dealloc {
    WindowHitTest *window = (WindowHitTest *)[[UIApplication sharedApplication].delegate window];
    if (window.hitTestDelegate == self) {
        window.hitTestDelegate = nil;
    }
}

#pragma mark UIResponder

- (BOOL)becomeFirstResponder {
	BOOL result = [super becomeFirstResponder];
    if (result) {
        ((WindowHitTest *)[[UIApplication sharedApplication].delegate window]).hitTestDelegate = self;
    }
	return result;
}

- (BOOL)resignFirstResponder {
    BOOL result = [super resignFirstResponder];
    if (result) {
        WindowHitTest *window = (WindowHitTest *)[[UIApplication sharedApplication].delegate window];
		if (window.hitTestDelegate == self) {
            window.hitTestDelegate = nil;
        }
    }
    return result;
}

- (void)commonInit {
    self.opaque = NO;
}
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        [self commonInit];
    }
    return self;
}
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self != nil) {
        [self commonInit];
    }
    return self;
}


//#pragma mark UITextField
//
//- (CGRect)textRectForBounds:(CGRect)bounds {
//    return CGRectMake(bounds.origin.x + 10, bounds.origin.y + 1.0, bounds.size.width - 20, bounds.size.height - 2.0);
//}
//
//- (CGRect)editingRectForBounds:(CGRect)bounds {
//    return [self textRectForBounds:bounds];
//}

#pragma mark - Protocols

#pragma mark WindowHitTestDelegate

- (UIView *)windowHitTestShouldReturnView:(UIView *)view {
    if (view && ![view isDescendantOfView:self] && ![NSStringFromClass(view.class) isEqualToString:@"UIAutocorrectInlinePrompt"]) {
        if ([view canBecomeFirstResponder]) {
            [view becomeFirstResponder];
        }
        else {
	        [self resignFirstResponder];
        }
    }
    return view;
}

@end
