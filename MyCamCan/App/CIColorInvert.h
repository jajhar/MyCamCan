//
//  CIColorInvert.h
//  Blog
//
//  Created by James Ajhar on 3/15/17.
//  Copyright © 2017 James Ajhar. All rights reserved.
//

#import <CoreImage/CoreImage.h>

@interface CIColorInvert: CIFilter {
    
    CIImage *inputImage;
    
}

@property (retain, nonatomic) CIImage *inputImage;

@end
