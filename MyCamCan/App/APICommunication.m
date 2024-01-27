//
//  APICommunication.m
//  Blog
//
//  Created by James Ajhar on 4/29/13.
//  Copyright (c) 2013 James Ajhar. All rights reserved.
//
//  This is the primary class for dealing with the Blog API and database

#import "APICommunication.h"
#import <CommonCrypto/CommonDigest.h>
#import "AppData.h"
#import "ASIHTTPRequest.h"
#import "Reachability.h"
#import "LocalSession.h"
#import "Media.h"
#import "Media_Uploads.h"
#import "User.h"
#import "MusicItem.h"
#import "AppData_ModelInternal.h"

#import <AWSS3/AWSS3.h>


const NSTimeInterval defaultRequesTimeOutSeconds = 30;
const NSTimeInterval resourceRequesTimeOutSeconds = 60;

const time_t APIFirstPageCeilingTime = LONG_MAX;
__strong NSString * const APIFirstPageStart = @"";

@implementation APICommunication

+ (void)initialize {

}

+ (NSMutableDictionary *)convertJsonToDictionary:(NSData *)data {
	NSError *error = nil;
	id obj = [NSJSONSerialization
			  JSONObjectWithData:data
			  options:NSJSONReadingMutableLeaves | NSJSONReadingMutableContainers
			  error:&error];
	if (error !=nil) {
		NSLog(@"JSON was not parsed");
		NSLog(@"%@",error);
	}
	return obj;
}

+ (BOOL)validateAPIResult:(NSMutableDictionary *)result error:(NSError **)error {
    if (![result isKindOfClass:[NSDictionary class]]) {
        NSLog(@"This is %@, not %@",[result class],[NSDictionary class]);
        return YES;
    }

	NSNumber *errorCode = [result objectForKey:@"errorCode"];
    if(errorCode == nil)
        errorCode = [[result objectForKey:@"error"] objectForKey:@"errorCode"];
    
	if ((errorCode != nil) && (error != nil)) {
        NSString *message = [result objectForKey:@"message"] == nil ? [[result objectForKey:@"error"] objectForKey:@"message"] : [result objectForKey:@"message"];
		(*error) = [NSError errorWithDomain:kAppAPIErrorDomain code:[errorCode intValue] userInfo:[NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey]];
		return NO;
	}
	else
		return YES;
}

// register new user
+ (void)registerUserWithUsername:(NSString *)username
                        password:(NSString *)password
                           email:(NSString *)email
                       firstName:(NSString *)firstName
                        lastName:(NSString *)lastName
                           phone:(NSString *)phone
                        birthday:(NSDate *)birthday
                      completion:(BlogAPICompletionBlock)completion
                         failure:(BlogAPIFailureBlock)failure {
    
    NSURL *url = [URLs registerUser];
    
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          username, @"username",
                          password, @"password",
                          email, @"email",
                          phone, @"phone",
                          nil];
    
    NSLog(@"%@", url);
    NSLog(@"%@", data);
    
    [APICommunication sendPostRequestWithUrl:url
                                     andData:data
                                 requestType:POST
                                  completion:completion
                                     failure:failure
                                 cachePolicy:ASIUseDefaultCachePolicy];
}

// login
+ (void)loginWithEmail:(NSString *)email
              password:(NSString *)password
            completion:(BlogAPICompletionBlock)completion
               failure:(BlogAPIFailureBlock)failure {
    
    NSURL *url = [URLs loginUser];
    
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          email, @"username",
                          password, @"password",
                          nil];
    
    [APICommunication sendPostRequestWithUrl:url
                                     andData:data
                                 requestType:POST
                                  completion:completion
                                     failure:failure
                                 cachePolicy:ASIUseDefaultCachePolicy];
}

// login
+ (void)loginWithFacebookToken:(NSString *)token
            completion:(BlogAPICompletionBlock)completion
               failure:(BlogAPIFailureBlock)failure {
    
    NSURL *url = [URLs loginUserWithFacebook];
    
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          token, @"facebookToken",
                          nil];
    
    [APICommunication sendPostRequestWithUrl:url
                                     andData:data
                                 requestType:POST
                                  completion:completion
                                     failure:failure
                                 cachePolicy:ASIUseDefaultCachePolicy];
}


