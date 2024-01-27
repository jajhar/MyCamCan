//
//  LikesPager.m
//  RedSoxApp
//
//  Created by Shakuro Developer on 5/29/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//


#import "LikesPager.h"
#import "Pager_Inherit.h"
#import "AppData.h"
#import "Like.h"
#import "AppData_ModelInternal.h"


@interface LikesPager()
{
    Media *_media;
}

@end


@implementation LikesPager


#pragma mark - Initialization


+ (LikesPager *)likesPagerForMedia:(Media *)media {
    return [[LikesPager alloc] initWithMedia:media];
}


- (id)initWithMedia:(Media *)media {
    self = [self init];
    if (self) {
        _media = media;
    }
    return self;
}


#pragma mark - Accessors


- (Like *)likeElementAtIndex:(NSUInteger)index {
    return (Like *)_elements[index];
}


#pragma mark - Inherit


- (void)makeGetRequestWithLimit:(NSUInteger)limit completion:(void (^)(NSArray *, NSInteger, NSString *, NSError *, NSDictionary *))completionBlock {
    [[AppData sharedInstance] getLikesForMedia:_media
                                withDateOffset:_nextPageDateOffset
                                      callback:^(NSArray *newElements, NSInteger newTotalCount, NSString *nextPage, NSError *error) {
                                          completionBlock(newElements, newTotalCount, nextPage, error, nil);
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
        
        for(Like *like in newElements) {
            if(![_elements containsObject:like]) {
                [_elements addObject:like];
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


- (void)clearInherited {
    _nextPageDateOffset = @"";
}


- (void)sendNotificationChangedWithTotalFlag:(BOOL)total {
    [[AppData sharedInstance] sendPagerNotification:kAppData_Notification_Pager_Likes
                                              total:total
                                               user:nil
                                              media:_media];
}


@end
