//
//  FollowersPager.h
//  MCC
//
//  Created by Shakuro Developer on 6/26/14.
//  Copyright (c) 2014 D9. All rights reserved.
//


#import "Pager.h"


@class User;


@interface FollowersPager : Pager

+ (FollowersPager *)followersPagerForUser:(User *)user;

@end