+ (void)verifyUsername:(NSString *)username completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs verifyUsername:username];
    
    NSLog(@"%@", url);
    
    [self sendGetRequestWithUrl:url
                     completion:completion
                        failure:failure
                    cachePolicy:ASIDoNotReadFromCacheCachePolicy|ASIDoNotWriteToCacheCachePolicy
             cacheStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
}

+ (void)getFeaturedArtistMusicWithCompletion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs getFeaturedArtistMusic];
    
    NSLog(@"%@", url);
    
    [self sendGetRequestWithUrl:url
                     completion:completion
                        failure:failure
                    cachePolicy:ASIDoNotReadFromCacheCachePolicy|ASIDoNotWriteToCacheCachePolicy
             cacheStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
}

+ (void)getTopMusicWithCompletion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs getTopMusic];
    
    NSLog(@"%@", url);
    
    [self sendGetRequestWithUrl:url
                     completion:completion
                        failure:failure
                    cachePolicy:ASIDoNotReadFromCacheCachePolicy|ASIDoNotWriteToCacheCachePolicy
             cacheStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
}

// login
+ (void)changePassword:(NSString *)newPassword completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
}

// Update user's device id in database
+ (void) updateUserDeviceId:(NSString*)deviceId completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs updateUser];
    
    NSLog(@"%@", url);
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:deviceId
                                                     forKey:@"deviceToken"] ;
    NSLog(@"%@", data);

    
    [self sendPostRequestWithUrl:url
                         andData:data
                     requestType:PUT
                      completion:completion
                         failure:failure
                     cachePolicy:ASIUseDefaultCachePolicy];
}

// Forgot password
+ (void)sendForgotPasswordRequestWithEmail:(NSString*)email completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs recoverPassword:email];
    
    NSLog(@"%@", url);
        
    [self sendPostRequestWithUrl:url
                         andData:@{}
                     requestType:POST
                      completion:completion
                         failure:failure
                     cachePolicy:ASIUseDefaultCachePolicy];
}

// Get Profile info of user with id
+ (void)getProfile:(User *)user
       forceReload:(BOOL)forceReload
        completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    
    NSURL *url = [URLs getUserProfileWithUserId:user.theId];
    
    NSLog(@"%@", url);
    
    [self sendGetRequestWithUrl:url
                     completion:completion
                        failure:failure
                    cachePolicy:ASIDoNotReadFromCacheCachePolicy|ASIDoNotWriteToCacheCachePolicy
             cacheStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
}

+ (void)blockUser:(User *)user completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs blockUser:user.theId];
    
    NSLog(@"%@", url);
    
    [self sendPostRequestWithUrl:url
                         andData:@{}
                     requestType:POST
                      completion:completion
                         failure:failure
                     cachePolicy:ASIUseDefaultCachePolicy];
}

+ (void)unblockUser:(User *)user completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs blockUser:user.theId];
    
    NSLog(@"%@", url);
    
    [self sendPostRequestWithUrl:url
                         andData:@{}
                     requestType:DELETE
                      completion:completion
                         failure:failure
                     cachePolicy:ASIUseDefaultCachePolicy];
}

+ (void)getMediaForUser:(User *)user
             dateOffset:(NSString *)dateOffset
             completion:(BlogAPICompletionBlock)completion
                failure:(BlogAPIFailureBlock)failure
{
    NSURL *url = [URLs getMediaForUserWithId:user.theId dateOffset:dateOffset];
    
    NSLog(@"%@", url);
    
    [self sendGetRequestWithUrl:url
                     completion:completion
                        failure:failure
                    cachePolicy:ASIDoNotReadFromCacheCachePolicy|ASIDoNotWriteToCacheCachePolicy
             cacheStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
}


// Update user profile image
+ (void) updateAvatarWithPhoto:(NSData *)photo andFileName:(NSString*)fileName completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
	}


