//
//  BGControllerImageCropper.m
//  Blog
//
//  Created by James Ajhar on 9/10/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGControllerImageCropper.h"
#import "RSKImageCropViewController.h"
#import "Media.h"
#import "MBProgressHUD.h"
#import "UIImage+BGFixOrientation.h"

NSString *kBGControllerImageCropper = @"BGControllerImageCropper";
NSString *kBGKeyImageCropperDelegate = @"BGKeyImageCropperDelegate";

@interface BGControllerImageCropper () <RSKImageCropViewControllerDelegate>

@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) RSKImageCropViewController *imageCropVC;
@end


@implementation BGControllerImageCropper


- (void)viewDidLoad {
    [super viewDidLoad];

    self.imageCropVC = [[RSKImageCropViewController alloc] initWithImage:self.image];
    self.imageCropVC.delegate = self;
    self.imageCropVC.view.frame = self.view.bounds;
    [self.view addSubview:self.imageCropVC.view];
    [self addChildViewController:self.imageCropVC];
    [self.imageCropVC didMoveToParentViewController:self];

}

- (void)setInfo:(NSDictionary *)info animated:(BOOL)animated {
    [super setInfo:info animated:animated];
 
    self.image = [info objectForKey:kVXKeyMedia];
    self.delegate = [info objectForKey:kBGKeyImagePickerDelegate];
}


#pragma mark - RSKImageCropViewControllerDelegate

// Crop image has been canceled.
- (void)imageCropViewControllerDidCancelCrop:(RSKImageCropViewController *)controller
{
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [self.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];
    
    [self.navigationController popViewControllerAnimated:NO];
}

// The original image has been cropped.
- (void)imageCropViewController:(RSKImageCropViewController *)controller
                   didCropImage:(UIImage *)croppedImage
                  usingCropRect:(CGRect)cropRect
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    UIImage *compressedImage = [UIImage imageWithImage:croppedImage scaledToSize:CGSizeMake(600.0, 600.0)];
    [self.delegate didFinishCroppingImage:compressedImage];

    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [self.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];
    
    [self.navigationController popViewControllerAnimated:NO];
}

// The original image has been cropped. Additionally provides a rotation angle used to produce image.
- (void)imageCropViewController:(RSKImageCropViewController *)controller
                   didCropImage:(UIImage *)croppedImage
                  usingCropRect:(CGRect)cropRect
                  rotationAngle:(CGFloat)rotationAngle
{
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    UIImage *compressedImage = [UIImage imageWithImage:croppedImage scaledToSize:CGSizeMake(600.0, 600.0)];
    [self.delegate didFinishCroppingImage:compressedImage];
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [self.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];
    
    [self.navigationController popViewControllerAnimated:NO];
}

// The original image will be cropped.
- (void)imageCropViewController:(RSKImageCropViewController *)controller
                  willCropImage:(UIImage *)originalImage
{
    //     Use when `applyMaskToCroppedImage` set to YES.
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}


// Returns a custom rect for the mask.
- (CGRect)imageCropViewControllerCustomMaskRect:(RSKImageCropViewController *)controller
{
    CGSize maskSize;
    if ([controller isPortraitInterfaceOrientation]) {
        maskSize = CGSizeMake(250, 250);
    } else {
        maskSize = CGSizeMake(220, 220);
    }
    
    CGFloat viewWidth = CGRectGetWidth(controller.view.frame);
    CGFloat viewHeight = CGRectGetHeight(controller.view.frame);
    
    CGRect maskRect = CGRectMake((viewWidth - maskSize.width) * 0.5f,
                                 (viewHeight - maskSize.height) * 0.5f,
                                 maskSize.width,
                                 maskSize.height);
    
    return maskRect;
}

// Returns a custom path for the mask.
- (UIBezierPath *)imageCropViewControllerCustomMaskPath:(RSKImageCropViewController *)controller
{
    CGRect rect = controller.maskRect;
    CGPoint point1 = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
    CGPoint point2 = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    CGPoint point3 = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    
    UIBezierPath *triangle = [UIBezierPath bezierPath];
    [triangle moveToPoint:point1];
    [triangle addLineToPoint:point2];
    [triangle addLineToPoint:point3];
    [triangle closePath];
    
    return triangle;
}

// Returns a custom rect in which the image can be moved.
- (CGRect)imageCropViewControllerCustomMovementRect:(RSKImageCropViewController *)controller
{
    // If the image is not rotated, then the movement rect coincides with the mask rect.
    return controller.maskRect;
}

@end
