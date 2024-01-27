//
//  BGViewButtonCarousel.h
//  Blog
//
//  Created by James Ajhar on 9/9/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGView.h"

@class iCarousel;

@protocol BGViewButtonCarouselDelegate <NSObject>

@required
- (void)buttonTappedAtIndex:(NSInteger)index;
- (NSInteger)numberOfButtonsInCarousel:(iCarousel *)carousel;
- (NSString *)titleForButtonInCarousel:(iCarousel *)carousel atIndex:(NSInteger)index;

@end

@interface BGViewButtonCarousel : BGView

@property (nonatomic, assign) id delegate;

- (void)reloadData;
- (void)scrollToIndex:(NSInteger)index;
- (void)scrolltoOffset:(CGFloat)offset;

@end
