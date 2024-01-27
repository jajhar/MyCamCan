#import "MediaPlayerView.h"
#import "Media.h"
#import "MBProgressHUD.h"
#import "AppData.h"
#import "NSURL+RefersLocalProperty.h"
#import "BGAVPlayerList.h"
#import <AVFoundation/AVFoundation.h>
#import "DACircularProgressView.h"
#import "MusicItem.h"

/**
 * These constants define MediaPlayerInterface
 */
typedef NS_ENUM(NSUInteger, MediaPlayerInterface) {
    kMediaPlayerInterfaceNone,
    kMediaPlayerInterfacePlayback
};

static __weak MediaPlayerView *_lastActivePlayer = nil;


@interface MediaPlayerView ()

- (void)togglePlay;

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

//L1

- (void)commonInit;

@property (assign, nonatomic) MediaPlayerStatus status;

/**
 * This method is called action to play the media player from start activity
 */
- (void)playInner;
/**
 * This method is called action to play the media player from last active pause
 */
- (void)pauseInner;
/**
 * This method is called action to play the media player from last active resume
 */
- (void)resumeInner;
/**
 * This method is called action to play the media player from last active stop
 */
- (void)stopInner;

/**
 * This method is called action to play the media player when user click the play buton
 */
- (void)playPressed:(UIButton *)button;

@property (assign, nonatomic) MediaPlayerInterface interface;

//control interface
@property (strong, nonatomic) UIButton *playButton;

//presenting interface

@property (strong, nonatomic) AVPlayer *moviePlayer;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
//@property (strong, nonatomic) AVPlayerItem *moviePlayerItem;
@property (strong, nonatomic) MBProgressHUD *loadingIndicator;
@property (strong, nonatomic) DACircularProgressView *progressView;
@property (nonatomic, assign) BOOL isVideoLoaded;
@property (nonatomic, strong) UIView *playButtonBackgroundView;

@end

@implementation MediaPlayerView

#pragma mark L-1
/**
 * This method is called to toggle between play,pause,stop.
 */
- (void)togglePlay {
    switch (self.status) {
        case kMediaPlayerStatusPaused:
            [self resume];
            break;
        case kMediaPlayerStatusIdle:
            [self play];
            break;
        case kMediaPlayerStatusPlaying:
            [self pause];
            break;
        default:
            break;
    }
}

+ (void)pauseLastActivePlayer {
//    MediaPlayerView *strongPlayer = _lastActivePlayer;
//    if (strongPlayer != nil) {
//        [strongPlayer stop];
//        [strongPlayer removeAllObservers];
//        strongPlayer.status = kMediaPlayerStatusIdle;
//    }
//    _lastActivePlayer = nil;
}

- (void)play {
    if (self.status == kMediaPlayerStatusIdle) {
        [self playInner];
    }
}

- (void)pause {
    if (self.status == kMediaPlayerStatusPlaying) {
        [self pauseInner];
    }
}

- (void)resume {
    if (self.status == kMediaPlayerStatusPaused) {
        [self resumeInner];
    }
}

- (void)stop {
    if (self.status == kMediaPlayerStatusPlaying) {
        [self stopInner];
    }
}

#pragma mark L1
/**
 * Proper initialization for MovieSlider, add observers to the view.
 */
