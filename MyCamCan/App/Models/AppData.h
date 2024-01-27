//
//  zumData.h
//  Zum 2.0
//
//  Created by James Ajhar on 4/30/13.
//  Copyright (c) 2013 James Ajhar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APICommunication.h"
#import "ASIHTTPRequest.h"
#import "URLs.h"
#import "FeedPager.h"
#import "BGTabBarController.h"
#import <Accounts/Accounts.h>

@class LocalSession;
@class UploadQueue;

typedef void (^AppDataCallback)(id result, NSError *error);
typedef void (^AppDataCallbackPagerElements)(NSArray *newElements, NSInteger newTotalCount, NSString *nextPage, NSError *error);

static __attribute__((unused)) NSString *kAppAPIErrorDomain = @"com.LA.Blog.API";
static __attribute__((unused)) NSString *kAppS3APIErrorDomain = @"com.LA.Blog.AmazonS3API";
static __attribute__((unused)) NSString *kAppErrorDomain = @"com.LA.Blog";

// notifications
extern NSString * const kAppData_Notification_CommentsListChanged;
extern NSString * const kAppData_Notification_CommentsListAppended;
extern NSString * const kAppData_Notification_FeedChanged;
extern NSString * const kAppData_Notification_ProfileMediaChanged;
extern NSString * const kAppData_Notification_FeedAppended;
extern NSString * const kAppData_Notification_FeedDeleted;
extern NSString * const kAppData_Notification_MediaUpdated;
extern NSString * const kAppData_Notification_UserUpdated;
extern NSString * const kAppData_Notification_UserMediasChanged;
extern NSString * const kAppData_Notification_UserMediasAppended;
extern NSString * const kAppData_Notification_UserMediaDeleted;
extern NSString * const kAppData_Notification_Pager_Comments;
extern NSString * const kAppData_Notification_NotificationsReceived;

// pagers
extern NSString * const kAppData_Notification_Pager_Subscribers;
extern NSString * const kAppData_Notification_Pager_Comments;
extern NSString * const kAppData_Notification_Pager_Feed;
extern NSString * const kAppData_Notification_Pager_Likes;
extern NSString * const kAppData_Notification_Pager_Medias;
extern NSString * const kAppData_Notification_Pager_Notifications;
extern NSString * const kAppData_Notification_Pager_Followers;
extern NSString * const kAppData_Notification_Pager_Following;
extern NSString * const kAppData_Notification_Pager_Search;

// notification keys
extern NSString * const kAppData_NotificationKey_User;
extern NSString * const kAppData_NotificationKey_Media;
extern NSString * const kAppData_NotificationKey_Count;
extern NSString * const kAppData_NotificationKey_Index;
extern NSString * const kAppData_NotificationKey_TotalFlag;

extern NSString *kVXKeyMedia;
extern NSString *kVXKeyUser;
extern NSString *kBGKeyURL;
extern NSString *kBGKeyImagePickerDelegate;
extern NSString *kBGInfoMusicItem;

@interface AppData : NSObject

//--singleton
+ (AppData *)sharedInstance;

//--auth
@property (nonatomic, strong, readonly) User *localUser;
@property (nonatomic, strong, readonly) LocalSession *localSession;
@property (nonatomic, strong) NSString *deviceToken;                 // This device id (used for sending push notifications)
@property (nonatomic, strong) BGTabBarController *navigationManager;
@property (nonatomic, strong) UINavigationController *LoginNavigationController;
@property (strong, nonatomic) ACAccount *facebookAccount;

- (void)resetNavigationManager;

//--register new user
- (void)registerUser:(User *)user password:(NSString *)password callback:(AppDataCallback)callback;

//--login
- (void)loginWithEmail:(NSString *)email password:(NSString *)password andCallback:(AppDataCallback)callback;
- (void)loginWithFacebookToken:(NSString *)token andCallback:(AppDataCallback)callback;
- (void)setLocalSessionWithEmail:(NSString *)email password:(NSString *)password;
- (void)clearLocalSession;
- (void)storeLocalSession;
- (BOOL)restoreLocalSession;
- (void)sendForgotPasswordRequestWithEmail:(NSString*)email andCallback:(AppDataCallback)callback;
- (void)verifyUsername:(NSString *)username callback:(AppDataCallback)callback;

//--update user info
- (void)updateUserDeviceId:(NSString *)deviceId callback:(AppDataCallback)callback;

