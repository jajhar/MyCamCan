// api.MCC.com
// MCCapi-uat.elasticbeanstalk.com   - demo
// stagingMCCapi-env.elasticbeanstalk.com - staging (release)
// devMCCapi-env.elasticbeanstalk.com

#import "URLs.h"

static NSURL *RS_NET_BaseUrl = nil;

@implementation URLs

+ (void)initialize {

    RS_NET_BaseUrl = [NSURL URLWithString:[@"http://mycamcan.com:8080" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
//    RS_NET_BaseUrl = [NSURL URLWithString:[@"http://localhost:8080" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    
}

+ (NSURL *)baseUrl {
    return RS_NET_BaseUrl;
}

+ (NSURL *)registerUser {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/user/profile", [URLs baseUrl]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

}

+ (NSURL *)recoverPassword:(NSString *)email {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/resetpassword?email=%@", [URLs baseUrl], email] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
}

+ (NSURL *)blockUser:(NSString *)userId {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/user/%@/block", [URLs baseUrl], userId] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)loginUser {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/login", [URLs baseUrl]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)loginUserWithFacebook {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/loginWithFacebook", [URLs baseUrl]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)verifyUsername:(NSString *)username {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/verify/username/%@", [URLs baseUrl], username] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)searchMusicWithKeyword:(NSString *)keyword {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/search/music/%@", [URLs baseUrl], keyword] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)getFeaturedArtistMusic {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/song", [URLs baseUrl]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)searchUsersWithKeyword:(NSString *)keyword {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/search/user/%@", [URLs baseUrl], keyword] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)getTopMusic {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/music/top", [URLs baseUrl]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)getTotalUsersForPhoneNumbers {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/search/user/friend/count", [URLs baseUrl]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)searchUsersWithPhoneNumbers {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/search/user/phone", [URLs baseUrl]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)getUserProfileWithUserId:(NSString *)userId {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/user/%@/profile", [URLs baseUrl], userId] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)getMediaForUserWithId:(NSString *)userId dateOffset:(NSString *)dateOffset{
    
    if(dateOffset != nil && dateOffset.length > 0) {
        return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/user/%@/media?dateOffset=%@", [URLs baseUrl], userId, dateOffset] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/user/%@/media", [URLs baseUrl], userId] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)updateUser {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/user", [URLs baseUrl]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)updatePassword {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/updatepassword", [URLs baseUrl]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)updateMedia:(NSString *)mediaId {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/media/%@", [URLs baseUrl], mediaId] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)saveMediaToDB {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/media", [URLs baseUrl]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)likeMedia {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/like", [URLs baseUrl]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)deleteMedia:(NSString *)mediaId {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/user/media/%@", [URLs baseUrl], mediaId] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)getLikesForMediaId:(NSString *)mediaId dateOffset:(NSString *)dateOffset{
    if(dateOffset != nil && dateOffset.length > 0) {
        return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/likes/%@?dateOffset=%@", [URLs baseUrl], mediaId, dateOffset] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }

    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/likes/%@", [URLs baseUrl], mediaId] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)followUserWithId:(NSString *)userId {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/user/follow/%@", [URLs baseUrl], userId] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)getFollowersOfUser:(NSString *)userId withOffset:(NSInteger)offset{
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/user/%@/followers?offset=%lu", [URLs baseUrl], userId, offset] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)getFolloweesOfUser:(NSString *)userId withOffset:(NSInteger)offset{
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/user/%@/followees?offset=%lu", [URLs baseUrl], userId, offset] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)getMediaWithId:(NSString *)mediaId {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/media/%@", [URLs baseUrl], mediaId] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)getFeedWithOffset:(NSInteger)offset {
    
        return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/feed?offset=%lu", [URLs baseUrl], offset] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)getGlobalFeedWithDateOffset:(NSString *)offset {
    
    if(offset != nil && offset.length > 0) {
        return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/feed/global?dateOffset=%@", [URLs baseUrl], offset] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/feed/global", [URLs baseUrl]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)getNotificationsWithDateOffset:(NSString *)dateOffset {
    if(dateOffset != nil && dateOffset.length > 0) {
        return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/notifications?dateOffset=%@", [URLs baseUrl], dateOffset] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@/notifications", [URLs baseUrl]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSURL *)cdn {
    return nil;
}

+ (NSString *)s3CDN {
    return @"http://d1mu8eaey2y66n.cloudfront.net";
}

+ (NSString *)s3AccessKey {
    return @"";
}

+ (NSString *)s3SecretKey {
    return @"";
}

+ (NSString *)s3BucketKey {
    return @"mycamcanbucket";
}

+ (NSString *)domainId {
    return @"";
}

+ (NSString *)urbanAirshipKey {
    return @"";
}

+ (NSString *)urbanAirshipMasterSecret {
    return @"";
}



@end