- (void)commonInit {
    
    _isVideoLoaded = NO;
    
    // add play button
    self.playButton = [UIButton new];
    [self.playButtonBackgroundView removeFromSuperview];
    self.playButtonBackgroundView = [UIView new];
    self.playButtonBackgroundView.frame = CGRectMake(0, 0, 50, 50);
    self.playButtonBackgroundView.center = self.center;
    self.playButtonBackgroundView.backgroundColor = [UIColor blackColor];
    self.playButtonBackgroundView.alpha = 0.7;
    self.playButtonBackgroundView.clipsToBounds = YES;
    self.playButtonBackgroundView.layer.cornerRadius = 25.0;
    [self addSubview:self.playButtonBackgroundView];
    
    [self.playButton setImage:[[UIImage imageNamed:@"PlayBtn"]
                               imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.playButton setTintColor:[UIColor whiteColor]];
    
    [self.playButton setImage:/*empty image*/[UIImage new] forState:UIControlStateSelected];
    [self.playButton addTarget:self action:@selector(playPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.playButton];
    
    
    // add thumb imageview
    self.imageView = [UIImageView new];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:self.imageView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:_moviePlayer];
    
    [self setupProgressView];
    
    // allows audio playback on movies
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];
}

- (void)setupProgressView {
    [_progressView removeFromSuperview];
    _progressView = nil;
    // setup progress view
    _progressView = [[DACircularProgressView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];
    [_progressView setCenter:self.center];
    _progressView.autoresizingMask = UIViewAutoresizingNone;
    _progressView.roundedCorners = YES;
    _progressView.backgroundColor = [UIColor clearColor];
    [self addSubview:_progressView];
}

/**
 * THis method is callled to add loading indicater to view.
 */
- (void)showLoadingIndicator {
    [self.loadingIndicator show:YES];
}

- (void)setMedia:(Media *)media {
    
    _media = media;
    
    self.status = kMediaPlayerStatusIdle;
    
    // Loading indicator setup
    [self.loadingIndicator removeFromSuperview];
    self.loadingIndicator = [[MBProgressHUD alloc] initWithView:self];
    self.loadingIndicator.color = [UIColor clearColor];
    self.loadingIndicator.activityIndicatorColor = [UIColor whiteColor];
    self.loadingIndicator.opacity = 1.0f;
    self.loadingIndicator.userInteractionEnabled = NO;
    self.loadingIndicator.autoresizingMask = UIViewAutoresizingNone;
    self.loadingIndicator.center = self.center;
    [self addSubview:self.loadingIndicator];
    
    self.moviePlayer = nil;
    self.imageView.hidden = NO;
    [self.imageView setImage:[UIImage new]];
    [self.playerLayer removeFromSuperlayer];
    [self.playButton setImage:[[UIImage imageNamed:@"PlayBtn"]
                               imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.playButtonBackgroundView.hidden = NO;
    
    if (_media.thumbUrl != nil) {
        
//        [self setupProgressView];
        
        __block DACircularProgressView *blockProgressView = self.progressView;
        
        [self.imageView sd_setImageWithURL:self.media.thumbUrl
                          placeholderImage:nil
                                   options:0
                                  progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                                      CGFloat progress = ((CGFloat)receivedSize / (CGFloat)expectedSize);
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          [blockProgressView setProgress:progress animated:NO];
                                      });
                                  } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                      [blockProgressView removeFromSuperview];
                                      blockProgressView = nil;

                                      if(!image || error) {

                                      }
                                      
                                  }];
        
    }
    
    [self layoutSubviews];
}

- (void)playInner {
    // pause previous one
//    [MediaPlayerView pauseLastActivePlayer];
//    [_lastActivePlayer.musicPlayer pause];
    
    [self attemptToPlayMediaWithMusic];

    
    self.status = kMediaPlayerStatusPlaying;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self && self.delegate && [self.delegate respondsToSelector:@selector(mediaPlayerDidBeginPlaying:)]) {
            [self.delegate mediaPlayerDidBeginPlaying:self];
        }
    });
    
//    _lastActivePlayer = self;
    
//    [self.selectorQueue pause];
//    if ((_mediaContent != nil) && (self.status == kMediaPlayerStatusIdle) && !self.mediaContent.isStatic) {
//        [self.mediaContent startForTarget:self callback:^(NSError *error, id assignedInfo) {
//            if (error != nil) {
//                NSLog(@"MediaPlayerController could not start playing");
//            }
//            
//            self.timePlayed = CMTimeGetSeconds(self.moviePlayer.currentTime);
//            
//            [self.selectorQueue resume];
//        }];
//    } else {
//        [self.selectorQueue resume];
//    }
}

