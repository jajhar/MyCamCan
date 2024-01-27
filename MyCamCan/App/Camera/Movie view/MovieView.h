#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@class MovieView;

@protocol MovieViewDelegate <NSObject>

- (void)movieView:(MovieView *)movieView changedPlaybackStateTo:(MPMoviePlaybackState)state;

- (void)movieViewWillTogglePlay:(MovieView *)movieView play:(BOOL)play;

@end

@interface MovieView : UIButton <MPMediaPlayback>

@property (weak, nonatomic) id<MovieViewDelegate> delegate;
//@property (assign, nonatomic) CGRect viewFrame;
@property (strong, nonatomic, readonly) CGImageRef thumb __attribute__((NSObject));
@property (strong, nonatomic) NSURL *contentURL;
@property (strong, nonatomic, readonly) MPMoviePlayerController *moviePlayerController;
@property (assign, nonatomic) BOOL showLoadingAnimation;
@property (assign, nonatomic) BOOL shouldAutoplay;

- (void)setThumbCG:(CGImageRef)thumb animated:(BOOL)animated;

@end


//	setIsPlaying
//self.playbackButton.enabled = NO;

//if expanded
//self.playbackButton.hidden = NO;
//BOOL canTogglePlayback = ((self.savedVideoUrl != nil) && (self.loadingError == nil) && self.isExpanded);
//self.playbackButton.enabled = canTogglePlayback;
