#import "BGViewBanner.h"
#import "BGView_Inherit.h"

@interface BGViewBanner ()

//L1

@property (strong, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) IBOutlet UIButton *notificationsButton;
@property (strong, nonatomic) IBOutlet UIButton *searchButton;
@property (strong, nonatomic) IBOutlet UILabel *notificationsCountLabel;
@property (assign, nonatomic) BOOL isAnimating;
@property (strong, nonatomic) BGViewBannerBackButtonCallback backButtonCallback;
@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIImageView *headerImage;

@end

const CGFloat kBGViewBannerHeight = 80;

@implementation BGViewBanner


#pragma mark L0

- (void)setTitle:(NSString *)title {
    
    if(title.length > 0) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.headerImage.alpha = 0.0;
                         }];
    } else {
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.headerImage.alpha = 1.0;
                         }];
    }
    
    CATransition *animation = [CATransition animation];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = kCATransitionFade;
    animation.duration = 0.3;
    [self.label.layer addAnimation:animation forKey:@"kCATransitionFade"];
    
    self.label.text = title;
}

- (void)setColor:(UIColor *)color {
    self.backgroundColor = color;
}

-(void)showBackButton:(BGViewBannerBackButtonCallback)callback animated:(BOOL)animated
{
    if(_isAnimating) {
        animated = NO;
    }
    
    self.backButton.hidden = NO;
    
    if(animated) {
        _isAnimating = YES;
        
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.backButton.alpha = 1.0;
                         }
                         completion:^(BOOL finished) {
                             _isAnimating = NO;
                         }];
    } else {
        self.backButton.alpha = 1.0;
    }
    
    self.backButtonCallback = callback;
}

- (void)hideBackButtonAnimated:(BOOL)animated
{
    if(_isAnimating) {
        animated = NO;
    }
    
    if(animated) {
        _isAnimating = YES;
        
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.backButton.alpha = 0.0;
                         }
                         completion:^(BOOL finished) {
                             self.backButton.hidden = YES;
                             _isAnimating = NO;
                         }];
    } else {
        self.backButton.alpha = 0.0;
        self.backButton.hidden = YES;
    }
    
    self.backButtonCallback = nil;
}

- (IBAction)backPressed:(id)sender {
}

@end
