//
//  LikesPager.m
//  RedSoxApp
//
//  Created by Shakuro Developer on 5/29/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//


#import "NotificationPager.h"
#import "Pager_Inherit.h"
#import "AppData.h"
#import "AppData_ModelInternal.h"
#import "user.h"
#import "Notification.h"

@interface NotificationPager()
{
    User *_user;
}

@end


@implementation NotificationPager


#pragma mark - Initialization


+ (NotificationPager *)NotificationPagerForUser:(User *)user {
    return [[NotificationPager alloc] initWithUser:user];
}


- (id)initWithUser:(User *)user {
    self = [self init];
    if (self) {
        _user = user;
    }
    return self;
}


#pragma mark - Accessors


#pragma mark - Inherit


- (void)makeGetRequestWithLimit:(NSUInteger)limit completion:(void (^)(NSArray *, NSInteger, NSString *, NSError *, NSDictionary *))completionBlock {
    [[AppData sharedInstance] getNotificationsWithDateOffset:_nextPageDateOffset
                                                    callback:^(NSArray *newElements, NSInteger newTotalCount, NSString *nextPage, NSError *error) {
                                                        completionBlock(newElements, newTotalCount, nextPage, error,  nil);
                                                    }];
}


- (NSUInteger)parseGetServerResponseWithElements:(NSArray *)newElements nextPage:(NSString *)nextPage info:(NSDictionary *)info {
    
    NSInteger oldCount = _elements.count;
    
    if (newElements.count == 0) {
        // server has no more data
        [self markEndOfPages];
        [self sendNotificationChangedWithTotalFlag:YES];
        
    } else {
        // add parsed elements to list
        
        for(Notification *notification in newElements) {
            if(![_elements containsObject:notification]) {
                [_elements addObject:notification];
            }
        }
        
        // save next page offset
        _nextPageDateOffset = [[_elements lastObject] createdAt];
        
        if(oldCount == 0 || !_isEndOfPages) {
            [self sendNotificationChangedWithTotalFlag:YES];
        }
    }
    
    return newElements.count;
}


- (void)sendNotificationChangedWithTotalFlag:(BOOL)total {
    [[AppData sharedInstance] sendPagerNotification:kAppData_Notification_Pager_Notifications
                                                 total:total
                                                  user:nil
                                                 media:nil];
}



@end
