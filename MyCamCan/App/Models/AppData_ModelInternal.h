//
//  AppData_ModelInternal.h
//  RedSoxApp
//
//  Created by Shakuro Developer on 5/6/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//


#import "AppData.h"


@class User;
@class Post;
@class PostContent;

// methods to be used inside data model structure
@interface AppData ()

//--pools
- (User *)getUserFromPoolWithID:(NSString *)theID;
- (User *)getUserFromPoolWithInfo:(NSDictionary *)userInfo;
- (User *)getUserFromPoolWithID:(NSString *)theID username:(NSString *)username;
- (Media *)getMediaFromPoolWithID:(NSString *)theID;
- (Media *)getMediaFromPoolWithInfo:(NSDictionary *)postInfo;

//--notifications
- (void)sendNotificationCommentsListChangedForMedia:(Media *)media;
- (void)sendNotificationCommentsListAppendedForMedia:(Media *)media count:(NSUInteger)count;
- (void)sendNotificationPostFeedChanged;
- (void)sendNotificationPostFeedAppendedWith:(NSUInteger)count;
- (void)sendNotificationMediasChangedForUser:(User *)user;
- (void)sendNotificationMediasForUser:(User *)user appendedWith:(NSUInteger)count;

@property (strong, nonatomic) NSTimer *pollTimer;
@property (nonatomic, strong) User *localUser;

- (void)sendPagerNotification:(NSString *)notificationName
                        total:(BOOL)total
                         user:(User *)user
                        media:(Media *)media;

- (void)sendPagerNotification:(NSString *)notificationName
                        total:(BOOL)total
                         user:(User *)user
                        media:(Media *)media
                        index:(NSUInteger)index;

// notifications
- (void)sendNotificationWithName:(NSString *)name infoDictionary:(NSDictionary *)infoDict;
- (void)sendElementNotification:(NSString *)notificationName user:(User *)user media:(Media *)media;

@end
