//
//  BGViewButtonCarousel.m
//  Blog
//
//  Created by James Ajhar on 9/9/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGViewButtonCarousel.h"

#import "iCarousel.h"

@interface BGViewButtonCarousel () <iCarouselDataSource, iCarouselDelegate>

@property (strong, nonatomic) iCarousel *carousel;

@end


@implementation BGViewButtonCarousel


- (void)commonInit {
    [super commonInit];
    
    self.carousel = [[iCarousel alloc] initWithFrame:self.bounds];
    self.carousel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin |
                                        UIViewAutoresizingFlexibleHeight |
                                        UIViewAutoresizingFlexibleLeftMargin |
                                        UIViewAutoresizingFlexibleRightMargin |
                                        UIViewAutoresizingFlexibleTopMargin |
                                        UIViewAutoresizingFlexibleWidth;
    
    [self addSubview:self.carousel];
    
    self.carousel.bounces = NO;
    self.carousel.delegate = self;
    self.carousel.dataSource = self;
    
    //configure carousel
    self.carousel.type = iCarouselTypeLinear;
}

- (void)reloadData {
    [self.carousel reloadData];
}

- (void)scrollToIndex:(NSInteger)index {
    [self.carousel scrollToItemAtIndex:index animated:YES];
}

- (void)scrolltoOffset:(CGFloat)offset {
    [self.carousel scrollToOffset:offset duration:0.5];
}

- (void)setDelegate:(id)delegate {
    _delegate = delegate;
    
    [self.carousel reloadData];
}

- (UIFont *)boldFontWithFont:(UIFont *)font
{
    UIFontDescriptor * fontD = [font.fontDescriptor
                                fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    return [UIFont fontWithDescriptor:fontD size:18];
}

#pragma mark iCarousel methods

- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel {
    return [self.delegate numberOfButtonsInCarousel:carousel];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    UIButton *button = (UIButton *)view;
    if (button == nil)
    {
        //no button available to recycle, so create new one
        button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(10.0f, 0.0f, 185.0, 35.0);
        [button setTitleColor:[UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        button.titleLabel.font = [self boldFontWithFont:button.titleLabel.font];
        
        NSLog(@"font: %@", [NSString stringWithFormat:@"%@", button.titleLabel.font.fontName]);
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    }
    
    //set button label
    NSString *title = [self.delegate titleForButtonInCarousel:carousel atIndex:index];
    [button setTitle:title forState:UIControlStateNormal];

    
    return button;
}

- (CGFloat)carouselItemWidth:(iCarousel *)carousel {
    return 170.0;
}

- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel {
    [self.delegate buttonTappedAtIndex:carousel.currentItemIndex];
}

@end
