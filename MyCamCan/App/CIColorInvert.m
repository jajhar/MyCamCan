//
//  CIColorInvert.m
//  Blog
//
//  Created by James Ajhar on 3/15/17.
//  Copyright © 2017 James Ajhar. All rights reserved.
//

#import "CIColorInvert.h"

@implementation CIColorInvert

@synthesize inputImage;

- (CIImage *) outputImage

{
    
    CIFilter *filter = [CIFilter filterWithName:@"CIColorMatrix"
                        
                            withInputParameters: @{
                                                   
                                                   kCIInputImageKey: inputImage,
                                                   
                                                   @"inputRVector": [CIVector vectorWithX:-1 Y:0 Z:0],
                                                   
                                                   @"inputGVector": [CIVector vectorWithX:0 Y:-1 Z:0],
                                                   
                                                   @"inputBVector": [CIVector vectorWithX:0 Y:0 Z:-1],
                                                   
                                                   @"inputBiasVector": [CIVector vectorWithX:1 Y:1 Z:1],
                                                   
                                                   }];
    
    return filter.outputImage;
    
}

@end
