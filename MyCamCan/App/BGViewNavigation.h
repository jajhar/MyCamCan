//
//  BGViewNavigation.h
//  Blog
//
//  Created by James Ajhar on 12/1/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//

#import "BGView.h"

extern const CGFloat kBGViewHeaderHeight;

typedef NS_ENUM(NSUInteger, BGNavigationBarOption) {
    kNavigationOptionHome = 0,
    kNavigationOptionSearch = 1,
    kNavigationOptionNotifications = 3,
    kNavigationOptionProfile = 4,
    kNavigationOptionNone = 5

};

@interface BGViewNavigation : BGView

- (void)setSelectedNavigationOption:(BGNavigationBarOption)option;

@end
