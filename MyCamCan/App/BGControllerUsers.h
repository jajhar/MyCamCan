//
//  BGControllerUsers.h
//  Blog
//
//  Created by James Ajhar on 12/2/15.
//  Copyright © 2015 James Ajhar. All rights reserved.
//

#import "BGController.h"

typedef NS_ENUM(NSUInteger, BGControllerUsersFilterType) {
    kBGControllerUsersFilterTypeFollowers      = 0,
    kBGControllerUsersFilterTypeFollowees      = 1
};

extern NSString *kBGKeyUsersFilter;

@interface BGControllerUsers : BGController

@end
