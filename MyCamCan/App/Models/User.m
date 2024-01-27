//
//  User.m
//  Zum 2.0
//
//  Created by James Ajhar on 4/29/13.
//  Copyright (c) 2013 James Ajhar. All rights reserved.
//

#import "User.h"
#import "User_ModelInternal.h"
#import "DataModelObject_Inherit.h"
//#import "Uploads.h"
#import "FeedPager.h"
#import "Media.h"
#import "AppData.h"
#import "AppData_ModelInternal.h"
#import "URLs.h"
#import "SearchPager.h"
#import "NotificationPager.h"
#import "FollowersPager.h"
#import "FolloweesPager.h"
#import "ProfileMediaPager.h"

@interface User()
{
    NSMutableArray *_followers;
    NSMutableArray *_following;
}

@end


@implementation User

@synthesize email = _email;
@synthesize username = _username;
@synthesize firstName = _firstName;
@synthesize lastName = _lastName;
@synthesize birthday = _birthday;
@synthesize bio = _bio;
@synthesize deviceToken = _deviceToken;
@synthesize avatarUrl = _avatarUrl;
@synthesize genderType = _genderType;
@synthesize feedPager = _feedPager;
@synthesize globalFeedPager = _globalFeedPager;
@synthesize searchPager = _searchPager;
@synthesize notificationPager = _notificationPager;
@synthesize followersPager = _followersPager;
@synthesize followeesPager = _followeesPager;

#pragma mark - Initialization

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self = [self initWithId:[decoder decodeObjectForKey:@"id"]];
        
        _email = [decoder decodeObjectForKey:@"email"];
        _username = [decoder decodeObjectForKey:@"username"];
        _firstName = [decoder decodeObjectForKey:@"_firstName"];
        _lastName = [decoder decodeObjectForKey:@"_lastName"];
        _birthday = [decoder decodeObjectForKey:@"birthday"];
        _bio = [decoder decodeObjectForKey:@"bio"];
        _avatarUrl = [decoder decodeObjectForKey:@"avatar"];
        _coverPhotoURL = [decoder decodeObjectForKey:@"cover"];
        _blockedUserIds = [decoder decodeObjectForKey:@"blockedUserIds"];

//        if(!self.uploads) {
//            self.uploads = [Uploads uploadsForUser:self];
//        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    
    [encoder encodeObject:self.theId forKey:@"id"];
    [encoder encodeObject:_email forKey:@"email"];
    [encoder encodeObject:_username forKey:@"username"];
    [encoder encodeObject:_firstName forKey:@"firstName"];
    [encoder encodeObject:_lastName forKey:@"lastName"];
    [encoder encodeObject:_birthday forKey:@"birthday"];
    [encoder encodeObject:_bio forKey:@"bio"];
    [encoder encodeObject:_coverPhotoURL forKey:@"cover"];
    [encoder encodeObject:_avatarUrl forKey:@"avatar"];
    [encoder encodeObject:_blockedUserIds forKey:@"blockedUserIds"];

}



+ (User *)userWithUsername:(NSString *)username
                     email:(NSString *)email {
    
	return [[User alloc] initWithUsername:username
                                    email:email];
}


+ (User *)userWithSearchInfoDictionary:(NSDictionary *)searchInfo {
    return [[User alloc] initWithSearchInfoDictionary:searchInfo];
}


+ (User *)userWithId:(NSString *)theId {
	return [[User alloc] initWithId:theId];
}


+ (User *)userWithBasicInfoDictionary:(NSDictionary *)basicInfo {
	User *user = [[User alloc] initWithBasicInfoDictionary:basicInfo];
	if (user.theId == nil)
		user = nil;
    
    user.username = user.username ? user.username : @"";
    
    return user;
}


- (instancetype)initWithUsername:(NSString *)username
                           email:(NSString *)email
                      {
    self = [self initWithId:nil];
    if (self) {
        _username = username;
        _email = email;
    }
    return self;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        //self.uploads = [Uploads uploadsForUser:self];
        _followers = [NSMutableArray array];
        _following = [NSMutableArray array];
        _isFirstTimeUser = NO;
    }
    return self;
}


#pragma mark - Accessors


- (void)supplyUsername:(NSString *)newValue {
    _username = newValue;
}


