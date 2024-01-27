#import "ScrollViewRespectsKeyboard.h"

@interface ScrollViewRespectsKeyboard ()

@property (assign, nonatomic) UIEdgeInsets originalInsets;

@end

@implementation ScrollViewRespectsKeyboard

@synthesize originalInsets = _originalInsets;
/**
* Returns an object initialized from data in a given unarchiver.
 */
- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super initWithCoder:aDecoder]) != nil) {
		[self commonInit];
	}
	return self;
}

/**
* Initializes and returns a newly allocated view object with the specified frame rectangle.
 */
- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame]) != nil) {
		[self commonInit];
	}
	return self;
}

- (void)commonInit {
//	self.scrollsToTop = YES;
}

/**
* dealloactes the memory occupaid by the observer added in this view.
*/
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}
/**
* Tells the view that its superview is about to change to the specified superview.
 */
- (void)willMoveToSuperview:(UIView *)newSuperview {
	if ((self.superview == nil) && (newSuperview != nil)) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kbWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
	}
}
/**
* Tells the view that its superview changed
 */
- (void)didMoveToSuperview {
	if (self.superview == nil) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
		[self updateFrameToKeyboardFrame:CGRectMake((CGFloat)0,CGFLOAT_MAX,(CGFloat)0,(CGFloat)0) duration:0.0 curve:UIViewAnimationCurveLinear];
	}
}

#pragma mark - Keyboard callbacks
/**
* This method is called action to frame view change when keyboard will appear.
 */
- (void)kbWillChange:(NSNotification *)notification {
	CGRect toFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGFloat animationDuration = (CGFloat)[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	UIViewAnimationCurve animationCurve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];

	toFrame = [[[UIApplication sharedApplication].delegate window] convertRect:toFrame fromWindow:nil];
	toFrame = [self.superview convertRect:toFrame fromView:nil];

	[self updateFrameToKeyboardFrame:toFrame duration:animationDuration curve:animationCurve];
}

/**
 * This method is called action to update frame to key board frame
 */
- (void)updateFrameToKeyboardFrame:(CGRect)kbFrame duration:(CGFloat)duration curve:(UIViewAnimationCurve)curve {
	// kb frame is in parent's coordinate system
    CGFloat overlap = CGRectGetMaxY(self.frame) - CGRectGetMinY(kbFrame);
    CGFloat inset = MAX(MAX(0,
                            overlap),
                        self.originalInsets.bottom);

	UIViewAnimationOptions animationCurveOption = (UIViewAnimationOptions)(curve << 16);

	UIEdgeInsets insets = self.contentInset;
	insets.bottom = inset;

	[UIView animateWithDuration:duration
                          delay:0.0
                        options:animationCurveOption | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.contentInset = insets;
                     }
                     completion:NULL];
}

@end
