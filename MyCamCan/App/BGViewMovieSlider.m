/**
*  BGViewMovieSlider.m
* MCC
* @author James Ajhar 
*@since 12/3/14.
* Copyright (c) 2014 D9. All rights reserved.
*/

#import "BGViewMovieSlider.h"



@interface BGViewMovieSlider ()

@property (strong, nonatomic) IBOutlet UIProgressView *bufferProgressView;
@property (strong, nonatomic) IBOutlet UISlider *movieSlider;
@property (strong, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (strong, nonatomic) IBOutlet UILabel *endTimeLabel;

@end


@implementation BGViewMovieSlider
/**
* This method is called to initiates movie slider, add tapGestureRecognizer to the slider.
 */
- (void)commonInit {
    [super commonInit];

    [_movieSlider setMaximumTrackImage:[UIImage new] forState:UIControlStateNormal];

    [self.movieSlider addTarget:self action:@selector(sliderBecameActive:) forControlEvents:UIControlEventTouchDown];

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderTapped:)];
    [self.movieSlider addGestureRecognizer:tapGestureRecognizer];
}

/**
 *<p>
 * We do this to absorb taps using the uislider even if we are not doing anything with them. otherwise taps will pass right
 *through.
 */
- (void)sliderTapped:(UIGestureRecognizer *)gestureRecognizer {
    // do nothing
}

/**
* <p>
* This method is called to set the minimum value of the silder
* If you change the value of this property, and the current value of the receiver is below the new minimum, the current
* value is adjusted to match the new minimum value automatically.
 */
- (void)setMinimumValue:(CGFloat)value {
    [self.movieSlider setMinimumValue:value];
}
/**
 * <p>
 * This method is called to set the maximum value of the silder
 * If you change the value of this property, and the current value of the receiver is above the new maximum, the current
 * value is adjusted to match the new maximum value automatically.
 */
- (void)setMaximumValue:(CGFloat)value {
    [self.movieSlider setMaximumValue:value];
    [self.endTimeLabel setText:[self timeFormatted:value]];
}

/**
 * This method sets the time at which the slider began playing in CGFloat (seconds)
 */
- (void)setTimePlayed:(CGFloat)timePlayed animated:(BOOL)animated {
    [self.movieSlider setValue:timePlayed animated:animated];
    [self updateCurrentTime:timePlayed];
}

/**
 * This method sets the amount of the video that has been buffered so far in CGFloat (seconds)
 */
- (void)setBufferValue:(CGFloat)buffered {
    [self.bufferProgressView setProgress:buffered animated:YES];
}

/**
* Label updates the current play time of the video.
 */
- (void)updateCurrentTime:(CGFloat)value {
    self.currentTimeLabel.text = [self timeFormatted:(int)value];
}

#pragma mark - delegate methods

/**
* This method is called to add delegate to slider to become active.
 */
- (void)sliderBecameActive:(id)sender {
    [self.delegate sliderBecameActive:self];
}

/**
 * This button action makes the slider to become active.
 */
- (IBAction)sliderBecameInactive:(id)sender {
    [self.delegate sliderBecameInactive:self];
}

/**
 * This button action changes the value of the slider.
 */
- (IBAction)sliderValueChanged:(id)sender {
    [self.delegate sliderValueChanged:self value:self.movieSlider.value];
}

                              
#pragma mark - Helper Methods
  /**
*returns the play back time.
 */
- (NSString *)timeFormatted:(NSInteger)totalSeconds
{
    
    NSInteger seconds = totalSeconds % 60;
    NSInteger minutes = (totalSeconds / 60) % 60;
    
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
}

@end
