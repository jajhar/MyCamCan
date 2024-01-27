#import <Foundation/Foundation.h>

@interface SystemInfo : NSObject

+ (BOOL)iOS6OrGreater;
+ (BOOL)iOS5;
+ (BOOL)iOS7OrGreater;

+ (BOOL)is4Inch;

//+ (float)volume;
//+ (void)setVolume:(float)volume;
//+ (void)setVolumeRememberOriginal:(float)volume;
//+ (void)restoreOriginalVolume;
//+ (void)toggleVolumeOnOff;

@end
