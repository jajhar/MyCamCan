#import "GPUImagePictureWriter.h"

#import "GPUImage/GPUImageOutput.h"
#import "GPUImage/GPUImageFilter.h"
#import "GPUImage/GPUImageMovieWriter.h"

@interface GPUImagePictureWriter () {
    CVOpenGLESTextureCacheRef coreVideoTextureCache;
    CVPixelBufferRef renderTarget;
    CVOpenGLESTextureRef renderTexture;

    CGSize pictureSize;
    GPUImageRotationMode inputRotation;

//    __unsafe_unretained id<GPUImageTextureDelegate> textureDelegate;

    GLuint pictureFramebuffer, pictureRenderbuffer;

    GLProgram *passthroughProgram;
    GLint colorSwizzlingPositionAttribute, colorSwizzlingTextureCoordinateAttribute;
    GLint colorSwizzlingInputTextureUniform;

    GLuint inputTextureForPictureRendering;

    CMTime startTime, previousFrameTime;

	CGSize inputImageSize;
    GLfloat imageVertices[8];
}

@property(nonatomic, strong) GPUImagePictureWriterCallback pictureReadyCallback;

// Initialization and teardown
- (id)initWithPictureSize:(CGSize)newSize;

// Frame rendering
- (void)createDataFBO;
- (void)destroyDataFBO;
- (void)setFilterFBO;

- (void)renderAtInternalSize;

// Handling fill mode
- (void)recalculateViewGeometry;

@end

@implementation GPUImagePictureWriter

@synthesize pictureReadyCallback = _pictureReadyCallback;
@synthesize enabled = _enabled;

- (void)capturePicture:(GPUImagePictureWriterCallback)callback {
    if (self.enabled) {
        runAsynchronouslyOnVideoProcessingQueue(^{
            if (!_isCapturing) {
                _isCapturing = YES;
                self.pictureReadyCallback = callback;
            }
        });
    }
}

- (void)cancelCapture {
    if (_isCapturing) {
        runAsynchronouslyOnVideoProcessingQueue(^{
            if (_isCapturing) {
                _isCapturing = NO;
                self.pictureReadyCallback = NULL;
            }
        });
    }
}

@synthesize isCapturing = _isCapturing;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithPictureSize:(CGSize)newSize {
    if (!(self = [super init]))
    {
		return nil;
    }

    pictureSize = newSize;
    startTime = kCMTimeInvalid;
    previousFrameTime = kCMTimeNegativeInfinity;
    inputRotation = kGPUImageNoRotation;

    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];

        if ([GPUImageContext supportsFastTextureUpload])
        {
            passthroughProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImagePassthroughFragmentShaderString];
        }
        else
        {
            passthroughProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImageColorSwizzlingFragmentShaderString];
        }

        if (!passthroughProgram.initialized)
        {
            [passthroughProgram addAttribute:@"position"];
            [passthroughProgram addAttribute:@"inputTextureCoordinate"];

            if (![passthroughProgram link])
            {
                NSString *progLog = [passthroughProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [passthroughProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [passthroughProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                passthroughProgram = nil;
                NSAssert(NO, @"Filter shader link failed");
            }
        }

        colorSwizzlingPositionAttribute = [passthroughProgram attributeIndex:@"position"];
        colorSwizzlingTextureCoordinateAttribute = [passthroughProgram attributeIndex:@"inputTextureCoordinate"];
        colorSwizzlingInputTextureUniform = [passthroughProgram uniformIndex:@"inputImageTexture"];

        // REFACTOR: Wrap this in a block for the image processing queue
        [GPUImageContext setActiveShaderProgram:passthroughProgram];

        glEnableVertexAttribArray(colorSwizzlingPositionAttribute);
        glEnableVertexAttribArray(colorSwizzlingTextureCoordinateAttribute);
    });

    self.enabled = YES;

    return self;
}

- (void)setPictureSizeAsync:(CGSize)newSize
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [self destroyDataFBO];
        pictureSize = newSize;
        [self recalculateViewGeometry];
    });
}

- (void)dealloc;
{
    [self destroyDataFBO];
}

#pragma mark -
#pragma mark Accessors


@synthesize fillMode = _fillMode;

- (void)setFillMode:(GPUImageFillModeType)newValue;
{
    _fillMode = newValue;
    [self recalculateViewGeometry];
}

