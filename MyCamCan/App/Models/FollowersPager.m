//
//  FollowersPager.m
//  MCC
//
//  Created by Shakuro Developer on 6/26/14.
//  Copyright (c) 2014 D9. All rights reserved.
//


#import "FollowersPager.h"
#import "Pager_Inherit.h"

#import "AppData.h"
#import "AppData_ModelInternal.h"


@interface FollowersPager()
{
    NSInteger _offset;
    __weak User *_owner;
}

- (id)initForUser:(User *)user;
    
@end


@implementation FollowersPager


#pragma mark - Initialization


+ (FollowersPager *)followersPagerForUser:(User *)user {
    return [[FollowersPager alloc] initForUser:user];
}


- (id)initForUser:(User *)user {
    self = [super init];
    if (self) {
        _owner = user;
        _offset = 0;
    }
    return self;
}

#pragma mark - Inherited


- (void)makeGetRequestWithLimit:(NSUInteger)limit completion:(void (^)(NSArray *, NSInteger, NSString *, NSError *, NSDictionary *))completionBlock {
    //NOTE: this pager does not use actual pages to get data. See [parseGetServerResponse:]
    [[AppData sharedInstance] getFollowersOfUser:_owner
                                        withOffset:_offset
                                           callback:^(NSArray *newElements, NSInteger newTotalCount, NSString *nextPage, NSError *error) {
                                               completionBlock(newElements, newTotalCount, nextPage, error, nil);
                                           }];
}


- (NSUInteger)parseGetServerResponseWithElements:(NSArray *)newElements nextPage:(NSString *)nextPage info:(NSDictionary *)info {
    
    NSInteger oldCount = _elements.count;
    
    if (newElements.count == 0) {
        // server has no more data
        [self markEndOfPages];
        [self sendNotificationChangedWithTotalFlag:NO];
        
    } else {
        // add parsed elements to list
        [_elements addObjectsFromArray:newElements];
        
        _offset += newElements.count;
        
        if(oldCount == 0) {
            [self sendNotificationChangedWithTotalFlag:YES];
        } else {
            [self sendNotificationChangedWithTotalFlag:NO];
        }
    }
    
    return newElements.count;
}

- (void)clearStateAndElements {
    [super clearStateAndElements];
    _offset = 0;
}

- (void)sendNotificationChangedWithTotalFlag:(BOOL)total {
    [[AppData sharedInstance] sendPagerNotification:kAppData_Notification_Pager_Followers
                                                 total:total
                                                  user:_owner
                                                 media:nil];
}


@end