- (void)pauseInner {
//    if(self.status == kMediaPlayerStatusPlaying){
        [self.moviePlayer pause];
        self.status = kMediaPlayerStatusPaused;
//    }
}

- (void)resumeInner {
//    [MediaPlayerView pauseLastActivePlayer];
//    _lastActivePlayer = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self && self.delegate && [self.delegate respondsToSelector:@selector(mediaPlayerDidResumePlaying:)]) {
            [self.delegate mediaPlayerDidResumePlaying:self];
        }
    });
}

- (void)stopInner {
    [self stopInner];
}

- (void)attemptToPlayMediaWithMusic {
    
//    switch (_status) {
//        case kMediaPlayerStatusPlaying:
//            break;
//        case kMediaPlayerStatusPaused:
//        case kMediaPlayerStatusIdle:
//            
//        default:
//            break;
//    }
    if(_status != kMediaPlayerStatusPlaying || kMediaPlayerStatusIdle) {
        NSLog(@"Attempted to play with status: %lu", _status);
        return;
    }
    
//    if(_isMusicLoaded && _isVideoLoaded) {
    if(self.moviePlayer.currentItem.playbackLikelyToKeepUp)// &&
//       self.musicPlayer.currentItem.playbackLikelyToKeepUp)
    {
        self.imageView.hidden = YES;

        [self.loadingIndicator hide:NO];
//        [self.musicPlayer play];
        [self.moviePlayer play];
    } else {
//        [self.musicPlayer pause];
        [self.moviePlayer pause];
        [self showLoadingIndicator];
    }
}

- (void)playPressed:(UIButton *)button {
    
    NSLog(@"Play pressed for: %@", _media.theId);
    
//    [self.selectorQueue pause];
//    if ((_mediaContent != nil) && !self.mediaContent.isStatic) {
    

        switch (self.status) {
            case kMediaPlayerStatusIdle: {
                
                [self.playButton setImage:[UIImage new] forState:UIControlStateNormal];
                self.playButtonBackgroundView.hidden = YES;

                self.moviePlayer = [[BGAVPlayerList sharedInstance] playerForURL:self.media.mediaUrl];
                
                if (self.moviePlayer == nil) {
                    self.moviePlayer = [AVPlayer playerWithURL:_media.mediaUrl];
                }
                
                [self.playerLayer removeFromSuperlayer];
                
                _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_moviePlayer];
                _playerLayer.frame = self.bounds;
                _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                self.moviePlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
                
                // add player
                [self.layer addSublayer:self.playerLayer];
                
                [self setNeedsLayout];
                
                [self removeAllObservers];
                [self addVideoObservers];
//                [self addMusicObservers];
                
//                [MediaPlayerView pauseLastActivePlayer];
//                _lastActivePlayer = self;
                
                self.status = kMediaPlayerStatusPlaying;
                
                [self attemptToPlayMediaWithMusic];

                dispatch_async(dispatch_get_main_queue(), ^{
                    if(self && self.delegate && [self.delegate respondsToSelector:@selector(mediaPlayerDidBeginPlaying:)]) {
                        [self.delegate mediaPlayerDidBeginPlaying:self];
                    }
                });
                
//                [self.selectorQueue resume];
                
                break;
            }
            case kMediaPlayerStatusPaused: {
                
                NSLog(@"Resuming from paused...");

                [self.playButton setImage:[UIImage new] forState:UIControlStateNormal];
                self.playButtonBackgroundView.hidden = YES;

//                if(_lastActivePlayer != self) {
//                    [MediaPlayerView pauseLastActivePlayer];
//                    [_lastActivePlayer.musicPlayer pause];
//                    
//                    _lastActivePlayer = self;
//                }
                
                self.status = kMediaPlayerStatusPlaying;
                
                [self attemptToPlayMediaWithMusic];
                
//                self.timePlayed = CMTimeGetSeconds(self.moviePlayer.currentTime);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(self && self.delegate && [self.delegate respondsToSelector:@selector(mediaPlayerDidBeginPlaying:)]) {
                        [self.delegate mediaPlayerDidBeginPlaying:self];
                    }
                });
                
