//
//  BGViewLike.m
//  Blog
//
//  Created by James Ajhar on 9/8/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGViewLike.h"


@interface BGViewLike ()

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) NSTimer *timer;

@end


@implementation BGViewLike

- (void)commonInit {
    [super commonInit];
    
    
    
//    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.06
//                                     target:self
//                                   selector:@selector(checkForCollision)
//                                   userInfo:nil
//                                    repeats:YES];
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin |
    UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.imageView];
}

- (void)startAnimating {
//    [self.timer fire];
}

- (void)checkForCollision {
    if(![self.delegate shouldKeepAnimating:self]) {
        [self.layer removeAllAnimations];
        [self.timer invalidate];
    }
}

- (void)setImage:(UIImage *)image {
    [self.imageView setImage:image];
}

@end
