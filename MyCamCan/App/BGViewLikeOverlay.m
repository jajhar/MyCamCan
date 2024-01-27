//
//  BGViewLikeOverlay.m
//  Blog
//
//  Created by James Ajhar on 9/8/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGViewLikeOverlay.h"

#import "BGViewLike.h"

/** Degrees to Radian **/
#define degreesToRadians( degrees ) ( ( degrees ) / 180.0 * M_PI )

@interface BGViewLikeOverlay () <BGViewLikeDelegate>

@property (nonatomic) NSUInteger likesCount;
@property (nonatomic) NSUInteger currentLikeIndex;

@property (strong, nonatomic) NSMutableArray *likeViews;

@end


@implementation BGViewLikeOverlay


- (void)commonInit {
    [super commonInit];
    self.likeViews = [NSMutableArray new];

}

- (void)setCurrentLikesCount:(NSUInteger)count {
    [self removeAllLikes];
    _likesCount = count;
    _currentLikeIndex = 1;
    [self displayRandomLikes];
}

- (void)removeAllLikes {
    for(UIView *view in self.likeViews) {
        [view removeFromSuperview];
    }
    
    _likesCount = 0;
}

- (void)addLikeAnimated:(BOOL)animated {
    CGFloat randomX = arc4random_uniform(self.frame.size.width) - 20.0;
    CGFloat randomY = arc4random_uniform(self.frame.size.height) - 20.0;//(self.frame.size.height*1/3) - 30.0) + (self.frame.size.height*2/3) + 30.0;
    
    NSInteger r = 1;
    
    if(_currentLikeIndex > 10 && _currentLikeIndex < 40) {
        r = 2;
    }
    if(_currentLikeIndex >= 40 && _currentLikeIndex < 75) {
        r = 3;
    }
    if(_currentLikeIndex > 75) {
        r = 4;
    }
    
    BGViewLike *likeView = [[BGViewLike alloc] initWithFrame:CGRectMake(randomX, randomY, 30.0, 30.0)];
    [likeView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"heart-interaction-0%lu", r]]];
    likeView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;

    [self addSubview:likeView];
    
    [self.likeViews addObject:likeView];
    

//    [UIView animateWithDuration:0.3
//                     animations:^{
//                         likeView.alpha = 1.0;
//                     }];
    
//    CGRect frame = likeView.frame;
//    frame.origin.y = (self.frame.size.height - CGRectGetHeight(likeView.frame));
    
//    likeView.delegate = self;
//    [likeView startAnimating];
    
    int degrees = (arc4random() % 90) - 45;
    CGFloat randomRotation = degreesToRadians(degrees);
    
    if(animated) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             likeView.transform = CGAffineTransformMakeScale(2.0, 2.0);
                         } completion:^(BOOL finished) {
                             
                             [UIView animateWithDuration:0.3
                                              animations:^{
                                                  likeView.transform = CGAffineTransformIdentity;
                                                  likeView.transform = CGAffineTransformMakeRotation(randomRotation); //rotation in radians

                                              }];
                             
    //                         likeView.frame = [(CALayer *)likeView.layer.presentationLayer frame];
    //                         likeView.frame = frame;
    //                         NSLog(@"frame: %@", NSStringFromCGRect(likeView.frame));
                             
    //                         NSLog(@"done: %f  %f",  CGRectGetMaxY([(CALayer *)likeView.layer.presentationLayer frame]), self.frame.size.height);

                             
                         }];
    }
    
    _likesCount++;
    _currentLikeIndex++;
    
    if(_likesCount > 100) {
        [[self.likeViews firstObject] removeFromSuperview];
        [self.likeViews removeObjectAtIndex:0];
        self.likesCount--;
    }
}

- (void)removeLike {
    [[self.likeViews lastObject] removeFromSuperview];
    [self.likeViews removeLastObject];
    self.likesCount--;
}

- (BOOL)checkForCollision:(UIView *)viewToCheck {
    
    BOOL didCollide = NO;
        
    if(CGRectGetMaxY([(CALayer *)viewToCheck.layer.presentationLayer frame]) >= (self.frame.size.height - CGRectGetHeight(viewToCheck.frame))) {
        didCollide = YES;
    }
    
//    for(UIView *view in self.likeViews) {
//        
//        NSLog(@"y: %f",  CGRectGetMaxY(viewToCheck.frame));
//        
//        didCollide = CGRectIntersectsRect(view.frame, viewToCheck.frame) || CGRectGetMaxY(viewToCheck.frame) >= self.frame.size.height;
//    }
    
    return didCollide;
}


- (void)displayRandomLikes {
    
    NSInteger totalLikes = _likesCount < 75 ? _likesCount : 75;
    _likesCount = 0;
    for(NSInteger i = 0; i < totalLikes; i++) {
        [self addLikeAnimated:YES];
    }
}

#pragma mark - BGViewLikeDelegate

- (BOOL)shouldKeepAnimating:(BGViewLike *)likeView {
    return ![self checkForCollision:likeView];
}


@end
