//  Use this file to hold all urls (and related constant info) in use throughout the app

#import <Foundation/Foundation.h>


@interface URLs : NSObject

+ (NSURL *)baseUrl;

+ (NSURL *)registerUser;

+ (NSURL *)loginUser;

+ (NSURL *)loginUserWithFacebook;

+ (NSURL *)blockUser:(NSString *)userId;

+ (NSURL *)recoverPassword:(NSString *)email;

+ (NSURL *)updatePassword;

+ (NSURL *)verifyUsername:(NSString *)username;

+ (NSURL *)searchMusicWithKeyword:(NSString *)keyword;

+ (NSURL *)getFeaturedArtistMusic;

+ (NSURL *)searchUsersWithKeyword:(NSString *)keyword;

+ (NSURL *)getTopMusic;

+ (NSURL *)getTotalUsersForPhoneNumbers;

+ (NSURL *)searchUsersWithPhoneNumbers;

+ (NSURL *)getUserProfileWithUserId:(NSString *)userId;

+ (NSURL *)getMediaWithId:(NSString *)mediaId;

+ (NSURL *)getMediaForUserWithId:(NSString *)userId dateOffset:(NSString *)dateOffset;

+ (NSURL *)getNotificationsWithDateOffset:(NSString *)dateOffset;

+ (NSURL *)updateUser;

+ (NSURL *)updateMedia:(NSString *)mediaId;

+ (NSURL *)saveMediaToDB;

+ (NSURL *)likeMedia;

+ (NSURL *)deleteMedia:(NSString *)mediaId;

+ (NSURL *)getLikesForMediaId:(NSString *)mediaId dateOffset:(NSString *)dateOffset;

+ (NSURL *)followUserWithId:(NSString *)userId;

+ (NSURL *)getFeedWithOffset:(NSInteger)offset;

+ (NSURL *)getGlobalFeedWithDateOffset:(NSString *)offset;

+ (NSURL *)getFollowersOfUser:(NSString *)userId withOffset:(NSInteger)offset;

+ (NSURL *)getFolloweesOfUser:(NSString *)userId withOffset:(NSInteger)offset;

+ (NSURL *)cdn;

+ (NSURL *)s3CDN;

+ (NSString *)s3AccessKey;

+ (NSString *)s3SecretKey;

+ (NSString *)s3BucketKey;

+ (NSString *)domainId;

+ (NSString *)urbanAirshipKey;

+ (NSString *)urbanAirshipMasterSecret;

@end