// Update user information
+ (void) updateUserInfoWithFirstName:(NSString *)firstName
                            lastName:(NSString *)lastName
                                 bio:(NSString *)bio
                          genderType:(GenderType)genderType
                            hometown:(NSString *)hometown
                            birthday:(NSDate *)birthday
                          completion:(BlogAPICompletionBlock)completion
                             failure:(BlogAPIFailureBlock)failure {
   
}

+ (void)getNotificationsWithDateOffset:(NSString *)dateOffset
                                 limit:(NSUInteger)limit
                            completion:(BlogAPICompletionBlock)completion
                               failure:(BlogAPIFailureBlock)failure
{
    NSURL *url = [URLs getNotificationsWithDateOffset:dateOffset];
    
    NSLog(@"%@", url);
    
    [self sendGetRequestWithUrl:url
                     completion:completion
                        failure:failure
                    cachePolicy:ASIDoNotReadFromCacheCachePolicy|ASIDoNotWriteToCacheCachePolicy
             cacheStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
}

+ (void)likeMedia:(Media *)media completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs likeMedia];
    
    NSLog(@"%@", url);
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:media.theId
                                                     forKey:@"mediaId"] ;
    
    [self sendPostRequestWithUrl:url
                         andData:data
                     requestType:POST
                      completion:completion
                         failure:failure
                     cachePolicy:ASIUseDefaultCachePolicy];
}

+ (void)deleteMedia:(Media *)media completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs deleteMedia:media.theId];
    
    NSLog(@"%@", url);
    
    [self sendPostRequestWithUrl:url
                         andData:[NSDictionary new]
                     requestType:DELETE
                      completion:completion
                         failure:failure
                     cachePolicy:ASIUseDefaultCachePolicy];
}

+ (void)getLikesForMedia:(Media *)media dateOffset:(NSString *)dateOffset completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs getLikesForMediaId:media.theId dateOffset:dateOffset];
    
    NSLog(@"%@", url);
    
    [self sendGetRequestWithUrl:url
                     completion:completion
                        failure:failure
                    cachePolicy:ASIDoNotReadFromCacheCachePolicy|ASIDoNotWriteToCacheCachePolicy
             cacheStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
}

+ (void)getMediaWithId:(NSString *)mediaId completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs getMediaWithId:mediaId];
    
    NSLog(@"%@", url);
    
    [self sendGetRequestWithUrl:url
                     completion:completion
                        failure:failure
                    cachePolicy:ASIDoNotReadFromCacheCachePolicy|ASIDoNotWriteToCacheCachePolicy
             cacheStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
}

+ (void)getFollowersForUser:(User *)user
                 withOffset:(NSInteger)offset
                 completion:(BlogAPICompletionBlock)completion
                    failure:(BlogAPIFailureBlock)failure {
    
    NSURL *url = [URLs getFollowersOfUser:user.theId withOffset:offset];
    
    NSLog(@"%@", url);
    
    [self sendGetRequestWithUrl:url
                     completion:completion
                        failure:failure
                    cachePolicy:ASIDoNotReadFromCacheCachePolicy|ASIDoNotWriteToCacheCachePolicy
             cacheStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
}

+ (void)getFolloweesForUser:(User *)user
                 withOffset:(NSInteger)offset
                 completion:(BlogAPICompletionBlock)completion
                    failure:(BlogAPIFailureBlock)failure {
    
    NSURL *url = [URLs getFolloweesOfUser:user.theId withOffset:offset];
    
    NSLog(@"%@", url);
    
    [self sendGetRequestWithUrl:url
                     completion:completion
                        failure:failure
                    cachePolicy:ASIDoNotReadFromCacheCachePolicy|ASIDoNotWriteToCacheCachePolicy
             cacheStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
    
   
}

// Stop Following User
+ (void) stopFollowingUser:(User *)user completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs followUserWithId:user.theId];
    
    NSLog(@"%@", url);
    
    NSDictionary *data = [NSDictionary new] ;
    
    [self sendPostRequestWithUrl:url
                         andData:data
                     requestType:DELETE
                      completion:completion
                         failure:failure
                     cachePolicy:ASIUseDefaultCachePolicy];
}