- (void)supplyDeviceToken:(NSString *)newValue {
    _deviceToken = newValue;
}


- (FeedPager *)feedPager {
    if (_feedPager == nil) {
        _feedPager = [FeedPager feedPager];
        [_feedPager setUser:self];
    }
    return _feedPager;
}

- (FeedPager *)globalFeedPager {
    if (_globalFeedPager == nil) {
        _globalFeedPager = [FeedPager feedPager];
        [_globalFeedPager setUser:self];
    }
    return _globalFeedPager;
}

- (SearchPager *)searchPager {
    if (_searchPager == nil) {
        _searchPager = [[SearchPager alloc] init];
    }
    return _searchPager;
}

- (FollowersPager *)followersPager {
    if (_followersPager == nil) {
        _followersPager = [FollowersPager followersPagerForUser:self];
    }
    return _followersPager;
}

- (FolloweesPager *)followeesPager {
    if (_followeesPager == nil) {
        _followeesPager = [FolloweesPager followeesPagerForUser:self];
    }
    return _followeesPager;
}

- (ProfileMediaPager *)profileMediaPager {
    if (_profileMediaPager == nil) {
        _profileMediaPager = [ProfileMediaPager ProfileMediaPagerForUser:self];
    }
    return _profileMediaPager;
}

- (NotificationPager *)notificationPager {
    if (_notificationPager == nil) {
        _notificationPager = [[NotificationPager alloc] init];
    }
    return _notificationPager;
}

- (NSString *)genderString {
    switch (self.genderType) {
        case GenderTypeFemale:
            return @"Female";
        case GenderTypeMale:
            return @"Male";
        case GenderTypeOther:
            return @"Other";
    }
    return @"";
}


#pragma mark - Parsing Server results


+ (NSString *)IDFromBasicInfoDictionary:(NSDictionary *)basicInfo {
    NSString *result = [super IDFromBasicInfoDictionary:basicInfo];
    return result != nil ? result : @"";
}


- (void)supplyBasicInfoDictionary:(NSDictionary *)basicInfo {
    [super supplyBasicInfoDictionary:basicInfo];
    
    id temp = [basicInfo objectForKey:@"username"];
    if(temp != nil && [temp isKindOfClass:[NSString class]]) {
        _username = temp;
    }
    
    temp = [basicInfo objectForKey:@"email"];
    if(temp != nil && [temp isKindOfClass:[NSString class]]) {
        _email = temp;
    }
    
    temp = [basicInfo objectForKey:@"avatar"];
    if(temp != nil && [temp isKindOfClass:[NSString class]]) {
        _avatarUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [URLs s3CDN], temp]];
    }
    
    temp = [basicInfo objectForKey:@"coverPhoto"];
    if(temp != nil && [temp isKindOfClass:[NSString class]]) {
        _coverPhotoURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [URLs s3CDN], temp]];
    }
    
    temp = [basicInfo objectForKey:@"isFollowing"];
    if(temp != nil) {
        _isFollowing = [temp boolValue];
    }
    
    temp = [basicInfo objectForKey:@"blockedUserIds"];
    if(temp != nil) {
        _blockedUserIds = [temp mutableCopy];
    }
    
    temp = [basicInfo objectForKey:@"totalFollowing"];
    if(temp != nil && temp != [NSNull null]) {
        _totalFollowing = [temp integerValue];
    }
    
    temp = [basicInfo objectForKey:@"totalFollowers"];
    if(temp != nil && temp != [NSNull null]) {
        _totalFollowers = [temp integerValue];
    }
    
    temp = [basicInfo objectForKey:@"totalUnreadNotifications"];
    if(temp != nil && temp != [NSNull null]) {
        _totalUnreadNotifications = [temp integerValue];
    }
}


#pragma mark - Actions


- (BOOL)updateAvatarUrl:(NSString *)fileName {
    NSString *avatarString = [NSString stringWithFormat:@"%@/%@", [URLs s3CDN], fileName];
    _avatarUrl = [NSURL URLWithString:[avatarString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    return YES;
}

- (BOOL)updateCoverUrl:(NSString *)fileName {
    NSString *coverString = [NSString stringWithFormat:@"%@/%@", [URLs s3CDN], fileName];
    _coverPhotoURL = [NSURL URLWithString:[coverString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    return YES;
}

@end