#pragma mark -
#pragma mark Frame rendering

- (void)createDataFBO {
    glActiveTexture(GL_TEXTURE1);
    glGenFramebuffers(1, &pictureFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, pictureFramebuffer);

    if ([GPUImageContext supportsFastTextureUpload])
    {
#if defined(__IPHONE_6_0)
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [[GPUImageContext sharedImageProcessingContext] context], NULL, &coreVideoTextureCache);
#else
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[[GPUImageContext sharedImageProcessingContext] context], NULL, &coreVideoTextureCache);
#endif

        if (err)
        {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
        }

        // Code originally sourced from http://allmybrain.com/2011/12/08/rendering-to-a-texture-with-ios-5-texture-cache-api/

        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                                 [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                                 [NSNumber numberWithBool:YES], kCVPixelBufferOpenGLCompatibilityKey,
                                 [NSDictionary dictionary], kCVPixelBufferIOSurfacePropertiesKey,
                                 nil];

        CVPixelBufferCreate(NULL,
                            pictureSize.width,
                            pictureSize.height,
                            kCVPixelFormatType_32BGRA,
                            (__bridge CFDictionaryRef)(options),
                            &renderTarget);

        CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault,
                                                      coreVideoTextureCache,
                                                      renderTarget,
                                                      NULL, // texture attributes
                                                      GL_TEXTURE_2D,
                                                      GL_RGBA, // opengl format
                                                      (int)pictureSize.width,
                                                      (int)pictureSize.height,
// native iOS format is GL_BGRA, but we making it reverse to RGBA cause we want to produce image with it, not processing live video
                                                      GL_RGBA,
                                                      GL_UNSIGNED_BYTE,
                                                      0,
                                                      &renderTexture);

        glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
    }
    else
    {
        glGenRenderbuffers(1, &pictureRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, pictureRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, (int)pictureSize.width, (int)pictureSize.height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, pictureRenderbuffer);
    }


	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);

    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
}

- (void)destroyDataFBO;
{
    [GPUImageContext useImageProcessingContext];

    if (pictureFramebuffer)
	{
		glDeleteFramebuffers(1, &pictureFramebuffer);
		pictureFramebuffer = 0;
	}

    if (pictureRenderbuffer)
	{
		glDeleteRenderbuffers(1, &pictureRenderbuffer);
		pictureRenderbuffer = 0;
	}

    if ([GPUImageContext supportsFastTextureUpload])
    {
        if (coreVideoTextureCache)
        {
           // CFRelease(coreVideoTextureCache);
        }

        if (renderTexture)
        {
            //CFRelease(renderTexture);
        }
        if (renderTarget)
        {
            //CVPixelBufferRelease(renderTarget);
        }

    }
}

- (void)setFilterFBO;
{
    if (!pictureFramebuffer)
    {
        [self createDataFBO];
    }

    glBindFramebuffer(GL_FRAMEBUFFER, pictureFramebuffer);

    glViewport(0, 0, (int)pictureSize.width, (int)pictureSize.height);
}

- (void)renderAtInternalSize;
{
    [GPUImageContext useImageProcessingContext];
    [self setFilterFBO];

    [GPUImageContext setActiveShaderProgram:passthroughProgram];

    glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    static const GLfloat textureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };

	glActiveTexture(GL_TEXTURE4);
	glBindTexture(GL_TEXTURE_2D, inputTextureForPictureRendering);
	glUniform1i(colorSwizzlingInputTextureUniform, 4);

    glVertexAttribPointer(colorSwizzlingPositionAttribute, 2, GL_FLOAT, 0, 0, imageVertices);
	glVertexAttribPointer(colorSwizzlingTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glFinish();
}

#pragma mark -
#pragma mark Handling fill mode

- (void)recalculateViewGeometry;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        CGFloat heightScaling, widthScaling;

        CGSize currentViewSize = pictureSize;

        //    CGFloat imageAspectRatio = inputImageSize.width / inputImageSize.height;
        //    CGFloat viewAspectRatio = currentViewSize.width / currentViewSize.height;

        CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(inputImageSize, CGRectMake(0.0, 0.0, currentViewSize.width, currentViewSize.height));

        switch(_fillMode)
        {
            case kGPUImageFillModeStretch:
            {
                widthScaling = 1.0;
                heightScaling = 1.0;
            }; break;
            case kGPUImageFillModePreserveAspectRatio:
            {
                widthScaling = insetRect.size.width / currentViewSize.width;
                heightScaling = insetRect.size.height / currentViewSize.height;
            }; break;
            case kGPUImageFillModePreserveAspectRatioAndFill:
            {
                //            CGFloat widthHolder = insetRect.size.width / currentViewSize.width;
                widthScaling = currentViewSize.height / insetRect.size.height;
                heightScaling = currentViewSize.width / insetRect.size.width;
            }; break;
        }