//                [self.selectorQueue resume];
                
                break;
            }
            case kMediaPlayerStatusPlaying: {
                
                NSLog(@"Pausing...");
                
                [self.playButton setImage:[[UIImage imageNamed:@"PlayBtn"]
                                           imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
                self.playButtonBackgroundView.hidden = NO;

                [self.loadingIndicator hide:NO];
                
                [self.moviePlayer pause];
//                [self.musicPlayer pause];
//                [_lastActivePlayer.musicPlayer pause];
                self.status = kMediaPlayerStatusPaused;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(self && self.delegate && [self.delegate respondsToSelector:@selector(mediaPlayerDidBeginPlaying:)]) {
                        [self.delegate mediaPlayerDidPause:self];
                    }
                });
//                self.timePlayed = CMTimeGetSeconds(self.moviePlayer.currentTime);
                
//                [self.selectorQueue resume];
            }
                break;
            default:
                break;
        }
//    } else {
//        [self.selectorQueue resume];
//    }
}

- (void)hidePlayButton:(BOOL)hidden {
    self.playButton.hidden = self.playButtonBackgroundView.hidden = hidden;
}


/**
 *<p>
 *Tell the player to do nothing when it reaches the end of the video
 * It will come back to this method when it's done
 */
- (void) playerItemDidReachEnd: (NSNotification *)notification
{
    
    [self pause];
    
    // Set it back to the beginning
    [_moviePlayer seekToTime: kCMTimeZero];

    [self.playButton setImage:[[UIImage imageNamed:@"PlayBtn"]
                               imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.playButtonBackgroundView.hidden = NO;
    self.imageView.hidden = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self && self.delegate && [self.delegate respondsToSelector:@selector(mediaPlayerDidStopPlaying:)]) {
            [self.delegate mediaPlayerDidStopPlaying:self];
        }
    });
    
//    self.timePlayed = CMTimeGetSeconds(self.moviePlayer.currentTime);
    
    _moviePlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
}

#pragma mark L3

- (void)removePlayerObservers {
    @try{
        [self.moviePlayer.currentItem removeObserver:self forKeyPath:@"status"];
        [self.moviePlayer.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [self.moviePlayer.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        [self.moviePlayer.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];

    }@catch(id anException){
//        NSLog(@"Exception [removePlayerObservers] - Failed to remove status observer");
    }
    
}

- (void)addVideoObservers {
    @try{
        [self.moviePlayer.currentItem addObserver:self forKeyPath:@"status" options:0 context:nil];
        [self.moviePlayer.currentItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:0 context:nil];
        [self.moviePlayer.currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:0 context:nil];
        [self.moviePlayer.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:0 context:nil];
        
    }@catch(id exception) {
        //                    NSLog(@"Exception: Failed to add observers to movie player");
        
        // do nothing
    }
}

- (void)removeAllObservers {
    [self removePlayerObservers];
//    [self removeMusicObservers];
}


#pragma mark L5

@synthesize playButton = _playButton;
@synthesize imageView = _imageView;

#pragma mark - Inherited

#pragma mark NSObject
/**
 * This method is called to deallocate the memory occupaid by the movie player,observers.
 */
- (void)dealloc {
    [self removeAllObservers];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:_moviePlayer];
    
}

#pragma mark NSObject(NSCoding)
/**
 * Returns an object initialized from data in a given unarchiver
 */
- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder]) != nil) {
        [self commonInit];
    }
    return self;
}