//--User
- (void)getProfileForUser:(User *)user callback:(AppDataCallback)callback;
- (void)blockUser:(User *)user callback:(AppDataCallback)callback;
- (void)unblockUser:(User *)user callback:(AppDataCallback)callback;
- (void)getMediaForUser:(User *)user withDateOffset:(NSString*)dateOffset callback:(AppDataCallbackPagerElements)callback;
- (void)stopFollowingUser:(User *)user callback:(AppDataCallback)callback;
- (void)startFollowingUser:(User *)user callback:(AppDataCallback)callback;
- (void)getFollowersOfUser:(User *)user withOffset:(NSInteger)offset callback:(AppDataCallbackPagerElements)callback;
- (void)getFolloweesOfUser:(User *)user withOffset:(NSInteger)offset callback:(AppDataCallbackPagerElements)callback;
- (void)updateAvatarWithPhoto:(NSURL *)photoURL withFileName:(NSString*)fileName callback:(AppDataCallback)callback;
- (void)updateCoverWithPhoto:(NSURL *)photoURL withFileName:(NSString*)fileName callback:(AppDataCallback)callback;
- (void)updatePassword:(NSString *)newPassword token:(NSString *)token callback:(AppDataCallback)callback;
- (void)updateUserInfoWithFirstName:(NSString *)firstName
                           lastName:(NSString *)lastName
                                bio:(NSString *)bio
                         genderType:(GenderType)genderType
                           hometown:(NSString *)hometown
                           birthday:(NSDate *)birthday
                           callback:(AppDataCallback)callback;
// Feed

- (void)getFeedForUser:(User *)user
        withOffset:(NSInteger)Offset
        withFilterType:(BGFeedFilterType)filterType
              callback:(AppDataCallbackPagerElements)callback;

- (void)getGlobalFeedForUser:(User *)user
                  withOffset:(NSString *)Offset
              withFilterType:(BGFeedFilterType)filterType
                    callback:(AppDataCallbackPagerElements)callback;

- (void)updateMedia:(Media *)media callback:(AppDataCallback)callback;


// Notifications

- (void)getNotificationsWithDateOffset:(NSString *)dateOffset
                              callback:(AppDataCallbackPagerElements)callback;

// Likes

- (void)likeMedia:(Media *)media
         callback:(AppDataCallback)callback;

- (void)getLikesForMedia:(Media *)media
          withDateOffset:(NSString *)dateOffset
                callback:(AppDataCallbackPagerElements)callback;

- (void)deleteMedia:(Media *)media
           callback:(AppDataCallback)callback;


- (void)getFeaturedArtistMusicWithCallback:(AppDataCallback)callback;
- (void)getTopMusicWithCallback:(AppDataCallback)callback;

// Search
- (void)searchMusicWithKeyword:(NSString *)keyword
                      callback:(AppDataCallback)callback;
- (void)searchUsersWithKeyword:(NSString *)keyword
                      callback:(AppDataCallbackPagerElements)callback;
- (void)getTotalUsersForPhoneNumbers:(NSArray *)phoneNumbers
                            callback:(AppDataCallback)callback;
- (void)searchUsersWithPhoneNumbers:(NSArray *)phoneNumbers
                           callback:(AppDataCallbackPagerElements)callback;

//--supplemental
// MD5 converter
- (NSString *)md5Conversion:(NSString *) input;
// Load Resource
- (void)loadResourceWithUrl:(NSURL *)url
         cacheStoragePolicy:(ASICacheStoragePolicy)cacheStoragePolicy
          forceAsynchronous:(BOOL)forceAsynchronous
                 completion:(void (^)(id result, BOOL cacheUsed, NSString *fileBackupPath, NSError *error))callback;
// time to string
- (NSString *)dateStringRelativeFromDateSince1970:(NSDate *)date;

- (void)startNotificationsPollingWithCallback:(AppDataCallback)callback;
- (void)stopNotificationsPolling;


// Pools
- (User *)getUserFromPoolWithInfo:(NSDictionary *)userInfo;
- (Media *)getMediaFromPoolWithID:(NSString *)theID;
- (Media *)getMediaFromPoolWithInfo:(NSDictionary *)postInfo;
- (User *)getUserFromPoolWithID:(NSString *)theID;

@property (strong, nonatomic) NSMapTable *cachedPoolOfMedia;
@property (strong, nonatomic) NSMapTable *cachedPoolOfUsers;

+ (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description;

@end