//        GPUImageVerticesCompensatingRotation(imageVertices,inputRotation,widthScaling,heightScaling);
    });
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    if (!_isCapturing)
    {
        return;
    }

    // Drop frames forced by images and other things with no time constants
    // Also, if two consecutive times with the same value are added to the movie, it aborts recording, so I bail on that case
    if ( (CMTIME_IS_INVALID(frameTime)) || (CMTIME_COMPARE_INLINE(frameTime, ==, previousFrameTime)) || (CMTIME_IS_INDEFINITE(frameTime)) )
    {
        return;
    }

    _isCapturing = NO;

    if (CMTIME_IS_INVALID(startTime))
    {
        startTime = frameTime;
    }

    // Render the frame with swizzled colors, so that they can be uploaded quickly as BGRA frames
    [self renderAtInternalSize];

    CVPixelBufferRef pixel_buffer = renderTarget;

    CVPixelBufferLockBaseAddress(pixel_buffer, kCVPixelBufferLock_ReadOnly);

    if (![GPUImageContext supportsFastTextureUpload])
    {
        GLubyte *pixelBufferData = (GLubyte *)CVPixelBufferGetBaseAddress(pixel_buffer);
        glReadPixels(0, 0, pictureSize.width, pictureSize.height, GL_RGBA, GL_UNSIGNED_BYTE, pixelBufferData);
    }

    size_t width = CVPixelBufferGetWidth(pixel_buffer);
    size_t height = CVPixelBufferGetHeight(pixel_buffer);
    CFDataRef data = CFDataCreate(NULL, CVPixelBufferGetBaseAddress(pixel_buffer), width*height*4);
    CVPixelBufferUnlockBaseAddress(pixel_buffer, kCVPixelBufferLock_ReadOnly);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CFRelease(data);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef image = CGImageCreate(width,
                                     height,
                                     8,
                                     32,
                                     CVPixelBufferGetBytesPerRow(pixel_buffer),
                                     colorSpace,
                                     kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast,
                                     provider,
                                     NULL,
                                     NO,
                                     kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);

    if (self.pictureReadyCallback != NULL) {
        UIImage *uiImage = [UIImage imageWithCGImage:image];
//        CGImageRelease(image);
        self.pictureReadyCallback(uiImage,nil);
        self.pictureReadyCallback = NULL;
    }
    CGImageRelease(image);

    previousFrameTime = frameTime;
}

- (NSInteger)nextAvailableTextureIndex;
{
    return 0;
}

- (void)setInputTexture:(GLuint)newInputTexture atIndex:(NSInteger)textureIndex;
{
    inputTextureForPictureRendering = newInputTexture;
}

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    if (inputRotation != newInputRotation) {
        inputRotation = newInputRotation;
        [self recalculateViewGeometry];
    }
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
	runSynchronouslyOnVideoProcessingQueue(^{
        CGSize rotatedSize = newSize;

        if (GPUImageRotationSwapsWidthAndHeight(inputRotation))
        {
            rotatedSize.width = newSize.height;
            rotatedSize.height = newSize.width;
        }

        if (!CGSizeEqualToSize(inputImageSize, rotatedSize))
        {
            inputImageSize = rotatedSize;
            [self recalculateViewGeometry];
        }
    });
}

- (CGSize)maximumOutputSize;
{
    return pictureSize;
}

- (void)endProcessing
{
    [self cancelCapture];
}

- (BOOL)shouldIgnoreUpdatesToThisTarget;
{
    return NO;
}

//- (void)setTextureDelegate:(id<GPUImageTextureDelegate>)newTextureDelegate atIndex:(NSInteger)textureIndex;
//{
//    textureDelegate = newTextureDelegate;
//}

- (void)conserveMemoryForNextFrame;
{

}

- (BOOL)wantsMonochromeInput;
{
    return NO;
}

- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue;
{

}

@end