#pragma mark UIView
/**
 * Initializes and returns a newly allocated view object with the specified frame rectangle
 */
- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame]) != nil) {
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self commonInit];
}

/**
 * This implementation uses any constraints to determine the size and position of any subviews.
 */
- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageView.frame = self.bounds;
    self.playButton.frame = self.bounds;
    self.playerLayer.frame = self.bounds;
    [_progressView setCenter:self.center];
    [self.loadingIndicator setCenter:self.center];
    
    self.playButtonBackgroundView.center = self.playButton.center;
    [self bringSubviewToFront:self.imageView];
    [self bringSubviewToFront:self.playButtonBackgroundView];
    [self bringSubviewToFront:self.playButton];
    [self bringSubviewToFront:self.loadingIndicator];
}
/**
 * Unlinks the view from its superview and its window, and removes it from the responder chain.
 */
- (void)removeFromSuperview {
    
    [self removeAllObservers];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:_moviePlayer];
    
    
    
    [super removeFromSuperview];
}

#pragma mark - Protocols

- (void)setAspectRatio:(UIViewContentMode)contentMode {
    [UIView animateWithDuration:.3 animations:^{
        self.imageView.contentMode = contentMode;
        
        if(contentMode == UIViewContentModeScaleAspectFill) {
            _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        }else if(contentMode == UIViewContentModeScaleAspectFit) {
            _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        }
    }];
}

#pragma mark - Video Helper Methods


#pragma mark - Observing

/**
 * This message is sent to the receiver when the value at the specified key path relative to the given object has changed.
 */

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //    if(_lastActivePlayer != self) {
    //        return;
    //    }
    
    if ([object isKindOfClass:[AVPlayerItem class]] && (object == self.moviePlayer.currentItem)) //|| object == self.musicPlayer.currentItem))
    {
        AVPlayerItem *item = (AVPlayerItem *)object;
        //playerItem status value changed?
        if ([keyPath isEqualToString:@"status"])
        {   //yes->check it...
            switch(item.status)
            {
                case AVPlayerItemStatusFailed:
                    NSLog(@"player item status failed");
                    break;
                case AVPlayerItemStatusReadyToPlay:
                {
//                    NSLog(@"player item status is ready to play");
                    
                    if(self.status == kMediaPlayerStatusPlaying) {
                        [self attemptToPlayMediaWithMusic];

//                        [self showLoadingIndicator];
                    }
                    
                    break;
                }
                case AVPlayerItemStatusUnknown:
//                    NSLog(@"player item status is unknown");
                    break;
            }
        } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"])
        {
            if (item.playbackLikelyToKeepUp)
            {
//                [self.loadingIndicator hide:NO];

//                if(object == self.musicPlayer.currentItem) {
//                    NSLog(@"music player item likely to keep up");
//                    _isMusicLoaded = YES;
//                } else {
                    NSLog(@"video player item likely to keep up");
                    _isVideoLoaded = YES;
//                }
                
                NSLog(@"attempting to play...");
                //[self.moviePlayer pause];
                [self attemptToPlayMediaWithMusic];

//                    [self play];
            } else {
                NSLog(@"buffering...");
                [self attemptToPlayMediaWithMusic];

            }
        } else if([keyPath isEqualToString:@"playbackBufferEmpty"]) {
            if (item.playbackBufferEmpty)
            {
                NSLog(@"player item playback buffer is empty");
            } else {
                NSLog(@"buffering...");

                if(self.status == kMediaPlayerStatusPlaying) {
                    [self attemptToPlayMediaWithMusic];
                }
            }
        } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
            
            if(object == self.moviePlayer.currentItem) {
                // loaded time ranges
//                [self.movieSlider setBufferValue:([self moviebufferDuration] / CMTimeGetSeconds(self.moviePlayer.currentItem.duration))];
            }
            
        }
    }
    [self layoutSubviews];
}

@end
