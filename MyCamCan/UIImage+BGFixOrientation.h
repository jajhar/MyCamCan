/**
* UIImage+BGFixOrientation.h
*  MCC
* @author  James Ajhar
* @since  10/21/14.
*  Copyright (c) 2014 D9. All rights reserved.
*/

#import <UIKit/UIKit.h>

@interface UIImage (BGFixOrientation)


- (UIImage *)fixOrientation;

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

@end
