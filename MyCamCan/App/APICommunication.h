//
//  APICommunication.h
//  Zum 2.0
//
//  Created by James Ajhar on 4/29/13.
//  Copyright (c) 2013 James Ajhar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "URLs.h"
#import "User.h"


@class User;
@class Comment;
@class Media;
@class Capsule;
@class ASIHTTPRequest;


#define SAFE_CALLBACK2(a, b)\
if (callback != NULL)\
callback(a,b)

#define SAFE_CALLBACK3(a, b, c)\
if (callback != NULL)\
callback(a,b,c)

#define SAFE_CALLBACK4(a, b, c, d)\
if (callback != NULL)\
callback(a,b,c,d)


extern const NSTimeInterval defaultRequesTimeOutSeconds;
extern const NSTimeInterval resourceRequesTimeOutSeconds;

extern const time_t APIFirstPageCeilingTime;
extern __strong NSString * const APIFirstPageStart;


typedef void (^BlogAPICompletionBlock)(NSData *data);
typedef void (^BlogAPICompletion2Block)(NSData *data, BOOL fromCache);
typedef void (^BlogAPIProgressBlock) (float progress, float progressSoFar, float length);
typedef void (^BlogAPIFailureBlock)(NSError *error);
typedef void (^BlogVideoThumbnailBlock)(NSURL *thumbImageURL, NSString *thumbKey, NSError *error);

typedef NS_ENUM(NSUInteger, requestType) {
    GET = 0,
    POST = 1,
    PUT = 2,
    DELETE = 3
};

@interface APICommunication : NSObject

// routines
+ (NSMutableDictionary *)convertJsonToDictionary:(NSData *)data;
+ (BOOL)validateAPIResult:(NSDictionary *)result error:(NSError **)error;


#pragma mark - Register/Login


+ (void)registerUserWithUsername:(NSString *)username
                        password:(NSString *)password
                           email:(NSString *)email
                       firstName:(NSString *)firstName
                        lastName:(NSString *)lastName
                           phone:(NSString *)phone
                        birthday:(NSDate *)birthday
                      completion:(BlogAPICompletionBlock)completion
                         failure:(BlogAPIFailureBlock)failure;

+ (void)loginWithEmail:(NSString *)email
              password:(NSString *)password
            completion:(BlogAPICompletionBlock)completion
               failure:(BlogAPIFailureBlock)failure;

+ (void)loginWithFacebookToken:(NSString *)token
            completion:(BlogAPICompletionBlock)completion
               failure:(BlogAPIFailureBlock)failure;

    + (void)sendForgotPasswordRequestWithEmail:(NSString*)email completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;
    + (void)changePassword:(NSString *)newPassword completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;

#pragma mark - Feed

    + (void)getFeedWithOffset:(NSInteger)offset completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;
    + (void)getGlobalFeedWithOffset:(NSString *)offset completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;

#pragma mark - Media

+ (void)updateMedia:(Media *)media completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;

#pragma mark - User

    + (void)updateUserDeviceId:(NSString*)deviceId completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;
    + (void)getProfile:(User *)user forceReload:(BOOL)forceReload completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;
    + (void)getMediaForUser:(User *)user dateOffset:(NSString *)dateOffset completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;
    + (void)updatePassword:(NSString *)password token:(NSString *)token completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;

    //--Followers
    + (void)getFollowersForUser:(User *)user
                     withOffset:(NSInteger)offset
                     completion:(BlogAPICompletionBlock)completion
                        failure:(BlogAPIFailureBlock)failure;

    //--Following
    + (void)getFolloweesForUser:(User *)user
                     withOffset:(NSInteger)offset
                     completion:(BlogAPICompletionBlock)completion
                        failure:(BlogAPIFailureBlock)failure;
    + (void) startFollowingUser:(User *)user completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;
    + (void) stopFollowingUser:(User *)user completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;
    + (void)blockUser:(User *)user completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;
    + (void)unblockUser:(User *)user completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;


// Create Comment
    + (void)createComment:(Comment *)comment completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;
    + (void)verifyUsername:(NSString *)username completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;
    + (void)updateAvatarWithFileName:(NSString *)fileName completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;
    + (void)updateCoverWithFileName:(NSString *)fileName completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;


    + (void)deleteMedia:(Media *)media completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;
    + (void)getMediaWithId:(NSString *)mediaId completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;

#pragma mark - Notifications

    + (void)getNotificationsWithDateOffset:(NSString *)dateOffset
                                     limit:(NSUInteger)limit
                                completion:(BlogAPICompletionBlock)completion
                                   failure:(BlogAPIFailureBlock)failure;


#pragma mark - Likes

    + (void)likeMedia:(Media *)media completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;
    + (void)getLikesForMedia:(Media *)media dateOffset:(NSString *)dateOffset completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;

#pragma mark - Search

    + (void)getFeaturedArtistMusicWithCompletion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;
    + (void)getTopMusicWithCompletion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;

    + (void)searchMusicWithKeyword:(NSString *)keyword completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;
    + (void)searchUsersWithKeyword:(NSString *)keyword completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;
    + (void)searchTotalUsersForPhoneNumbers:(NSArray *)phoneNumbers completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;
    + (void)searchUsersWithPhoneNumbers:(NSArray *)phoneNumbers completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;

+ (void) addApplicationHeaders:(ASIHTTPRequest *)request;

// API Uploader
+ (void)saveMediaToDatabase:(Media *)media filename:(NSString *)filename thumbName:(NSString *)thumbName completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure;

//S3 Uploads
+ (void)uploadMedia:(Media *)media
       fileURL:(NSURL *)fileURL
        forKey:(NSString *)key
    completion:(BlogAPICompletionBlock)completion
      progress:(BlogAPIProgressBlock)progress
       failure:(BlogAPIFailureBlock)failure;

+ (void)upload:(NSURL *)fileURL
             forKey:(NSString *)key
         completion:(BlogAPICompletionBlock)completion
           progress:(BlogAPIProgressBlock)progress
            failure:(BlogAPIFailureBlock)failure;

@end