// Start Following User
+ (void) startFollowingUser:(User *)user completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs followUserWithId:user.theId];
    
    NSLog(@"%@", url);
    
    NSDictionary *data = [NSDictionary new] ;

    [self sendPostRequestWithUrl:url
                         andData:data
                     requestType:POST
                      completion:completion
                         failure:failure
                     cachePolicy:ASIUseDefaultCachePolicy];
}

+ (void)getFeedWithOffset:(NSInteger)offset completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs getFeedWithOffset:offset];
    
    NSLog(@"%@", url);
    
    [self sendGetRequestWithUrl:url
                     completion:completion
                        failure:failure
                    cachePolicy:ASIDoNotReadFromCacheCachePolicy|ASIDoNotWriteToCacheCachePolicy
             cacheStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
}

+ (void)getGlobalFeedWithOffset:(NSString *)offset completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs getGlobalFeedWithDateOffset:offset];
    
    NSLog(@"%@", url);
    
    [self sendGetRequestWithUrl:url
                     completion:completion
                        failure:failure
                    cachePolicy:ASIDoNotReadFromCacheCachePolicy|ASIDoNotWriteToCacheCachePolicy
             cacheStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
}

// Create Comment
+ (void)createComment:(Comment *)comment completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
   
}

+ (void)searchMusicWithKeyword:(NSString *)keyword completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs searchMusicWithKeyword:keyword];
    
    NSLog(@"%@", url);
    
    [self sendGetRequestWithUrl:url
                     completion:completion
                        failure:failure
                    cachePolicy:ASIDoNotReadFromCacheCachePolicy|ASIDoNotWriteToCacheCachePolicy
             cacheStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
}

+ (void)searchUsersWithKeyword:(NSString *)keyword completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs searchUsersWithKeyword:keyword];
    
    NSLog(@"%@", url);
    
    [self sendGetRequestWithUrl:url
                     completion:completion
                        failure:failure
                    cachePolicy:ASIDoNotReadFromCacheCachePolicy|ASIDoNotWriteToCacheCachePolicy
             cacheStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
}

+ (void)searchTotalUsersForPhoneNumbers:(NSArray *)phoneNumbers completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs getTotalUsersForPhoneNumbers];
    
    NSLog(@"%@", url);
    
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          phoneNumbers, @"phoneNumbers",
                          nil];
    
    [self sendPostRequestWithUrl:url
                         andData:data
                     requestType:POST
                      completion:completion
                         failure:failure
                     cachePolicy:ASIUseDefaultCachePolicy];
}

+ (void)searchUsersWithPhoneNumbers:(NSArray *)phoneNumbers completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs searchUsersWithPhoneNumbers];
    
    NSLog(@"%@", url);
    
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          phoneNumbers, @"phoneNumbers",
                          nil];
    
    NSLog(@"%@", data);

    
    [self sendPostRequestWithUrl:url
                         andData:data
                     requestType:POST
                      completion:completion
                         failure:failure
                     cachePolicy:ASIUseDefaultCachePolicy];
}

