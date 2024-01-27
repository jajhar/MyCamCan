//
//  BGControllerMusicTrim.m
//  Blog
//
//  Created by James Ajhar on 2/3/16.
//  Copyright © 2016 James Ajhar. All rights reserved.
//

#import "BGControllerMusicTrim.h"
#import <AVFoundation/AVFoundation.h>
#import "VisualizerView.h"
#import "MusicItem.h"
#import "SAMultiSectorControl.h"
#import "MBProgressHUD.h"
#import "BGControllerCamera.h"

@interface BGControllerMusicTrim ()
{
    CGFloat _currentSelectedStartTrimValue;
    CGFloat _currentSelectedEndTrimValue;
    CGFloat _audioDuration;
    NSTimer *_audioPlaybackTimer;
}

#define MIN_MUSIC_DURATION 9
#define MAX_MUSIC_DURATION 30

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIView *playButtonBackgroundView;
@property (weak, nonatomic) IBOutlet SAMultisectorControl *multisectorControl;
@property (weak, nonatomic) IBOutlet UILabel *totalSecondsLabel;
@property (weak, nonatomic) IBOutlet UIButton *ambientSoundButton;
@property (weak, nonatomic) IBOutlet UIStackView *ambientSoundPromptStackView;

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) VisualizerView *visualizer;
@property (strong, nonatomic) MusicItem *musicItem;

@end

@implementation BGControllerMusicTrim

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Trim Clip";

    // add next button to nav bar
    UIButton *nextButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    [nextButton setTitle:@"next" forState:UIControlStateNormal];
    [nextButton addTarget:self action:@selector(nextPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:nextButton];
    
    [self configureAudioSession];
    
    _currentSelectedStartTrimValue = 0.0;
    _currentSelectedEndTrimValue = 0.0;

    self.visualizer = [[VisualizerView alloc] initWithFrame:self.view.frame];
    [_visualizer setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
//    _visualizer.alpha = 0.0;
    [self.visualizer setupWithBirthRate:60.0 lifeTime:1.0 colorPallete:[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.8f] image: nil];
    [self.view addSubview:_visualizer];
    
    CGRect sliderFrame = CGRectMake(0, 0, 250, 250);

    UIImageView *imageView = [[UIImageView alloc] initWithFrame:sliderFrame];
    
    if(self.musicItem.artwork != nil) {
        [imageView setImage:self.musicItem.artwork];
    } else {
        __block BGControllerMusicTrim *blockSelf = self;
        [imageView sd_setImageWithURL:self.musicItem.imageURLHighResolution placeholderImage:[UIImage imageNamed:@"generic-music"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if(!image || error) {

                [imageView sd_setImageWithURL:blockSelf.musicItem.imageURL completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                    if (!image || error) {
                        imageView.image = [UIImage imageNamed:@"generic-music"];
                    }
                }];
            }
        }];
    }
    
    self.playButtonBackgroundView.layer.cornerRadius = CGRectGetWidth(self.playButtonBackgroundView.frame) / 2.0;
    
    imageView.center = self.view.center;
    imageView.clipsToBounds = YES;
    imageView.layer.cornerRadius = sliderFrame.size.width / 2.0;
    [imageView setBackgroundColor:[UIColor blackColor]];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:imageView];
    
    [self.view bringSubviewToFront:self.multisectorControl];
    [self.view bringSubviewToFront:self.playButtonBackgroundView];
    [self.view bringSubviewToFront:self.playButton];
    [self.view bringSubviewToFront:self.totalSecondsLabel];
    [self.view bringSubviewToFront:self.ambientSoundPromptStackView];

    [self configureAudioPlayer];
    [_visualizer startVisualizing];
  
    [self setupMultisectorControl];
    
    _audioPlaybackTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                                 target:self
                                                               selector:@selector(checkPlaybackTime:)
                                                               userInfo:nil
                                                                repeats:YES];
}

