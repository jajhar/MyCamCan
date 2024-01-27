#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "GPUImage/GPUImageContext.h"
#import "GPUImage/GPUImageView.h"

typedef void (^GPUImagePictureWriterCallback)(UIImage *,NSError *);

@interface GPUImagePictureWriter : NSObject <GPUImageInput>

// Initialization and teardown
- (id)initWithPictureSize:(CGSize)newSize;

@property(nonatomic) BOOL enabled;

@property(readwrite, nonatomic) GPUImageFillModeType fillMode;

// Picture capturing
- (void)capturePicture:(GPUImagePictureWriterCallback)callback;
- (void)cancelCapture;

@property (assign, atomic, readonly) BOOL isCapturing;

- (void)setPictureSizeAsync:(CGSize)newSize;

@end