/*
+ (void)sendPushNotificationsToUsers:(NSArray *)users withMessage:(NSString *)message completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSMutableString *pushDevices = [NSMutableString new];
	
    for (User *user in users) {
		if ([user.deviceToken length] != 0 && ![user.deviceToken isEqualToString:[AppData sharedInstance].localUser.deviceToken])
            [pushDevices appendFormat:@"\"%@\", ", user.deviceToken];
	}
    
	NSUInteger length = pushDevices.length;
	if (length > 2)
		[pushDevices deleteCharactersInRange:NSMakeRange(length - 2, 2)];

    NSString *queryString = @"https://go.urbanairship.com/api/push/";
    NSURL *url = [NSURL URLWithString:[queryString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSString *dataString = [NSString stringWithFormat:@"{\"device_tokens\":[%@], \"aps\": {\"badge\":\"+1\", \"alert\":\"%@\", \"sound\":\"default\"}}", pushDevices, message];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url andCachePolicy:(ASIDoNotWriteToCacheCachePolicy | ASIDoNotReadFromCacheCachePolicy)];
    
    [request addBasicAuthenticationHeaderWithUsername:[URLs urbanAirshipKey] andPassword:[URLs urbanAirshipMasterSecret]];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    [request appendPostData:[NSData dataWithBytes:[dataString UTF8String] length:[dataString length]]];
    
    __block ASIHTTPRequest *blockRequest = request;
    if (completion != NULL) {
        [request setCompletionBlock:^{
            NSLog(@"notifications sent");
           // NSLog(@"%@", [self convertJsonToDictionary:[blockRequest responseData]]);
            completion([blockRequest responseData]);
            blockRequest = nil;
        }];
    }
    if (failure != NULL) {
        [request setFailedBlock:^{
            NSLog(@"notifications failed to send");
            failure([blockRequest error]);
            blockRequest = nil;
        }];
    }
    [request startForceAsynchronous:NO];
}*/
/*
+ (void)setUrbanAirshipBadge:(NSString *)badgeCount completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSString *queryString = [NSString stringWithFormat:@"https://go.urbanairship.com/api/device_tokens/%@", [AppData sharedInstance].localUser. deviceToken];
    NSURL *url = [NSURL URLWithString:[queryString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSString *dataString = [NSString stringWithFormat:@"{\"badge\":%@}", badgeCount];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url andCachePolicy:(ASIDoNotWriteToCacheCachePolicy | ASIDoNotReadFromCacheCachePolicy)];
    
    NSLog(@"%@", queryString);
    NSLog(@"%@", dataString);
    
    [request addBasicAuthenticationHeaderWithUsername:[URLs urbanAirshipKey] andPassword:[URLs urbanAirshipMasterSecret]];
    //[request addRequestHeader:@"Content-Type" value:@"application/json"];
    [request setRequestMethod:@"PUT"];
    [request appendPostData:[NSData dataWithBytes:[dataString UTF8String] length:[dataString length]]];
    
    __block ASIHTTPRequest *blockRequest = request;
    if (completion != NULL) {
        [request setCompletionBlock:^{
            NSLog(@"UA badge updated %@", [blockRequest responseData]);
            NSLog(@"%@", [self convertJsonToDictionary:[blockRequest responseData]]);
            completion([blockRequest responseData]);
            blockRequest = nil;
        }];
    }
    if (failure != NULL) {
        [request setFailedBlock:^{
            NSLog(@"UA badge failed to update");
            failure([blockRequest error]);
            blockRequest = nil;
        }];
    }
    [request startForceAsynchronous:NO];
}*/

#pragma mark - Amazon S3Uploader + API Uploading

+ (void)uploadMedia:(Media *)media
            fileURL:(NSURL *)fileURL
		forKey:(NSString *)key
	completion:(BlogAPICompletionBlock)completion
	  progress:(BlogAPIProgressBlock)progress
	   failure:(BlogAPIFailureBlock)failure {
    
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = [URLs s3BucketKey];
    
    [APICommunication generateImage:fileURL
                         completion:^(NSURL *thumbImageURL, NSString *thumbKey, NSError *error)
    {
                             
                             
         if(error) {
             failure(error);
             return;
         }
         
         uploadRequest.body = thumbImageURL;
         uploadRequest.key = thumbKey;
        
            media.thumbName = thumbKey;
        
         AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
         
         [[transferManager upload:uploadRequest] continueWithExecutor:[AWSExecutor mainThreadExecutor]
                                                            withBlock:^id(AWSTask *task)
         {
                                                                
             if (task.error != nil) {
                NSLog(@"%s %@","Error Uploading Thumbnail:", uploadRequest.key);
                NSLog(@"Error: %@", task.error);
                failure(task.error);
                return nil;
             }
                                                            
            NSLog(@"Thumbnail Upload Completed");
             
             AWSS3TransferManagerUploadRequest *uploadRequest2 = [AWSS3TransferManagerUploadRequest new];
             uploadRequest2.bucket = [URLs s3BucketKey];

            uploadRequest2.key = key;
            uploadRequest2.body = fileURL;


            uploadRequest2.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
                CGFloat progressValue = (CGFloat)(totalBytesSent * 100 / totalBytesExpectedToSend);
                progress(progressValue/100, totalBytesSent, totalBytesExpectedToSend);
            };
             
             [[transferManager upload:uploadRequest2] continueWithExecutor:[AWSExecutor mainThreadExecutor]
                                                                   withBlock:^id(AWSTask *task2)
                {
                                                                       
                                                                       if (task2.error != nil) {
                                                                           NSLog(@"%s %@","Error uploading :", uploadRequest2.key);
                                                                           NSLog(@"Error: %@", task.error);
                                                                           failure(task2.error);
                                                                       } else {
                                                                           NSLog(@"Upload completed");
                                                                           
                                                                           completion(nil);
                                                                       }
                                                                       
                                                                       return nil;
                }];
             
             
             return nil;
         }];
        
                             
                             
                            
    }];
    
    
    
}

