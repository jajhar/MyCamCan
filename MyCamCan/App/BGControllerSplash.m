//
//  BGControllerSplash.m
//  Blog
//
//  Created by James Ajhar on 9/1/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGControllerSplash.h"
#import "BGControllerLogin.h"
#import "BGControllerRegister.h"
#import "MBProgressHUD.h"

NSString *kBGControllerSplash = @"BGControllerSplash";


@interface BGControllerSplash ()

@property (strong, nonatomic) IBOutlet UILabel *camCanLabel;
@property (strong, nonatomic) NSTimer *displayTimer;
@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;

@end


@implementation BGControllerSplash

- (void)viewDidLoad {
    [super viewDidLoad];

    
    self.displayTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:3.0f]
                                                 interval:1.0
                                                   target:self
                                                 selector:@selector(displayTimerFire:)
                                                 userInfo:nil
                                                  repeats:NO];
    
    [[NSRunLoop currentRunLoop] addTimer:self.displayTimer forMode:NSDefaultRunLoopMode];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if([AppData sharedInstance].restoreLocalSession) {
        [[AppData sharedInstance].navigationManager setModalPresentationStyle: UIModalPresentationFullScreen];
        [self presentViewController:[AppData sharedInstance].navigationManager animated:NO completion:nil];
    }
}

- (void)displayTimerFire:(NSTimer *)timer {
    [self transitionViews];
}

- (void)transitionViews {
    
    [UIView animateWithDuration:.3
                     animations:^{
                         
                         self.camCanLabel.alpha = 0.0;
                         self.logoImageView.alpha = 0.0;
                         
                     } completion:^(BOOL finished) {
                         
                         CATransition *transition = [CATransition animation];
                         transition.duration = 0.3;
                         transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                         transition.type = kCATransitionFade;
                         [self.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];
                         UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LoginStoryboard" bundle:[NSBundle mainBundle]];
                         BGController *controller = [storyboard instantiateViewControllerWithIdentifier:kBGControllerLogin];

                         [self.navigationController setViewControllers:@[controller] animated: NO];

//                         self.containerView.hidden = NO;
//                         self.containerView.alpha = 0.0;
//                         
//                         [UIView animateWithDuration:.3
//                                          animations:^{
//                                              self.containerView.alpha = 1.0;
//                                          }];
                     }];
}


@end
