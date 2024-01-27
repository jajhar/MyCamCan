//
//  Like.m
//  RedSoxApp
//
//  Created by James Ajhar on 2/3/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//


#import "Notification.h"
#import "DataModelObject_Inherit.h"
#import "AppData_ModelInternal.h"


@implementation Notification

#pragma mark - Initialization


+ (Notification *)notificationWithBasicInfoDictionary:(NSDictionary *)basicInfo {
    Notification *notification = [[Notification alloc] initWithBasicInfoDictionary:basicInfo];
    if (notification.theId == nil) {
        notification = nil;
    }
    return notification;
}


#pragma mark - Parsing


- (void)supplyBasicInfoDictionary:(NSDictionary *)basicInfo {
    [super supplyBasicInfoDictionary:basicInfo];
    
    // from user
    id temp = [basicInfo objectForKey:@"fromUser"];
    if ([temp isKindOfClass:[NSDictionary class]]) {
        _fromUser = [[AppData sharedInstance] getUserFromPoolWithInfo:temp];
    } else if ([temp isKindOfClass:[NSString class]]) {
        _fromUser = [[AppData sharedInstance] getUserFromPoolWithID:temp];
    }
    
    // created time
    temp = [basicInfo objectForKey:@"createdAt"];
    if ([temp isKindOfClass:[NSString class]]) {
        _createdAt = temp;
    }
    
    // type
    temp = [basicInfo objectForKey:@"type"];
    if ([temp isKindOfClass:[NSNumber class]]) {
        _type = [temp integerValue];
    }
    
    // metadata
    temp = [basicInfo objectForKey:@"metadata"];
    if ([temp isKindOfClass:[NSDictionary class]]) {
        
        // media
        if ([[temp objectForKey:@"media"] isKindOfClass:[NSDictionary class]]) {
            _media = [[AppData sharedInstance] getMediaFromPoolWithInfo:[temp objectForKey:@"media"]];
        }
    
    }
    
    switch (_type) {
        case kNotificationTypeLikedMedia:
            _message = [NSString stringWithFormat:@"%@ liked your video.", _fromUser.username];
            break;
        case kNotificationTypeWasFollowed:
            _message = [NSString stringWithFormat:@"%@ is now following you.", _fromUser.username];
            break;
        case kNotificationTypeFriendJoined:
            _message = [NSString stringWithFormat:@"Your friend %@ has just joined MyCamCan.", _fromUser.username];
            break;
            
        default:
            break;
    }
}


@end