+ (void)upload:(NSURL *)fileURL
        forKey:(NSString *)key
    completion:(BlogAPICompletionBlock)completion
      progress:(BlogAPIProgressBlock)progress
       failure:(BlogAPIFailureBlock)failure {
    
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = [URLs s3BucketKey];
    uploadRequest.key = key;
    uploadRequest.body = [NSURL fileURLWithPath:[fileURL path]];
    
    uploadRequest.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        CGFloat progressValue = (CGFloat)(totalBytesSent * 100 / totalBytesExpectedToSend);
        progress(progressValue/100, totalBytesSent, totalBytesExpectedToSend);
    };
    
    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    
    [[transferManager upload:uploadRequest] continueWithExecutor:[AWSExecutor mainThreadExecutor]
                                                       withBlock:^id(AWSTask *task) {
                                                           
                                                           if (task.error != nil) {
                                                               NSLog(@"%s %@","Error uploading :", uploadRequest.key);
                                                               NSLog(@"Error: %@", task.error);
                                                               failure(task.error);
                                                           } else {
                                                               NSLog(@"Upload completed");
                                                               
                                                               completion(nil);
                                                           }
                                                           
                                                           return nil;
                                                       }];
}


+ (void)generateImage:(NSURL *)url completion:(BlogVideoThumbnailBlock)completion
{
    AVURLAsset *asset=[[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform=TRUE;

    CMTime thumbTime = CMTimeMakeWithSeconds(0,30);
    
    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result != AVAssetImageGeneratorSucceeded) {
            NSLog(@"couldn't generate thumbnail, error:%@", error);
        }

        UIImage *thumbImg = [UIImage imageWithCGImage:im];
        
        NSString *key = [[AppData sharedInstance] md5Conversion:[NSString stringWithFormat:@"%lu.png", (unsigned long)[thumbImg hash]]];
        
        NSString* path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                              NSUserDomainMask,
                                                              YES) lastObject];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@.png", path, key];
        [UIImageJPEGRepresentation(thumbImg, 0.7) writeToFile:filePath atomically:YES];
        
        NSLog(@"Thumbnail image data: %li", [UIImagePNGRepresentation(thumbImg) length]);
        NSLog(@"Video thumbnail created: %@", filePath);
        
        completion([NSURL fileURLWithPath:filePath], key, error);
    };
    
    CGSize maxSize = CGSizeMake(640, 640);
    generator.maximumSize = maxSize;
    [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:handler];
    
}

+ (void)updateMedia:(Media *)media completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs updateMedia:media.theId];
    
    NSLog(@"%@", url);
    
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          media.caption, @"caption",
                          media.linkURL.absoluteString, @"link",
                          nil];
    
    NSLog(@"data: %@", data);
    
    [self sendPostRequestWithUrl:url
                         andData:data
                     requestType:PUT
                      completion:completion
                         failure:failure
                     cachePolicy:ASIUseDefaultCachePolicy];
}

