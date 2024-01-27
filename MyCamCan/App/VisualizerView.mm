
#import "VisualizerView.h"
#import <QuartzCore/QuartzCore.h>
#import "MeterTable.h"

@implementation VisualizerView {
  CAEmitterLayer *emitterLayer;
  MeterTable meterTable;
    CADisplayLink *dpLink;
    CGFloat _birthRate;
    CGFloat _lifeTime;
}

- (void)startVisualizing {
    [dpLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];

}

- (void)stopVisualizing {
    [dpLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

+ (Class)layerClass {
  return [CAEmitterLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    [self setBackgroundColor:[UIColor blackColor]];

    dpLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
  }
  return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateEmitterPosition];
}

- (void)updateEmitterPosition {
    emitterLayer.emitterPosition = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);

}

- (void)setupWithBirthRate:(CGFloat)birthRate lifeTime:(CGFloat)lifetime colorPallete:(UIColor *)colorPallete image:(UIImage *)image {
    emitterLayer = (CAEmitterLayer *)self.layer;
    
    CGFloat width = self.frame.size.width;//MAX(frame.size.width, frame.size.height);
    CGFloat height = self.frame.size.height;//MIN(frame.size.width, frame.size.height);
    emitterLayer.emitterPosition = CGPointMake(width/2, height/2);
    emitterLayer.emitterSize = CGSizeMake(width, height);
    emitterLayer.emitterShape = kCAEmitterLayerCircle;
    emitterLayer.renderMode = kCAEmitterLayerCircle;
    
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.name = @"cell";
    cell.spinRange = 2.0;
    
    CAEmitterCell *childCell = [CAEmitterCell emitterCell];
    childCell.name = @"childCell";
    childCell.lifetime = 1.0f / 60.0f;
    childCell.birthRate = 60.0f;
    childCell.velocity = 0.0f;
    childCell.spinRange = 2.0;
    
    if (image) {
        childCell.contents = (id)[image CGImage];
    } else {
        childCell.contents = (id)[[UIImage imageNamed:@"star-interaction"] CGImage];
    }
    
    cell.emitterCells = @[childCell];
//    cell.color = [colorPallete CGColor];
//    cell.color = [[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.8f] CGColor];
//    cell.color = [[UIColor colorWithRed:0.0f green:0.3f blue:0.6f alpha:0.8f] CGColor];
//    cell.redRange = 0.46f;
//    cell.greenRange = 0.49f;
//    cell.blueRange = 0.67f;
//    cell.alphaRange = 0.3f;
//    
//    cell.redSpeed = 0.11f;
//    cell.greenSpeed = 0.07f;
//    cell.blueSpeed = -0.25f;
//    cell.alphaSpeed = 0.15f;
    
    cell.scale = 0.5f;
    cell.scaleRange = 0.5f;
    
    cell.lifetime = lifetime;
//    cell.lifetime = 1.5f;
    cell.lifetimeRange = .25f;
//    cell.birthRate = 10;
    cell.birthRate = birthRate;
    
    cell.velocity = 80.0f;
    cell.velocityRange = 150.0f;
    cell.emissionRange = M_PI * 2;
    
    emitterLayer.emitterCells = @[cell];
    
    [emitterLayer setValue:@(0.6) forKeyPath:@"emitterCells.cell.emitterCells.childCell.scale"];

}

- (void)setBirthRate:(CGFloat)birthRate {
    _birthRate = birthRate;
}

- (void)setLifetime:(CGFloat)lifetime {
    _lifeTime = lifetime;
}

- (void)update
{
    float scale = 0.5;

  if (_audioPlayer.playing )
  {

    [_audioPlayer updateMeters];
    
    float power = 0.0f;
    for (int i = 0; i < [_audioPlayer numberOfChannels]; i++) {
      power += [_audioPlayer averagePowerForChannel:i];
    }
    power /= [_audioPlayer numberOfChannels];
    
    float level = meterTable.ValueAt(power);
    scale = level * 3;
      

  }
    
    [emitterLayer setValue:@(scale) forKeyPath:@"emitterCells.cell.emitterCells.childCell.scale"];

 
}

@end
