//
//  VisualizerView.h
//  iPodVisualizer
//
//  Created by Xinrong Guo on 13-3-30.
//  Copyright (c) 2013 Xinrong Guo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface VisualizerView : UIView

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

- (void)startVisualizing;
- (void)stopVisualizing;

- (void)setBirthRate:(CGFloat)birthRate;
- (void)setLifetime:(CGFloat)lifetime;
- (void)setupWithBirthRate:(CGFloat)birthRate lifeTime:(CGFloat)lifetime colorPallete:(UIColor *)colorPallete image:(UIImage *)image;

@end