+ (void)updateAvatarWithFileName:(NSString *)fileName completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs updateUser];
    
    NSLog(@"%@", url);
    
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          fileName, @"avatar",
                          nil];
    
    [self sendPostRequestWithUrl:url
                         andData:data
                     requestType:PUT
                      completion:completion
                         failure:failure
                     cachePolicy:ASIUseDefaultCachePolicy];
}

+ (void)updateCoverWithFileName:(NSString *)fileName completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs updateUser];
    
    NSLog(@"%@", url);
    
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          fileName, @"coverPhoto",
                          nil];
    
    [self sendPostRequestWithUrl:url
                         andData:data
                     requestType:PUT
                      completion:completion
                         failure:failure
                     cachePolicy:ASIUseDefaultCachePolicy];
}

+ (void)updatePassword:(NSString *)password token:(NSString *)token completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs updatePassword];
    
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          token, @"token",
                          password, @"newPassword",
                          nil];
    NSLog(@"%@", url);
    NSLog(@"%@", data);
    
    [self sendPostRequestWithUrl:url
                         andData:data
                     requestType:POST
                      completion:completion
                         failure:failure
                     cachePolicy:ASIUseDefaultCachePolicy];
}

// MCC API Save Media After Upload
+ (void)saveMediaToDatabase:(Media *)media filename:(NSString *)filename thumbName:(NSString *)thumbName completion:(BlogAPICompletionBlock)completion failure:(BlogAPIFailureBlock)failure {
    NSURL *url = [URLs saveMediaToDB];

    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          filename, @"fileName",
                          thumbName, @"thumbName",
                          [AppData sharedInstance].localUser.theId, @"ownerId",
                          [media.musicItem.previewURL absoluteString], @"musicUrl",   // note: orName cannot be blank or nil
                          nil];
    
    NSLog(@"%@", url);
    NSLog(@"%@", data);

    
    [APICommunication sendPostRequestWithUrl:url
                                     andData:data
                                 requestType:POST
                                  completion:completion
                                     failure:failure
                                 cachePolicy:ASIUseDefaultCachePolicy];
}


#pragma mark - API GET and POST request methods

+ (void)sendGetRequestWithUrl:(NSURL *)url
				   completion:(BlogAPICompletionBlock)completion
					  failure:(BlogAPIFailureBlock)failure
				  cachePolicy:(ASICachePolicy)cachePolicy
		   cacheStoragePolicy:(ASICacheStoragePolicy)cacheStoragePolicy {
    
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
    request.timeOutSeconds = defaultRequesTimeOutSeconds;

	[request setCacheStoragePolicy:cacheStoragePolicy];
	__block ASIHTTPRequest *blockRequest = request;
    
    [request addRequestHeader:@"Accept" value:@"application/json"];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    [request setValidatesSecureCertificate:NO];
    [APICommunication addApplicationHeaders:request];

    if (completion != NULL) {
        [request setCompletionBlock:^{
            completion([blockRequest responseData]);
			blockRequest = nil;
        }];
    }
	if (failure != NULL) {
		[request setFailedBlock:^{
			failure([blockRequest error]);
			blockRequest = nil;
		}];
	}
	[request startAsynchronous];
}

+ (void)sendGetRequestWithUrl:(NSURL *)url
				  completion2:(BlogAPICompletion2Block)completion
					  failure:(BlogAPIFailureBlock)failure
				  cachePolicy:(ASICachePolicy)cachePolicy
		   cacheStoragePolicy:(ASICacheStoragePolicy)cacheStoragePolicy {
    
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
    request.timeOutSeconds = defaultRequesTimeOutSeconds;

	[request setCacheStoragePolicy:cacheStoragePolicy];
	__block ASIHTTPRequest *blockRequest = request;
	
    [request addRequestHeader:@"Accept" value:@"application/json"];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    [request setValidatesSecureCertificate:NO];
    [APICommunication addApplicationHeaders:request];

    if (completion != NULL) {
        [request setCompletionBlock:^{
            completion([blockRequest responseData], [blockRequest didUseCachedResponse]);
			blockRequest = nil;
        }];
    }
	if (failure != NULL) {
		[request setFailedBlock:^{
			failure([blockRequest error]);
			blockRequest = nil;
		}];
	}
    [request startAsynchronous];
}

