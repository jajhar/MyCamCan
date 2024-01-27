//
//  User.h
//  Zum 2.0
//
//  Created by James Ajhar on 4/29/13.
//  Copyright (c) 2013 James Ajhar. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "DataModelObject.h"

@class Uploads;
@class FeedPager;
@class SearchPager;
@class NotificationPager;
@class FollowersPager;
@class FolloweesPager;
@class ProfileMediaPager;

typedef NS_ENUM(NSUInteger, UserRelationStatus) {
    UserRelationStatusUnknown = 0,
    UserRelationStatusSelf,
    UserRelationStatusFriend,
    UserRelationStatusStranger
};


typedef NS_ENUM(NSUInteger, GenderType) {
    GenderTypeMale = 0,
    GenderTypeFemale = 1,
    GenderTypeOther = 2,
};


@interface User : DataModelObject

//--inits
+ (User *)userWithUsername:(NSString *)username
                     email:(NSString *)email;

//--data
@property (nonatomic, strong, readonly) NSString *email;
@property (nonatomic, strong) NSString *username;
- (void)supplyUsername:(NSString *)newValue;
@property (strong, nonatomic, readonly) NSString *firstName;
@property (strong, nonatomic, readonly) NSString *lastName;
@property (strong, nonatomic, readonly) NSDate *birthday;
@property (strong, nonatomic, readonly) NSString *bio;
@property (strong, nonatomic) NSString *phone;
@property (strong, nonatomic, readonly) NSString *deviceToken;
- (void)supplyDeviceToken:(NSString *)newValue;
@property (strong, nonatomic, readonly) NSURL *avatarUrl;
@property (strong, nonatomic) NSURL *coverPhotoURL;
@property (strong, nonatomic) NSMutableArray *blockedUserIds;

@property (strong, nonatomic, readonly) NSURL *avatarSmallUrl;
@property (assign, nonatomic, readonly) GenderType genderType;
- (NSString *)genderString;
@property (strong, nonatomic, readonly) FeedPager *feedPager;
@property (strong, nonatomic, readonly) FeedPager *globalFeedPager;
@property (strong, nonatomic, readonly) SearchPager *searchPager;
@property (strong, nonatomic, readonly) NotificationPager *notificationPager;
@property (strong, nonatomic, readonly) FollowersPager *followersPager;
@property (strong, nonatomic, readonly) FolloweesPager *followeesPager;
@property (strong, nonatomic) ProfileMediaPager *profileMediaPager;

@property (nonatomic, assign) BOOL isFollowing;
@property (nonatomic, assign) BOOL isFirstTimeUser;
@property (nonatomic, assign) NSInteger totalFollowers;
@property (nonatomic, assign) NSInteger totalFollowing;
@property (nonatomic, assign) NSInteger totalUnreadNotifications;

//--parsing
+ (User *)userWithId:(NSString *)theId;
+ (User *)userWithBasicInfoDictionary:(NSDictionary *)basicInfo;

@end
