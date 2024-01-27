/**
 *  BGViewMovieSlider.h
 * MCC
 * @author James Ajhar
 *@since 12/3/14.
 * Copyright (c) 2014 D9. All rights reserved.
 */

#import "BGView.h"

@class BGViewMovieSlider;

@protocol BGViewMovieSliderDelegate <NSObject>

/**
 * This method is called to make the slider active
 */
- (void)sliderBecameActive:(BGViewMovieSlider *)movieSlider;
/**
 * This button action makes the slider inactive
 */
- (void)sliderBecameInactive:(BGViewMovieSlider *)movieSlider;
/**
 * This button action helps to silde on the screen to change the run time of
 */
- (void)sliderValueChanged:(BGViewMovieSlider *)movieSlider value:(CGFloat)newValue;

@end

@interface BGViewMovieSlider : BGView

@property (nonatomic, assign) id delegate;

- (void)setMinimumValue:(CGFloat)value;
- (void)setMaximumValue:(CGFloat)value;
- (void)setTimePlayed:(CGFloat)timePlayed animated:(BOOL)animated;
- (void)setBufferValue:(CGFloat)buffered;

@end