+ (ASIHTTPRequest *)sendPostRequestWithUrl:(NSURL*)url
andData:(NSDictionary*)data requestType:(requestType)type
completion:(BlogAPICompletionBlock)completion
failure:(BlogAPIFailureBlock)failure
cachePolicy:(ASICachePolicy)cachePolicy {
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
    request.timeOutSeconds = defaultRequesTimeOutSeconds;

	[request setCacheStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	__block ASIHTTPRequest *blockRequest = request;
    
    [request addRequestHeader:@"Accept" value:@"application/json"];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    [request setValidatesSecureCertificate:NO];
    [APICommunication addApplicationHeaders:request];

    if(data) {
        NSData *postData = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
        [request appendPostData:postData];
    }
    [request buildPostBody];
    
    switch (type) {
        case DELETE:
            [request setRequestMethod:@"DELETE"];
            break;
        case PUT:
            [request setRequestMethod:@"PUT"];
            break;
        default:
            break;
    }
    
    if (completion != NULL) {
        [request setCompletionBlock:^{
            completion([blockRequest responseData]);
			blockRequest = nil;
        }];
    }
	if (failure != NULL) {
		[request setFailedBlock:^{
			failure([blockRequest error]);
			blockRequest = nil;
		}];
	}
    [request startAsynchronous];

	return request;
}


+ (ASIHTTPRequest *)sendAuthenticationPostRequestWithUrl:(NSURL*)url
                                                 andData:(NSDictionary*)data
                                                username:(NSString *)username
                                                password:(NSString *)password
                                             requestType:(requestType)type
                                              completion:(BlogAPICompletionBlock)completion
                                                 failure:(BlogAPIFailureBlock)failure
                                             cachePolicy:(ASICachePolicy)cachePolicy {
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
    request.timeOutSeconds = defaultRequesTimeOutSeconds;
    
	[request setCacheStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	__block ASIHTTPRequest *blockRequest = request;
    
    [request addRequestHeader:@"Accept" value:@"application/json"];
    [request setValidatesSecureCertificate:NO];
    [APICommunication addApplicationHeaders:request];

    if (data) {
        NSData *postData = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
        [request appendPostData:postData];
    }
    [request buildPostBody];
    
    switch (type) {
        case DELETE:
            [request setRequestMethod:@"DELETE"];
            break;
        case PUT:
            [request setRequestMethod:@"PUT"];
            break;
        default:	
            break;
    }
    
    if (completion != NULL) {
        [request setCompletionBlock:^{
            completion([blockRequest responseData]);
			blockRequest = nil;
        }];
    }
	if (failure != NULL) {
		[request setFailedBlock:^{
			failure([blockRequest error]);
			blockRequest = nil;
		}];
	}
    [request startAsynchronous];
    
	return request;
}

/**
 
 Adds the app Bundle ID and Short Version to the header using the folowing key names:
 
 appId
 appVersion
 
 NOTE: this method must be called for all outgoing HTTP Request to the MCC APIs.
 
 This is done so that the API can distinguish versions and platforms of the native clients and, optionally, provide specific behavior.
 
 */
+ (void) addApplicationHeaders:(ASIHTTPRequest *)request
{
    if ( request == nil )
    {
        NSLog(@"%s - parameter 'request' cannot be nil.", __FUNCTION__);
        return; // early return
    }
    
    NSDictionary * infoDict = [[NSBundle bundleForClass:[self class] ] infoDictionary];
    
    if ( infoDict != nil )
    {
        if([AppData sharedInstance].localSession.oauthToken != nil) {
            NSLog(@"token: %@", [AppData sharedInstance].localSession.oauthToken);
            [request addRequestHeader:@"token"  value:[NSString stringWithFormat:@"%@", [AppData sharedInstance].localSession.oauthToken]];
        }
    }
}

@end
