//
//  LikesPager.h
//  RedSoxApp
//
//  Created by Shakuro Developer on 5/29/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//


#import "Pager.h"

@class User;

@interface NotificationPager : Pager

+ (NotificationPager *)NotificationPagerForUser:(User *)user;

@end