- (void)dealloc {
    [_audioPlayer stop];
    [_audioPlaybackTimer invalidate];
    _audioPlaybackTimer = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [_audioPlayer stop];
    [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
}

- (void)setInfo:(NSDictionary *)info animated:(BOOL)animated {
    [super setInfo:info animated:animated];
    
    self.musicItem = [info objectForKey:kBGInfoMusicItem];
}

- (void)setupMultisectorControl{
    
    NSError *error = nil;
    AVAudioPlayer* avAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.musicItem.localFileURL error:&error];
    _audioDuration = round(avAudioPlayer.duration);
    avAudioPlayer = nil;
    
    [self.multisectorControl addTarget:self action:@selector(multisectorValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.multisectorControl removeAllSectors];
    
    UIColor *redColor = [UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1.0];
    
    NSLog(@"duration of audio: %f", _audioDuration);
    
    SAMultisectorSector *sector = [SAMultisectorSector sectorWithColor:redColor maxValue:_audioDuration];
    sector.endValue = MIN_MUSIC_DURATION;
    [self.multisectorControl addSector:sector];
    self.multisectorControl.sectorsRadius = 125.0;
    self.multisectorControl.maxCircleMarkerRadius = 50.0;
    self.multisectorControl.minCircleMarkerRadius = 50.0;

    [self updateDataView];
}

- (void)multisectorValueChanged:(id)sender{
    [self updateDataView];
}

- (void)updateDataView{
    for(SAMultisectorSector *sector in self.multisectorControl.sectors){
        
        if((sector.endValue - sector.startValue) < MIN_MUSIC_DURATION) {
            
            if(self.multisectorControl.trackingSectorStartMarker) {
                sector.endValue = sector.startValue + MIN_MUSIC_DURATION;
            } else {
                sector.startValue = sector.endValue - MIN_MUSIC_DURATION;
            }
            
            if(sector.startValue <= 0) {
                sector.startValue = 0;
                sector.endValue = MIN_MUSIC_DURATION;
            }
            
        }
        
        // Wrap around the circle
        if((sector.startValue + MIN_MUSIC_DURATION) >= _audioDuration) {
            sector.startValue = _audioDuration - MIN_MUSIC_DURATION;
            sector.endValue = _audioDuration;
        }
        
        if((sector.endValue - sector.startValue) > MAX_MUSIC_DURATION) {
            if(self.multisectorControl.trackingSectorStartMarker) {
                sector.endValue = sector.startValue + MAX_MUSIC_DURATION;
            } else {
                sector.startValue = sector.endValue - MAX_MUSIC_DURATION;
            }
        }
        
        int startSeconds = (int)sector.startValue;
        int endSeconds = (int)sector.endValue;
        
        NSString *startText = [NSString stringWithFormat:@"%d", startSeconds];
        NSString *endText = [NSString stringWithFormat:@"%d", endSeconds];
        
        self.multisectorControl.startText = startText;
        self.multisectorControl.endText = endText;
        
        self.totalSecondsLabel.text = [NSString stringWithFormat:@"%d seconds", (endSeconds - startSeconds)];

        _currentSelectedStartTrimValue = sector.startValue;
        _currentSelectedEndTrimValue = sector.endValue;
        
        [self.view layoutIfNeeded];
    }
}


#pragma mark - Interface Actions

- (IBAction)playButtonPressed:(id)sender {
    if(_audioPlayer.isPlaying) {
        
//        [UIView animateWithDuration:.3
//                         animations:^{
//                             _visualizer.alpha = 0.0;
//                         }];
        
        [_audioPlayer pause];
//        [_visualizer stopVisualizing];
        
    } else {
        
//        [UIView animateWithDuration:.3
//                         animations:^{
//                             _visualizer.alpha = 1.0;
//                         }];
        
        [_audioPlayer setCurrentTime:_currentSelectedStartTrimValue];
        [_audioPlayer play];
    }
}

- (IBAction)nextPressed:(id)sender {
    
    self.musicItem.startTime = _currentSelectedStartTrimValue;
    self.musicItem.endTime = _currentSelectedEndTrimValue;
    
    [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];

    [[AppData sharedInstance].navigationManager presentControllerForPurpose:kBGPurposeCamera
                                                                       info:@{
                                                                              kBGInfoMusicItem: self.musicItem,
                                                                              kBGInfoCameraAmbientSoundFlag: [NSNumber numberWithBool:self.ambientSoundButton.isSelected]
                                                                              }
                                                                 showTabBar:NO];
}

- (IBAction)recordAmbientSoundButtonPressed:(UIButton *)sender {
    
    [sender setSelected:!sender.selected];
    
    
}

#pragma mark - Audio Configuration

- (void)configureAudioPlayer {
    NSError *error;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.musicItem.localFileURL error:&error];
    if (error) {
        NSLog(@"Error configuring audio player: %@", [error localizedDescription]);
    }
    [_audioPlayer setNumberOfLoops:0];
    [_audioPlayer setMeteringEnabled:YES];
    [_visualizer setAudioPlayer:_audioPlayer];
}

- (void)configureAudioSession {
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    
    if (error) {
        NSLog(@"Error setting category: %@", [error description]);
    }
}

- (void) checkPlaybackTime:(NSTimer *)theTimer {
    CGFloat seconds = _audioPlayer.currentTime;
    
    if (seconds >= _currentSelectedEndTrimValue) {
        [_audioPlayer stop];
    }
}

@end
