//
//  Notification.h
//  Blog
//
//  Created by James Ajhar on 9/14/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "DataModelObject.h"

typedef NS_ENUM(NSUInteger, NotificationType) {
    kNotificationTypeLikedMedia = 0,
    kNotificationTypeWasFollowed,
    kNotificationTypeFriendJoined,
};

@interface Notification : DataModelObject

//--inits
+ (Notification *)notificationWithBasicInfoDictionary:(NSDictionary *)basicInfo;

//--data
@property (strong, nonatomic) User *fromUser;
@property (strong, nonatomic) Media *media;
@property (strong, nonatomic) NSString *createdAt;
@property (strong, nonatomic) NSString *message;
@property (nonatomic) NotificationType type;

@end
