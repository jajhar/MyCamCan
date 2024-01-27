//
//  User_ModelInternal.h
//  RedSoxApp
//
//  Created by Shakuro Developer on 5/20/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//


#import "User.h"


@interface User ()

- (BOOL)stopFollowing:(User *)user;
- (BOOL)startFollowing:(User *)user;
- (BOOL)setupFollowing:(NSArray *)array;
- (BOOL)removeFollower:(User *)user;
- (BOOL)addFollower:(User *)user;
- (BOOL)setupFollowers:(NSArray *)array;
- (BOOL)updateAvatarUrl:(NSString *)fileName;
- (BOOL)updateCoverUrl:(NSString *)fileName;
@end
