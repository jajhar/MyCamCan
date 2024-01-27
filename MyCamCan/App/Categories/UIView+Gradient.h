//
//  UIView+Gradient.h
//  Blog
//
//  Created by James Ajhar on 1/20/16.
//  Copyright © 2016 James Ajhar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Gradient)

+ (void)addLinearGradientToView:(UIView *)theView withColor:(UIColor *)theColor transparentToOpaque:(BOOL)transparentToOpaque;

@end
