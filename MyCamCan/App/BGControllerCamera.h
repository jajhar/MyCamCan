//
//  BGControllerCamera.h
//  Blog
//
//  Created by James Ajhar on 6/3/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRecorder.h"


extern NSString *kBGControllerCamera;
extern NSString *kBGInfoCameraAmbientSoundFlag;

@interface BGControllerCamera : BGController <SCRecorderDelegate, UIImagePickerControllerDelegate, SCAssetExportSessionDelegate>

@property (nonatomic, assign) BOOL recordAmbientSound;

@end
