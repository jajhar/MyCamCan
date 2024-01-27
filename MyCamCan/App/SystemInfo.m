#import "SystemInfo.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation SystemInfo

static BOOL iOS6OrGreater;
static BOOL iOS5;
static BOOL iOS7OrGreater;

+ (BOOL)iOS6OrGreater {
    return iOS6OrGreater;
}

+ (BOOL)iOS5 {
    return iOS5;
}

+ (BOOL)iOS7OrGreater {
    return iOS7OrGreater;
}

+ (BOOL)is4Inch {
    return ([UIScreen mainScreen].scale >= 1.9f && [UIScreen mainScreen].bounds.size.height >= 567.0f);
}

+ (void)initialize {
    //this not going to change during runtime
    iOS7OrGreater = ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7);
    iOS6OrGreater = ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6);
    iOS5 = ([[[UIDevice currentDevice] systemVersion] floatValue] == 5);
}

//static float OriginalVolume = 0.5;

//+ (float)volume {
//	return [MPMusicPlayerController applicationMusicPlayer].volume;
//}
//
//+ (void)setVolume:(float)volume {
//	[MPMusicPlayerController applicationMusicPlayer].volume = volume;
//}
//
//+ (void)setVolumeRememberOriginal:(float)volume {
//	OriginalVolume = [self volume];
//	[self setVolume:volume];
//}
//
//+ (void)restoreOriginalVolume {
//	[MPMusicPlayerController applicationMusicPlayer].volume = OriginalVolume;
//}
//
//+ (void)toggleVolumeOnOff {
//	float volume = [self volume];
//	if (volume == 0.0) {
//		[self restoreOriginalVolume];
//	} else {
//		[self setVolumeRememberOriginal:0.0];
//	}
//}

@end
