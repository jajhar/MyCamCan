//
//  BGControllerImageCropper.h
//  Blog
//
//  Created by James Ajhar on 9/10/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGController.h"

extern NSString *kBGControllerImageCropper;
extern NSString *kBGKeyImageCropperDelegate;

@protocol BGImageCropperDelegate <NSObject>

@required

- (void)didFinishCroppingImage:(UIImage *)croppedImage;

@end


@interface BGControllerImageCropper : BGController

@property (nonatomic, assign) id delegate;

@end
