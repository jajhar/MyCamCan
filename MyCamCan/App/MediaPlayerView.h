#import <UIKit/UIKit.h>
/**
 * These constants define MediaPlayerStatus
 */
typedef NS_ENUM(NSUInteger, MediaPlayerStatus) {
    kMediaPlayerStatusIdle,
    kMediaPlayerStatusPlaying,
    kMediaPlayerStatusPaused
};

@class Media;
@class MediaPlayerView;

@protocol BGMediaPlayerViewDelegate <NSObject>

@optional
/**
 * This method is called action to when media player is begin play
 */
- (void)mediaPlayerDidBeginPlaying:(MediaPlayerView *)mediaPlayer;
/**
 * This method is called action to when media player is pause
 */
- (void)mediaPlayerDidPause:(MediaPlayerView *)mediaPlayer;
/**
 * This method is called action to when player is resume
 */
- (void)mediaPlayerDidResumePlaying:(MediaPlayerView *)mediaPlayer;
/**
 * This method is called action to when player is stop
 */
- (void)mediaPlayerDidStopPlaying:(MediaPlayerView *)mediaPlayer;

@end

@interface MediaPlayerView : UIView

- (void)togglePlay;
- (void)removeAllObservers;
- (void)setAspectRatio:(UIViewContentMode)contentMode;
- (void)hidePlayButton:(BOOL)hidden;

@property (nonatomic, assign, readonly) MediaPlayerStatus status;
@property (strong, nonatomic) UIImageView *imageView;

@property (nonatomic, strong) Media *media;

@property (nonatomic, assign) id delegate;

@property (nonatomic, assign) BOOL repeat;
@property (nonatomic, assign) BOOL mute;
/**
 * This method is called action to play the media player when user want
 */
- (void)play;
/**
 * This method is called action to pause the media player when user want
 */
- (void)pause;
/**
 * This method is called action to resume the media player when user want
 */
- (void)resume;
/**
 * This method is called action to stop the media player when user want
 */
- (void)stop;
/**
 * This method is called action to pause the last active in player
 */
+ (void)pauseLastActivePlayer;

@end
