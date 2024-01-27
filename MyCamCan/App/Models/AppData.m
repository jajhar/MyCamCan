//
//  AppData.m
//  Zum 2.0
//
//  Created by James Ajhar on 4/30/13.
//  Copyright (c) 2013 James Ajhar. All rights reserved.
//

#import "AppData.h"
#import "AppData_ModelInternal.h"
#import "APICommunication.h"
#import <CommonCrypto/CommonDigest.h>
#import "Keychain.h"
#import "Media.h"
#import "LocalSession.h"
#import "ProfileMediaPager.h"
#import "Pager_ModelInternal.h"
#import "URLs.h"
#import "User.h"
#import "Like.h"
#import "User_ModelInternal.h"
#import "MusicItem.h"
#import "SSKeychain.h"
#import "Notification.h"

static AppData *_sharedInstance = nil;


//--notifications
/**
 must have "media" key in userInfo
 */
NSString * const kAppData_Notification_CommentsListChanged = @"kVDN_CL_Changed";
/**
 must have "media", "count" keys in userInfo
 */
NSString * const kAppData_Notification_CommentsListAppended = @"kVDN_CL_Appended";
/**
 userInfo is nil
 */
NSString * const kAppData_Notification_FeedChanged = @"kVDN_F_Changed";

NSString * const kAppData_Notification_ProfileMediaChanged = @"kVDN_PM_Changed";
/**
 must have "count" key in userInfo
 */
NSString * const kAppData_Notification_FeedAppended = @"kVDN_F_Appended";
/**
 must have "index" key in userInfo
 */
NSString * const kAppData_Notification_FeedDeleted = @"kVDN_F_Deleted";
/**
 must have "media" key in userInfo
 */
NSString * const kAppData_Notification_MediaUpdated = @"kVDN_M_Updated";
/**
 must have "user" key in userInfo
 */
NSString * const kAppData_Notification_UserUpdated = @"kVDN_U_Updated";
NSString * const kAppData_Notification_UserMediasChanged = @"kVDN_UM_Changed";   // "user"
NSString * const kAppData_Notification_UserMediasAppended = @"kVDN_UM_Appended"; // "user", "count"
NSString * const kAppData_Notification_UserMediaDeleted = @"kVDN_UM_Deleted";    // "user", "index"
NSString * const kAppData_Notification_NotificationsReceived = @"kBG_N_Received";

// notification keys
NSString * const kAppData_NotificationKey_User = @"user";
NSString * const kAppData_NotificationKey_Media = @"media";
NSString * const kAppData_NotificationKey_Count = @"count";
NSString * const kAppData_NotificationKey_Index = @"index";
NSString * const kAppData_NotificationKey_TotalFlag = @"total";

// pagers
NSString * const kAppData_Notification_Pager_Subscribers = @"kVDN_P_Subscribers";
NSString * const kAppData_Notification_Pager_Comments = @"kVDN_P_Comments";
NSString * const kAppData_Notification_Pager_Feed = @"kVDN_P_Feed";
NSString * const kAppData_Notification_Pager_Likes = @"kVDN_P_Likes";
NSString * const kAppData_Notification_Pager_Medias = @"kVDN_P_Medias";
NSString * const kAppData_Notification_Pager_Notifications = @"kVDN_P_Notifications";
NSString * const kAppData_Notification_Pager_Followers = @"kVDN_P_Followers";
NSString * const kAppData_Notification_Pager_Following = @"kVDN_P_Following";
NSString * const kAppData_Notification_Pager_Search = @"kVDN_P_Search";

NSString *kBGKeyUser = @"BGKeyUser";
NSString *kBGKeyMedia = @"BGKeyMedia";
NSString *kBGKeyURL = @"BGKeyURL";
NSString *kBGKeyImagePickerDelegate = @"BGKeyImagePickerDelegate";
NSString *kBGInfoMusicItem = @"BGInfoMusicItem";


@interface AppData()
{
    //--state
    NSTimer *_pollTimer;
    
    //--supplement
    NSCalendar *_calendarEN_US;
    
}

@end


@implementation AppData

@synthesize localUser = _localUser;
@synthesize localSession = _localSession;
@synthesize deviceToken = _deviceToken;

#pragma mark - Singleton


// Get the shared instance and create it if necessary.
+ (AppData *)sharedInstance {
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{
        _sharedInstance = [[AppData alloc] init];
    });
    return _sharedInstance;
}


+ (id)alloc {
	@synchronized([AppData class]) {
		NSAssert(_sharedInstance == nil, @"Attempted to create second instance of Singleton");
		_sharedInstance = [super alloc];
		return _sharedInstance;
	}
	return nil;
}


#pragma mark - Initialization


- (id)init {
    self = [super init];
	if (self != nil) {
        // pools
        _cachedPoolOfMedia = [NSMapTable strongToWeakObjectsMapTable];
        _cachedPoolOfUsers = [NSMapTable strongToWeakObjectsMapTable];
        
        // calendar
        NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
        _calendarEN_US = [locale objectForKey:NSLocaleCalendar];
        
        // notifications
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(memoryWarning:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
	}
	return self;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)memoryWarning:(NSNotification *)notification {
    [ASIHTTPRequest clearSession];
    // media content
    //[[_poolOfMedias allValues] makeObjectsPerformSelector:@selector(clearMediaContent)];
}


#pragma mark - Supplemental


// MD5
- (NSString *)md5Conversion:(NSString *) input {
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return [NSString stringWithFormat:@"%@-%ld", output, (long)[[NSDate date] timeIntervalSince1970]];
}


// request resource from web
- (void)loadResourceWithUrl:(NSURL *)url cacheStoragePolicy:(ASICacheStoragePolicy)cacheStoragePolicy forceAsynchronous:(BOOL)forceAsynchronous completion:(void (^)(id, BOOL, NSString *, NSError *))callback {
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	request.timeOutSeconds = resourceRequesTimeOutSeconds;
	[request setCacheStoragePolicy:cacheStoragePolicy];
    request.secondsToCache = 0;
	__block ASIHTTPRequest *blockRequest = request;
	[request setCompletionBlock:^{
		SAFE_CALLBACK4([blockRequest responseData],
					   [blockRequest didUseCachedResponse],
					   blockRequest.url.absoluteString,
					   nil);
		blockRequest = nil;
	}];
	[request setFailedBlock:^{
		SAFE_CALLBACK4(nil, NO, nil, [blockRequest error]);
		blockRequest = nil;
	}];
	// run request, will call back immidiately if in-memory cache can be used
	[request startAsynchronous];
}


- (NSString *)dateStringRelativeFromDateSince1970:(NSDate *)date {
//    NSDateComponents *components = [_calendarEN_US components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitWeekOfMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute fromDate:date toDate:[NSDate date] options:NSCalendarWrapComponents];
//    NSInteger number = 0;
//    NSUInteger unit = NSCalendarUnitMinute;
//    if ([components year] > 0) {            // years
//        number = [components year];
//        unit = NSCalendarUnitYear;
//    } else if ([components month]) {        // months
//        number = [components month];
//        unit = NSCalendarUnitMonth;
//    } else if ([components weekOfMonth]) {  // weeks
//        number = [components weekOfMonth];
//        unit = NSCalendarUnitWeekOfMonth;
//    } else if ([components day]) {          // days
//        number = [components day];
//        unit = NSCalendarUnitDay;
//    } else if ([components hour]) {         // hours
//        number = [components hour];
//        unit = NSCalendarUnitHour;
//    } else {                                // minutes
//        number = [components minute];
//        unit = NSCalendarUnitMinute;
//    }
//    if (number <= 0) {
//        return @"< 1 min ago";
//    } else {
//        return [NSString stringWithFormat:@"%li %@ ago", (long)number, [self stringForCalendarUnit:unit number:number]];
//    }

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM dd h:mm a"];
    
    return [formatter stringFromDate:date];

}


- (NSString *)stringForCalendarUnit:(NSCalendarUnit)calendarUnit number:(NSInteger)number {
    NSString *result = @"";
    switch (calendarUnit) {
		case NSCalendarUnitYear:
            result = @"year";
			break;
		case NSCalendarUnitMonth:
            result = @"month";
			break;
		case NSCalendarUnitWeekOfMonth:
            result = @"week";
			break;
		case NSCalendarUnitDay:
            result = @"day";
			break;
		case NSCalendarUnitHour:
            result = @"hour";
            break;
		case NSCalendarUnitMinute:
            return @"min";   // return here, befor adding any "s"
            break;
        default:
            return @"";
	}
    if (number > 1) {
        return [result stringByAppendingString:@"s"];
    } else {
        return result;
    }
}


#pragma mark - Register


// register new user
- (void)registerUser:(User *)user password:(NSString *)password callback:(AppDataCallback)callback {
    
    [APICommunication registerUserWithUsername:user.username
                                      password:password
                                         email:user.email
                                     firstName:user.firstName
                                      lastName:user.lastName
                                         phone:user.phone
                                      birthday:user.birthday
                                    completion:^(NSData *data) {
                                        
                                        NSError *error = nil;
                                        if (data == nil) {
                                            error = [AppData errorWithCode:0 description:@":( Our systems appear to be acting up. Please try again"];
                                            SAFE_CALLBACK2(nil, error);
                                            return;
                                        }
                                        
                                        NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                                        
                                        NSLog(@"register: %@", resultDictionary);
                                        
                                        // DUMB!
                                        if([resultDictionary objectForKey:@"error"]) {
                                            if([[resultDictionary objectForKey:@"error"] objectForKey:@"raw"]) {
                                                if([[[resultDictionary objectForKey:@"error"] objectForKey:@"raw"] objectForKey:@"code"]) {
                                                    if([[[[resultDictionary objectForKey:@"error"] objectForKey:@"raw"] objectForKey:@"code"] integerValue] == 11000)
                                                    {
                                                        SAFE_CALLBACK2(nil, [AppData errorWithCode:0 description:@"A user with this name already exists!"]);
                                                        return;
                                                    }
                                                }
                                            }
                                        }

                                        
                                        if([resultDictionary objectForKey:@"errorMessage"]) {
                                            SAFE_CALLBACK2(nil, [AppData errorWithCode:0 description:[resultDictionary objectForKey:@"errorMessage"]]);
                                            return;
                                        }
                                        
                                        User *user;
                                        
                                        if([resultDictionary objectForKey:@"user"]) {
                                            
                                            user = [self getUserFromPoolWithInfo:[resultDictionary objectForKey:@"user"]];
                                            user.isFirstTimeUser = YES;
                                            
                                            SAFE_CALLBACK2(user, nil);
                                        } else {
                                            SAFE_CALLBACK2(nil, [AppData errorWithCode:0 description:@":( Our systems appear to be acting up. Please try again"]);
                                        }
                                        
                                        
                                    } failure:^(NSError *error) {
                                        NSLog(@"Failed to register: %@", error);
                                        SAFE_CALLBACK2(nil, [AppData errorWithCode:0 description:@"Something went wrong! Please try again."]);
                                    }];
}


#pragma mark - Login


// login
- (void)loginWithEmail:(NSString *)email password:(NSString *)password andCallback:(AppDataCallback)callback {
    
    __block AppData *blockSelf = self;
    
    [APICommunication loginWithEmail:email
                            password:password
                          completion:^(NSData *data) {
                              NSError *error = nil;
                              if (data == nil) {
                                  error = [AppData errorWithCode:0 description:@"Invalid response from Login"];
                                  SAFE_CALLBACK2(nil, error);
                                  return;
                              }
                              
                              NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                              
                              NSLog(@"login: %@", resultDictionary);
                              
                              if([resultDictionary objectForKey:@"data"]) {
                                  
                                  resultDictionary = [resultDictionary objectForKey:@"data"];
                                  NSDictionary *userInfo = [resultDictionary objectForKey:@"user"];
                                  
                                  if(userInfo == nil) {
                                      // user has an invalid username and we must return an error
                                      NSError *error = [AppData errorWithCode:0 description:@""];
                                      
                                      SAFE_CALLBACK2(nil, error);
                                      return;
                                  }
                                  
                                  blockSelf.localUser = [self getUserFromPoolWithInfo:userInfo];
                                  // update local session
                                  NSString *token = [resultDictionary  objectForKey:@"token"];
                                  blockSelf.localSession.username = blockSelf.localUser.username;
                                  blockSelf.localSession.userID = blockSelf.localUser.theId;
                                  blockSelf.localSession.oauthToken = token;
                                  
                                  _localUser = [self getUserFromPoolWithInfo:userInfo];
                                  
                                  [blockSelf storeLocalSession];
                                  
                                  [self.pollTimer fire];
                                  
                                  // register for remote notifications
                                  UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
                                  [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
                                  
                                  if(![self.deviceToken isEqualToString:self.localUser.deviceToken] &&
                                     self.deviceToken &&
                                     self.deviceToken.length > 0)
                                  {
                                      [self updateUserDeviceId:self.deviceToken
                                                      callback:^(id result, NSError *error) {
                                                          NSLog(@"updated device token of user");
                                      }];
                                  }
                                  
                                  SAFE_CALLBACK2(blockSelf.localUser, nil);
                                  return;

                              } else {
                                  
                                  NSLog(@"Login failed: Missing data from json: %@", resultDictionary);
                                  
                                  error = [AppData errorWithCode:0 description:[resultDictionary objectForKey:@"message"]];
                                  SAFE_CALLBACK2(nil, error);
                                  return;

                              }
                              

                              
                          } failure:^(NSError *error) {
                              NSLog(@"Failed to login: %@", error);
                              SAFE_CALLBACK2(nil, error);
                          }];
    
}

- (void)loginWithFacebookToken:(NSString *)token andCallback:(AppDataCallback)callback {
    
    __block AppData *blockSelf = self;
    
    [APICommunication loginWithFacebookToken:token
                          completion:^(NSData *data) {
                              NSError *error = nil;
                              if (data == nil) {
                                  error = [AppData errorWithCode:0 description:@"Invalid response from Login"];
                                  SAFE_CALLBACK2(nil, error);
                                  return;
                              }
                              
                              NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                              
                              NSLog(@"login: %@", resultDictionary);
                              
                              if([resultDictionary objectForKey:@"data"]) {
                                  
                                  resultDictionary = [resultDictionary objectForKey:@"data"];
                                  NSDictionary *userInfo = [resultDictionary objectForKey:@"user"];
                                  
                                  if(userInfo == nil) {
                                      // user with this facebook token does not exist
                                      NSError *error = [AppData errorWithCode:404 description:@""];
                                      
                                      SAFE_CALLBACK2(nil, error);
                                      return;
                                  }
                                  
                                  blockSelf.localUser = [self getUserFromPoolWithInfo:userInfo];
                                  // update local session
                                  NSString *token = [resultDictionary  objectForKey:@"token"];
                                  blockSelf.localSession.username = blockSelf.localUser.username;
                                  blockSelf.localSession.userID = blockSelf.localUser.theId;
                                  blockSelf.localSession.oauthToken = token;
                                  
                                  _localUser = [self getUserFromPoolWithInfo:userInfo];
                                  
                                  [blockSelf storeLocalSession];
                                  
                                  [self.pollTimer fire];
                                  
                                  // register for remote notifications
                                  UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
                                  [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
                                  
                                  if(![self.deviceToken isEqualToString:self.localUser.deviceToken] &&
                                     self.deviceToken &&
                                     self.deviceToken.length > 0)
                                  {
                                      [self updateUserDeviceId:self.deviceToken
                                                      callback:^(id result, NSError *error) {
                                                          NSLog(@"updated device token of user");
                                                      }];
                                  }
                                  
                                  SAFE_CALLBACK2(blockSelf.localUser, nil);
                                  return;
                                  
                              } else {
                                  
                                  NSLog(@"Login failed: Missing data from json: %@", resultDictionary);
                                  
                                  error = [AppData errorWithCode:0 description:[resultDictionary objectForKey:@"message"]];
                                  SAFE_CALLBACK2(nil, error);
                                  return;
                                  
                              }
                              
                              
                              
                          } failure:^(NSError *error) {
                              NSLog(@"Failed to login: %@", error);
                              SAFE_CALLBACK2(nil, error);
                          }];
    
}

- (void)updatePassword:(NSString *)newPassword token:(NSString *)token callback:(AppDataCallback)callback {
    [APICommunication updatePassword:newPassword
                               token:token
                              completion:^(NSData *data) {
                                  NSError *error = nil;
                                  
                                  if (data == nil) {
                                      error = [AppData errorWithCode:0 description:@"Invalid response from update password"];
                                      NSLog(@"Error: %@", error);
                                      
                                      SAFE_CALLBACK2(nil, error);
                                      return;
                                  }
                                  
                                  NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                                  
                                  if([resultDictionary objectForKey:@"data"]) {
                                      
                                      SAFE_CALLBACK2(resultDictionary, error);
                                      return;
                                      
                                  } else {
                                      
                                      NSLog(@"Failed to update password: Missing data from json: %@", resultDictionary);
                                      
                                      error = [AppData errorWithCode:0 description:@"Invalid response from update password"];
                                      SAFE_CALLBACK2(nil, error);
                                      return;
                                  }
                                  
                              } failure:^(NSError *error) {
                                  NSLog(@"Error: %@", error);
                                  SAFE_CALLBACK2(nil, error);
                              }];

}



#pragma mark - Session

- (void)setLocalSessionWithEmail:(NSString *)email password:(NSString *)password {
    _localSession = [LocalSession new];
    _localSession.username = email;
    _localSession.password = password;
}

- (void)storeLocalSession {
    if ([self.localUser.theId length] > 0) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:self.localUser.theId forKey:@"MCCSignedUserId"];
        [defaults setObject:self.localSession.oauthToken forKey:@"MCCSignedUserToken"];
        
        [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self.localUser] forKey:@"MCCSignedUser"];
        
        NSError *error;
        
        BOOL result = [SSKeychain setPassword:self.localSession.password forService:@"com.mycamcan" account:self.localUser.theId error:&error];
        
        if (!result || error != nil) {
            
            NSLog(@"error saving password to keychain: %@", error);
            
            //setting the password in keychain failed, use encoder instead
            [defaults setObject:self.localSession.password forKey:@"MCCSignedUserPassword"];
            NSLog(@"\n ******** Password saved on device in the encoder  *************");
        }
        
        
        [defaults synchronize];
    }
}

- (BOOL)restoreLocalSession {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *localUserId = [defaults objectForKey:@"MCCSignedUserId"];
    
    if (localUserId != nil) {
        _localSession = [LocalSession new];
        _localSession.oauthToken = [defaults objectForKey:@"MCCSignedUserToken"];
        User *user = [NSKeyedUnarchiver unarchiveObjectWithData:[defaults objectForKey:@"MCCSignedUser"]];
        
        self.localUser = user;
        _localSession.userID = self.localUser.theId;
        _localSession.username = self.localUser.username;
        
        NSError *error;
        
        _localSession.password = [SSKeychain passwordForService:@"com.mycamcan" account:self.localUser.theId error:&error];
        
        if (_localSession.password == nil || error != nil) {
            //couldn't retrieve password from keychain.  Try encoder
            NSLog(@"Error retrieving password from keychain: %@", error);
            _localSession.password = [defaults objectForKey:@"MCCSignedUserPassword"];
            if (_localSession.password == nil) {
                //couldn't find password at all.
                NSLog(@"\n ******** Could not retrieve password from encoder  **************");
                return NO;
            }
        }
        
        [_cachedPoolOfUsers setObject:_localUser forKey:_localUser.theId];
       
        [self startNotificationsPollingWithCallback:^(id result, NSError *error) {
            //
        }];
        
        [self.pollTimer fire];

        return YES;
        
    } else {
        //_localSession = nil;
        return NO;
    }
}

- (void)updateOauthToken:(NSString *)token {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"MCCSignedUserToken"];
    
    self.localSession.oauthToken = token;
    [defaults setObject:self.localSession.oauthToken forKey:@"MCCSignedUserToken"];
}

- (void)resetNavigationManager {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"BlogStoryboard" bundle:nil];
    self.navigationManager = (BGTabBarController *)[storyboard instantiateViewControllerWithIdentifier:@"BGTabBarController"];
}

- (void)clearLocalSession {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"MCCSignedUserId"];
    [defaults removeObjectForKey:@"MCCSignedUserToken"];
    [defaults removeObjectForKey:@"MCCSignedUser"];
    [defaults removeObjectForKey:@"MCCSignedUserPassword"];
    
    [SSKeychain deletePasswordForService:@"com.mycamcan" account:self.localUser.theId];
    
    [defaults synchronize];
    _localSession = nil;
    self.localUser = nil;
    
    // clear the disk cache
    [[SDImageCache sharedImageCache] clearMemory];
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:nil];
    
    //NOTE: resources - are images, loaded from web.
    //      They use ASIHTTP SDK's cache.
    //      Cache method is "for session duration".
    [ASIHTTPRequest clearSession];
    
    // clear all pools (#PoolsClosed)
    [_cachedPoolOfMedia removeAllObjects];
    [_cachedPoolOfUsers removeAllObjects];
    
    [self removeTempFiles];

}

- (void)removeTempFiles {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *directory = [documentsDirectory stringByAppendingPathComponent:@"movies/"];
    NSError *error = nil;
    
    for (NSString *file in [fm contentsOfDirectoryAtPath:directory error:&error]) {
        BOOL success = [fm removeItemAtPath:[NSString stringWithFormat:@"%@/%@", directory, file] error:&error];
        if (!success || error) {
            NSLog(@"Failed to delete file: %@ with error: %@", file, error);
        }
    }
}

// Forgot Password
- (void)sendForgotPasswordRequestWithEmail:(NSString*)email andCallback:(AppDataCallback)callback {
    [APICommunication sendForgotPasswordRequestWithEmail:email
                                              completion:^(NSData *data) {
                                                  
                                                  SAFE_CALLBACK2(data, nil);

                                              } failure:^(NSError *error) {
                                                  NSLog(@"Failed to recover password: %@", error);
                                                  SAFE_CALLBACK2(nil, error);

                                              }];
}


#pragma mark - Update User Info


- (void)updateUserDeviceId:(NSString *)deviceId callback:(AppDataCallback)callback {
    [APICommunication updateUserDeviceId:deviceId
                              completion:^(NSData *data) {
                                  SAFE_CALLBACK2(data, nil);
                              } failure:^(NSError *error) {
                                  NSLog(@"Failed to update user device token: %@", error);
                                  SAFE_CALLBACK2(nil, error);
                              }];
}

#pragma mark - Model Internal - Pools


- (User *)getUserFromPoolWithID:(NSString *)theID {
    if (theID == nil) {
        return nil;
    }
    User *user = [_cachedPoolOfUsers objectForKey:theID];
    if (user == nil) {
        user = [User userWithId:theID];
        if (![theID isEqualToString:@""]) {
            [_cachedPoolOfUsers setObject:user forKey:theID];
        }
    }
    return user;
}


- (User *)getUserFromPoolWithID:(NSString *)theID username:(NSString *)username {
    // return YES, if existing user was updated
    if (theID == nil) {
        return nil;
    }
    User *user = [_cachedPoolOfUsers objectForKey:theID];
    if (user != nil) {
        [user supplyUsername:username];
    } else {
        user = [User userWithBasicInfoDictionary:@{@"id": theID,
                                                   @"username": username}];
        if (![theID isEqualToString:@""]) {
            [_cachedPoolOfUsers setObject:user forKey:theID];
        }
        
    }
    return user;
}


- (User *)getUserFromPoolWithInfo:(NSDictionary *)userInfo {
    if (![userInfo isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    // <_userUpdated> will be set to YES, if user was already existed and was updated
    NSString *userID = [User IDFromBasicInfoDictionary:userInfo];
    User *user = nil;
    if (userID != nil) {
        user = [_cachedPoolOfUsers objectForKey:userID];
        if (user == nil) {
            // create new
            user = [User userWithBasicInfoDictionary:userInfo];
            // add to pool
            [_cachedPoolOfUsers setObject:user forKey:user.theId];
            return user;
        }
    }
    [user supplyBasicInfoDictionary:userInfo];
    return user;
}


- (Media *)getMediaFromPoolWithID:(NSString *)theID {
    if (theID == nil) {
        return nil;
    }
    Media *post = [_cachedPoolOfMedia objectForKey:theID];
    if (post == nil) {
        post = [Media mediaWithId:theID];
        if (![theID isEqualToString:@""]) {
            [_cachedPoolOfMedia setObject:post forKey:theID];
        }
    }
    return post;
}


- (Media *)getMediaFromPoolWithInfo:(NSDictionary *)postInfo {
    NSString *postId = [Media IDFromBasicInfoDictionary:postInfo];
    Media *post = nil;
    if (postId != nil) {
        post = [_cachedPoolOfMedia objectForKey:postId];
        if (post == nil) {
            // create new
            post = [Media mediaWithBasicInfoDictionary:postInfo];
            // add to pool
            [_cachedPoolOfMedia setObject:post forKey:postId];
            return post;
        }
    }
    // update existing one
    // if postId == nil -> media will be nil -> return will be nil
    [post supplyBasicInfoDictionary:postInfo];
    return post;
}

// GET Feed
- (void)getFeedForUser:(User *)user
            withOffset:(NSInteger)offset
        withFilterType:(BGFeedFilterType)filterType
              callback:(AppDataCallbackPagerElements)callback {
 
    [APICommunication getFeedWithOffset:offset
                                 completion:^(NSData *data) {
                                     NSError *error = nil;
                                     
                                     if (data == nil) {
                                         error = [AppData errorWithCode:0 description:@"Invalid response from get Feed for user"];
                                         NSLog(@"Error: %@", error);
                                         
                                         SAFE_CALLBACK4(nil, -1, @"", error);
                                         return;
                                     }
                                     
                                     NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                                     
                                     if([resultDictionary objectForKey:@"data"]) {
                                         
                                         Media *media;
                                         NSMutableArray *mediaArray = [NSMutableArray new];
                                         
                                         for(NSDictionary *mediaDict in [resultDictionary objectForKey:@"data"]) {
                                             media = [self getMediaFromPoolWithInfo:mediaDict];
                                             [mediaArray addObject:media];
                                         }
                                         
                                         SAFE_CALLBACK4(mediaArray, -1, @"", nil);
                                         return;
                                         
                                     } else {
                                         
                                         NSLog(@"Failed to get Feed for user: Missing data from json: %@", resultDictionary);
                                         
                                         error = [AppData errorWithCode:0 description:@"Invalid response from get Feed media"];
                                         SAFE_CALLBACK4(nil, -1, @"", error);
                                         return;
                                     }
                                     
                                 } failure:^(NSError *error) {
                                     NSLog(@"Error: %@", error);
                                     SAFE_CALLBACK4(nil, -1, @"", error);
                                 }];
}

- (void)getGlobalFeedForUser:(User *)user
            withOffset:(NSString *)offset
        withFilterType:(BGFeedFilterType)filterType
              callback:(AppDataCallbackPagerElements)callback {
    
    [APICommunication getGlobalFeedWithOffset:offset
                             completion:^(NSData *data) {
                                 NSError *error = nil;
                                 
                                 if (data == nil) {
                                     error = [AppData errorWithCode:0 description:@"Invalid response from get Global Feed"];
                                     NSLog(@"Error: %@", error);
                                     
                                     SAFE_CALLBACK4(nil, -1, @"", error);
                                     return;
                                 }
                                 
                                 NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                                 
                                 if([resultDictionary objectForKey:@"data"]) {
                                     
                                     Media *media;
                                     NSMutableArray *mediaArray = [NSMutableArray new];
                                     
                                     for(NSDictionary *mediaDict in [resultDictionary objectForKey:@"data"]) {
                                         media = [self getMediaFromPoolWithInfo:mediaDict];
                                         [mediaArray addObject:media];
                                     }
                                     
                                     SAFE_CALLBACK4(mediaArray, -1, @"", nil);
                                     return;
                                     
                                 } else {
                                     
                                     NSLog(@"Failed to get Global Feed: Missing data from json: %@", resultDictionary);
                                     
                                     error = [AppData errorWithCode:0 description:@"Invalid response from get Global Feed"];
                                     SAFE_CALLBACK4(nil, -1, @"", error);
                                     return;
                                 }
                                 
                             } failure:^(NSError *error) {
                                 NSLog(@"Error: %@", error);
                                 SAFE_CALLBACK4(nil, -1, @"", error);
                             }];
}

- (void)verifyUsername:(NSString *)username callback:(AppDataCallback)callback {
    [APICommunication verifyUsername:username
                          completion:^(NSData *data) {
                              NSError *error = nil;
                              
                              if (data == nil) {
                                  error = [AppData errorWithCode:0 description:@"Invalid response from verify username"];
                                  SAFE_CALLBACK2(nil, error);
                                  return;
                              }
                              
                              NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                              
                              if(resultDictionary == nil) {
                                  error = [AppData errorWithCode:0 description:@"Invalid response from verify username"];
                                  
                                  SAFE_CALLBACK2(nil, error);
                                  return;
                              }
                              
                              SAFE_CALLBACK2([resultDictionary objectForKey:@"isAvailable"], nil);
                              
                          } failure:^(NSError *error) {
                              NSLog(@"Error: %@", error);
                              SAFE_CALLBACK2(nil, error);
                          }];
}

- (void)getNotificationsWithDateOffset:(NSString *)dateOffset
                              callback:(AppDataCallbackPagerElements)callback {
    
    [APICommunication getNotificationsWithDateOffset:dateOffset
                                               limit:10
                                          completion:^(NSData *data) {
                                              NSError *error = nil;
                                              
                                              if (data == nil) {
                                                  error = [AppData errorWithCode:0 description:@"Invalid response from user search"];
                                                  NSLog(@"Error: %@", error);
                                                  
                                                  SAFE_CALLBACK4(nil, -1, @"", error);
                                                  return;
                                              }
                                              
                                              self.localUser.totalUnreadNotifications = 0;

                                              [self sendElementNotification:kAppData_Notification_UserUpdated
                                                                       user:self.localUser
                                                                      media:nil];
                                              
                                              NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                                              
                                              NSLog(@"%@", resultDictionary);
                                              
                                              if([resultDictionary objectForKey:@"data"]) {
                                                  
                                                  NSMutableArray *notificationArray = [NSMutableArray array];
                                                  
                                                  for (NSDictionary *infoDict in [resultDictionary objectForKey:@"data"]) {
                                                      Notification *notification = [Notification notificationWithBasicInfoDictionary:infoDict];
                                                      if (notification != nil) {
                                                          [notificationArray addObject:notification];
                                                      }
                                                  }
                                                  
                                                  SAFE_CALLBACK4(notificationArray, -1, @"", nil);
                                                  return;
                                                  
                                              } else {
                                                  
                                                  NSLog(@"Failed to search users: Missing data from json: %@", resultDictionary);
                                                  
                                                  error = [AppData errorWithCode:0 description:@"Invalid response from user search"];
                                                  SAFE_CALLBACK4(nil, -1, @"", error);
                                                  return;
                                              }
                                              
                                          } failure:^(NSError *error) {
                                              NSLog(@"Error: %@", error);
                                              SAFE_CALLBACK4(nil, -1, @"", error);
                                          }];

}

- (void)likeMedia:(Media *)media
         callback:(AppDataCallback)callback {
    
    [APICommunication likeMedia:media
                     completion:^(NSData *data) {
                         NSError *error = nil;
                         
                         if (data == nil) {
                             error = [AppData errorWithCode:0 description:@"Invalid response from Like Media"];
                             NSLog(@"Error: %@", error);
                             
                             SAFE_CALLBACK2(nil, error);
                             return;
                         }
                         
                         NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                         
                         if([resultDictionary objectForKey:@"data"]) {
                             
                             media.totalLikes++;
                             [self sendElementNotification:kAppData_Notification_MediaUpdated
                                                      user:nil
                                                     media:media];
                             
                             SAFE_CALLBACK2(resultDictionary, nil);
                             return;
                             
                         } else {
                             
                             NSLog(@"Failed to Like Media: Missing data from json: %@", resultDictionary);
                             
                             error = [AppData errorWithCode:0 description:@"Invalid response from Like Media"];
                             SAFE_CALLBACK2(nil, error);
                             return;
                         }
                         
                         
                     } failure:^(NSError *error) {
                         NSLog(@"Error: %@", error);
                         SAFE_CALLBACK2(nil, error);
                     }];
}

- (void)deleteMedia:(Media *)media
           callback:(AppDataCallback)callback {
    
    // set medias status to deleted
    [media setIsDeleting:YES];
    
    [self sendElementNotification:kAppData_Notification_MediaUpdated
                             user:nil
                            media:media];
    
    [APICommunication deleteMedia:media
                     completion:^(NSData *data) {
                         NSError *error = nil;
                         
                         if (data == nil) {
                             error = [AppData errorWithCode:0 description:@"Invalid response from Delete Media"];
                             NSLog(@"Error: %@", error);
                             
                             // undo set medias status to deleted
                             [media setIsDeleting:NO];
                             
                             [self sendElementNotification:kAppData_Notification_MediaUpdated
                                                      user:nil
                                                     media:media];
                             
                             SAFE_CALLBACK2(nil, error);
                             return;
                         }
                         
                         NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                         
                         [media setIsDeleted:YES];
                         
                         [self sendElementNotification:kAppData_Notification_MediaUpdated
                                                  user:nil
                                                 media:media];

                         
                         if([resultDictionary objectForKey:@"data"]) {
                             
                             // remove from feed
                             [self.localUser.feedPager deleteElement:media];
                             [self.localUser.globalFeedPager deleteElement:media];
                             [self.localUser.profileMediaPager deleteElement:media];
                             
                             NSUInteger mediaIndex = [self.localUser.profileMediaPager deleteElement:media];
                             
                             // notify
//                             if (feedIndex != NSNotFound) {
                                 [[NSNotificationCenter defaultCenter] postNotificationName:kAppData_Notification_FeedChanged
                                                                                     object:nil
                                                                                   userInfo:@{kAppData_NotificationKey_User: [AppData sharedInstance].localUser,
                                                                                              @"FeedFilter": [NSNumber numberWithInteger:kBGFeedFilterDefault],
                                                                                              kAppData_NotificationKey_TotalFlag: @(YES)}];
                                 
                                 [[NSNotificationCenter defaultCenter] postNotificationName:kAppData_Notification_FeedChanged
                                                                                     object:nil
                                                                                   userInfo:@{kAppData_NotificationKey_User: [AppData sharedInstance].localUser,
                                                                                              @"FeedFilter": [NSNumber numberWithInteger:kBGFeedFilterGlobal],
                                                                                              kAppData_NotificationKey_TotalFlag: @(YES)}];
//                             }
                             if (mediaIndex != NSNotFound) {
                                  [[NSNotificationCenter defaultCenter] postNotificationName:kAppData_Notification_FeedChanged
                                                     object:nil
                                                   userInfo:@{kAppData_NotificationKey_User: [AppData sharedInstance].localUser,
                                                              @"FeedFilter": [NSNumber numberWithInteger:kBGFeedFilterProfile],
                                                              kAppData_NotificationKey_TotalFlag: @(YES)}];
                             }
                             
                             SAFE_CALLBACK2(resultDictionary, nil);
                             return;
                             
                         } else {
                             
                             NSLog(@"Failed to Delete Media: Missing data from json: %@", resultDictionary);
                             
                             error = [AppData errorWithCode:0 description:@"Invalid response from Delete Media"];
                             SAFE_CALLBACK2(nil, error);
                             return;
                         }
                         
                         
                     } failure:^(NSError *error) {
                         NSLog(@"Error: %@", error);
                         SAFE_CALLBACK2(nil, error);
                     }];
}

- (void)getLikesForMedia:(Media *)media
          withDateOffset:(NSString *)dateOffset
                callback:(AppDataCallbackPagerElements)callback {
    [APICommunication getLikesForMedia:media
                            dateOffset:dateOffset
                            completion:^(NSData *data) {
                                
                                NSError *error = nil;
                                
                                if (data == nil) {
                                    error = [AppData errorWithCode:0 description:@"Invalid response from get likes for media"];
                                    NSLog(@"Error: %@", error);
                                    
                                    SAFE_CALLBACK4(nil, -1, @"", error);
                                    return;
                                }
                                
                                NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                                
                                if([resultDictionary objectForKey:@"data"]) {
                                    
                                    Like *like;
                                    NSMutableArray *likeArray = [NSMutableArray new];
                                    
                                    for(NSDictionary *likeDict in [resultDictionary objectForKey:@"data"]) {
                                        like = [Like likeWithBasicInfoDictionary:likeDict];
                                        [likeArray addObject:like];
                                    }
                                    
                                    SAFE_CALLBACK4(likeArray, -1, @"", nil);
                                    return;
                                    
                                } else {
                                    
                                    NSLog(@"Failed to get likes for media: Missing data from json: %@", resultDictionary);
                                    
                                    error = [AppData errorWithCode:0 description:@"Invalid response from get likes for media"];
                                    SAFE_CALLBACK4(nil, -1, @"", error);
                                    return;
                                }
                                
                            } failure:^(NSError *error) {
                                NSLog(@"Error: %@", error);
                                SAFE_CALLBACK4(nil, -1, @"", error);
                            }];
}

- (void)getMediaWithId:(NSString *)mediaId callback:(AppDataCallback)callback {
    [APICommunication getMediaWithId:mediaId
                       completion:^(NSData *data) {
                           NSError *error = nil;
                           
                           if (data == nil) {
                               error = [AppData errorWithCode:0 description:@"Invalid response from GET Media"];
                               NSLog(@"Error: %@", error);
                               
                               SAFE_CALLBACK2(nil, error);
                               return;
                           }
                           
                           NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                           
                           if(resultDictionary) {
                               
                               Media *media = [self getMediaFromPoolWithInfo:resultDictionary];
                               
                               [self sendElementNotification:kAppData_Notification_MediaUpdated
                                                        user:nil
                                                       media:media];
                               
                               SAFE_CALLBACK2(media, nil);
                               return;
                               
                           } else {
                               
                               NSLog(@"Failed to GET Media: Missing data from json: %@", resultDictionary);
                               
                               error = [AppData errorWithCode:0 description:@"Invalid response from GET Media"];
                               SAFE_CALLBACK2(nil, error);
                               return;
                           }
                           
                           
                       } failure:^(NSError *error) {
                           NSLog(@"Error: %@", error);
                           SAFE_CALLBACK2(nil, error);
                       }];
}

- (void)getFeaturedArtistMusicWithCallback:(AppDataCallback)callback {
    [APICommunication getFeaturedArtistMusicWithCompletion:^(NSData *data) {
                                       
                                       NSError *error = nil;
                                       
                                       if (data == nil) {
                                           error = [AppData errorWithCode:0 description:@"Invalid response from get featured artist"];
                                           NSLog(@"Error: %@", error);
                                           
                                           SAFE_CALLBACK2(nil, error);
                                           return;
                                       }
                                       
                                       NSDictionary *results = [APICommunication convertJsonToDictionary:data];
                                       
                                       if([results isKindOfClass:[NSArray class]]) {
                                           
                                           
                                           NSMutableArray *musicItems = [NSMutableArray new];
                                           
                                           for (NSDictionary *dictionary in results) {
                                               MusicItem *item = [[MusicItem alloc] init];
                                               item.previewURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [URLs s3CDN], [dictionary objectForKey:@"fileName"]]];
                                               item.title = [dictionary objectForKey:@"title"];
                                               
                                               if ([dictionary objectForKey:@"GroupingName"]) {
                                                   item.grouping = [dictionary objectForKey:@"GroupingName"];
                                               } else {
                                                   item.grouping = @"MyCamCan";
                                               }
                                            
                                               if ([dictionary objectForKey:@"artist"]) {
                                                   item.artist = [dictionary objectForKey:@"artist"];
                                               } else {
                                                   item.artist = @"MyCamCan";
                                               }
                                               
                                               // Set image
                                               if ([dictionary objectForKey:@"image"]) {
                                                   item.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [URLs s3CDN], [dictionary objectForKey:@"image"]]];
                                                   item.imageURLHighResolution = item.imageURL;
                                               }
                                               
                                               [musicItems addObject:item];
                                           }
                                           
                                           SAFE_CALLBACK2(musicItems, nil);
                                           return;
                                           
                                       } else {
                                           
                                           NSLog(@"Failed to search music: Invalid json: %@", results);
                                           
                                           error = [AppData errorWithCode:0 description:@"Invalid response from music search"];
                                           SAFE_CALLBACK2(nil, error);
                                           return;
                                       }
                                       
                                   } failure:^(NSError *error) {
                                       NSLog(@"Error: %@", error);
                                       SAFE_CALLBACK2(nil, error);
                                   }];
}

- (void)getTopMusicWithCallback:(AppDataCallback)callback {
    [APICommunication getTopMusicWithCompletion:^(NSData *data) {
        
        NSError *error = nil;
        
        if (data == nil) {
            error = [AppData errorWithCode:0 description:@"Invalid response from get top music"];
            NSLog(@"Error: %@", error);
            
            SAFE_CALLBACK2(nil, error);
            return;
        }
        
        NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
        
        if([resultDictionary objectForKey:@"results"]) {
            
            MusicItem *item;
            NSMutableArray *musicArray = [NSMutableArray new];
            
            for(NSDictionary *songDict in [resultDictionary objectForKey:@"results"]) {
                item = [MusicItem musicItemWithBasicInfoDictionary:songDict];
                [musicArray addObject:item];
            }
            
            SAFE_CALLBACK2(musicArray, nil);
            return;
            
        } else {
            
            NSLog(@"Failed to get top music: Invalid json: %@", resultDictionary);
            
            error = [AppData errorWithCode:0 description:@"Invalid response from get top music"];
            SAFE_CALLBACK2(nil, error);
            return;
        }
        
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error);
        SAFE_CALLBACK2(nil, error);
    }];
}


- (void)searchMusicWithKeyword:(NSString *)keyword
                      callback:(AppDataCallback)callback {
    [APICommunication searchMusicWithKeyword:keyword
                                   completion:^(NSData *data) {
                                       
                                       NSError *error = nil;
                                       
                                       if (data == nil) {
                                           error = [AppData errorWithCode:0 description:@"Invalid response from music search"];
                                           NSLog(@"Error: %@", error);
                                           
                                           SAFE_CALLBACK2(nil, error);
                                           return;
                                       }
                                       
                                       NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                                       
                                       if([resultDictionary objectForKey:@"results"]) {
                                           
                                           MusicItem *item;
                                           NSMutableArray *musicArray = [NSMutableArray new];
                                           
                                           for(NSDictionary *songDict in [resultDictionary objectForKey:@"results"]) {
                                               item = [MusicItem musicItemWithSearchInfoDictionary:songDict];
                                               [musicArray addObject:item];
                                           }
                                           
                                           SAFE_CALLBACK2(musicArray, nil);
                                           return;
                                           
                                       } else {
                                           
                                           NSLog(@"Failed to search music: Invalid json: %@", resultDictionary);
                                           
                                           error = [AppData errorWithCode:0 description:@"Invalid response from music search"];
                                           SAFE_CALLBACK2(nil, error);
                                           return;
                                       }

                                   } failure:^(NSError *error) {
                                       NSLog(@"Error: %@", error);
                                       SAFE_CALLBACK2(nil, error);
                                   }];
}

- (void)searchUsersWithKeyword:(NSString *)keyword
                      callback:(AppDataCallbackPagerElements)callback {
    [APICommunication searchUsersWithKeyword:keyword
                                   completion:^(NSData *data) {
                                       
                                       NSError *error = nil;
                                       
                                       if (data == nil) {
                                           error = [AppData errorWithCode:0 description:@"Invalid response from user search"];
                                           NSLog(@"Error: %@", error);
                                           
                                           SAFE_CALLBACK4(nil, -1, @"", error);
                                           return;
                                       }
                                       
                                       NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                                       
                                       if([resultDictionary objectForKey:@"data"]) {
                                           
                                           User *user;
                                           NSMutableArray *userArray = [NSMutableArray new];
                                           
                                           for(NSDictionary *userDict in [resultDictionary objectForKey:@"data"]) {
                                               user = [self getUserFromPoolWithInfo:userDict];
                                               [userArray addObject:user];
                                           }
                                           
                                           SAFE_CALLBACK4(userArray, -1, @"", nil);
                                           return;
                                           
                                       } else {
                                           
                                           NSLog(@"Failed to search users: Missing data from json: %@", resultDictionary);
                                           
                                           error = [AppData errorWithCode:0 description:@"Invalid response from user search"];
                                           SAFE_CALLBACK4(nil, -1, @"", error);
                                           return;
                                       }
                                       
                                   } failure:^(NSError *error) {
                                       NSLog(@"Error: %@", error);
                                       SAFE_CALLBACK4(nil, -1, @"", error);
                                   }];
}

- (void)getTotalUsersForPhoneNumbers:(NSArray *)phoneNumbers
                            callback:(AppDataCallback)callback {
        [APICommunication searchTotalUsersForPhoneNumbers:phoneNumbers
                                               completion:^(NSData *data) {
                                                   NSError *error = nil;
                                                   
                                                   if (data == nil) {
                                                       error = [AppData errorWithCode:0 description:@"Invalid response from get total users by phone number"];
                                                       NSLog(@"Error: %@", error);
                                                       
                                                       SAFE_CALLBACK2(nil, error);
                                                       return;
                                                   }
                                                   
                                                   NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                                                   
                                                   if([resultDictionary objectForKey:@"total"]) {
                                                                                                              
                                                       SAFE_CALLBACK2([resultDictionary objectForKey:@"total"], nil);
                                                       return;
                                                       
                                                   } else {
                                                       
                                                       error = [AppData errorWithCode:0 description:@"Invalid response from get total users by phone number"];
                                                       NSLog(@"Error: %@", error);

                                                       SAFE_CALLBACK2(nil, error);
                                                       return;
                                                   }
                                                   
                                                   
                                               } failure:^(NSError *error) {
                                                   NSLog(@"Error: %@", error);
                                                   SAFE_CALLBACK2(nil, error);
                                               }];
}

- (void)searchUsersWithPhoneNumbers:(NSArray *)phoneNumbers
                           callback:(AppDataCallbackPagerElements)callback {
        [APICommunication searchUsersWithPhoneNumbers:phoneNumbers
                                           completion:^(NSData *data) {
                                               NSError *error = nil;
                                               
                                               if (data == nil) {
                                                   error = [AppData errorWithCode:0 description:@"Invalid response from user search"];
                                                   NSLog(@"Error: %@", error);
                                                   
                                                   SAFE_CALLBACK4(nil, -1, @"", error);
                                                   return;
                                               }
                                               
                                               NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                                               
                                               NSLog(@"result: %@", resultDictionary);
                                               
                                               if([resultDictionary objectForKey:@"data"]) {
                                                   
                                                   User *user;
                                                   NSMutableArray *userArray = [NSMutableArray new];
                                                   
                                                   for(NSDictionary *userDict in [resultDictionary objectForKey:@"data"]) {
                                                       user = [self getUserFromPoolWithInfo:userDict];
                                                       [userArray addObject:user];
                                                   }
                                                   
                                                   SAFE_CALLBACK4(userArray, -1, @"", nil);
                                                   return;
                                                   
                                               } else {
                                                   
                                                   NSLog(@"Failed to search users: Missing data from json: %@", resultDictionary);
                                                   
                                                   error = [AppData errorWithCode:0 description:@"Invalid response from user search"];
                                                   SAFE_CALLBACK4(nil, -1, @"", error);
                                                   return;
                                               }
                                               
                                           } failure:^(NSError *error) {
                                               NSLog(@"Error: %@", error);
                                               SAFE_CALLBACK4(nil, -1, @"", error);
                                           }];
}

#pragma mark - Model Internal - Notifications


- (void)sendNotificationWithName:(NSString *)name infoDictionary:(NSDictionary *)infoDict {
    [[NSNotificationCenter defaultCenter] postNotificationName:name
                                                        object:self
                                                      userInfo:infoDict];
}


- (void)sendNotificationCommentsListAppendedForMedia:(Media *)media count:(NSUInteger)count {
    [self sendNotificationWithName:kAppData_Notification_CommentsListAppended
                    infoDictionary:@{kAppData_NotificationKey_Media: media,
                                     kAppData_NotificationKey_Count: [NSNumber numberWithUnsignedInteger:count]}];
}


- (void)sendNotificationCommentsListChangedForMedia:(Media *)media {
    [self sendNotificationWithName:kAppData_Notification_CommentsListChanged
                    infoDictionary:@{kAppData_NotificationKey_Media: media}];
}


- (void)sendNotificationPostFeedChanged {
    [self sendNotificationWithName:kAppData_Notification_CommentsListChanged
                    infoDictionary:nil];
}


- (void)sendNotificationPostFeedAppendedWith:(NSUInteger)count {
    [self sendNotificationWithName:kAppData_Notification_FeedAppended
                    infoDictionary:@{kAppData_NotificationKey_Count: [NSNumber numberWithUnsignedInteger:count]}];
}


- (void)sendNotificationFeedDeletedAt:(NSUInteger)index {
    [self sendNotificationWithName:kAppData_Notification_FeedDeleted
                    infoDictionary:@{kAppData_NotificationKey_Index: [NSNumber numberWithUnsignedInteger:index]}];
}



- (void)sendNotificationMediasChangedForUser:(User *)user {
    [self sendNotificationWithName:kAppData_Notification_UserMediasChanged
                    infoDictionary:@{kAppData_NotificationKey_User: user}];
}

- (void)sendNotificationMediasForUser:(User *)user appendedWith:(NSUInteger)count {
    [self sendNotificationWithName:kAppData_Notification_UserMediasAppended
                    infoDictionary:@{kAppData_NotificationKey_User: user,
                                     kAppData_NotificationKey_Count: [NSNumber numberWithUnsignedInteger:count]}];
}

- (void)sendNotificationMediaDeletedFromUser:(User *)user atIndex:(NSUInteger)index {
    [self sendNotificationWithName:kAppData_Notification_UserMediaDeleted
                    infoDictionary:@{kAppData_NotificationKey_User: user,
                                     kAppData_NotificationKey_Index: [NSNumber numberWithUnsignedInteger:index]}];
}

- (void)sendNotificationMediaUpdated:(Media *)media {
    [self sendNotificationWithName:kAppData_Notification_MediaUpdated
                    infoDictionary:@{kAppData_NotificationKey_Media: media}];
}


- (void)sendNotificationUserUpdated:(User *)user {
    [self sendNotificationWithName:kAppData_Notification_UserUpdated
                    infoDictionary:@{kAppData_NotificationKey_User: user}];
}

- (void)sendPagerNotification:(NSString *)notificationName total:(BOOL)total user:(User *)user media:(Media *)media {
    [self sendPagerNotification:notificationName total:total user:user media:media index:NSNotFound];
}

- (void)sendPagerNotification:(NSString *)notificationName total:(BOOL)total user:(User *)user media:(Media *)media index:(NSUInteger)index {
    NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];
    [infoDict setObject:[NSNumber numberWithBool:total]
                 forKey:kAppData_NotificationKey_TotalFlag];

    if (user != nil) {
        [infoDict setObject:user
                     forKey:kAppData_NotificationKey_User];
    }
    if (media != nil) {
        [infoDict setObject:media
                     forKey:kAppData_NotificationKey_Media];
    }
    
    [infoDict setObject:[NSNumber numberWithInteger:index]
                 forKey:kAppData_NotificationKey_Index];
    
    [self sendNotificationWithName:notificationName
                    infoDictionary:infoDict];
}

- (void)sendElementNotification:(NSString *)notificationName user:(User *)user media:(Media *)media {
    NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];
    if (user != nil) {
        [infoDict setObject:user
                     forKey:kAppData_NotificationKey_User];
    }
    if (media != nil) {
        [infoDict setObject:media
                     forKey:kAppData_NotificationKey_Media];
    }
    [self sendNotificationWithName:notificationName
                    infoDictionary:infoDict];
}

#pragma mark - Media



// GET likes for media
- (void)getLikesForMedia:(Media *)media
                   limit:(NSInteger)limit
              dateOffset:(NSString *)dateOffset
             forceReload:(BOOL)forceReload
                callback:(AppDataCallback)callback {
}


#pragma mark - Comments

/**
 @brief Get Comments for Media
 */
- (void)getCommentsForMedia:(Media *)media pageOffset:(NSString *)pageOffset limit:(NSUInteger)limit callback:(AppDataCallback)callback {
}


// CREATE Comment for media
- (void)createComment:(Comment *)comment callback:(AppDataCallback)callback {
}


#pragma mark - User


// GET Profile
- (void)getProfileForUser:(User *)user callback:(AppDataCallback)callback {
    
    __block AppData *blockSelf = self;
    [APICommunication getProfile:user
                     forceReload:NO
                      completion:^(NSData *data) {
                          
                          NSError *error = nil;
                          
                          if (data == nil) {
                              error = [AppData errorWithCode:0 description:@"Invalid response from get profile for user"];
                              SAFE_CALLBACK2(nil, error);
                              return;
                          }
                             
                          NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                              
                          if([resultDictionary objectForKey:@"data"]) {
                                 
                              resultDictionary = [resultDictionary objectForKey:@"data"];
                                 
                              if(resultDictionary == nil) {
                                  NSError *error = [AppData errorWithCode:0 description:@""];
                                  
                                  SAFE_CALLBACK2(nil, error);
                                  return;
                              }
                              
                              User *updatedUser = [blockSelf getUserFromPoolWithInfo:resultDictionary];

                              [self sendElementNotification:kAppData_Notification_UserUpdated
                                                       user:updatedUser
                                                      media:nil];
                            
                              SAFE_CALLBACK2(updatedUser, nil);
                              return;
                                 
                          } else {
                                 
                              NSLog(@"Failed to get user profile: Missing data from json: %@", resultDictionary);
                                 
                              error = [AppData errorWithCode:0 description:@"Invalid response from get user profile"];
                              SAFE_CALLBACK2(nil, error);
                              return;
                          }

                      } failure:^(NSError *error) {
                          NSLog(@"Error: %@", error);
                          SAFE_CALLBACK2(nil, error);
                      }];
}

- (void)updateMedia:(Media *)media callback:(AppDataCallback)callback {
    [APICommunication updateMedia:media
                      completion:^(NSData *data) {
                          
                          NSError *error = nil;
                          
                          if (data == nil) {
                              error = [AppData errorWithCode:0 description:@"Invalid response from update media"];
                              SAFE_CALLBACK2(nil, error);
                              return;
                          }
                          
                          NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                        
                          if(resultDictionary == nil) {
                              NSError *error = [AppData errorWithCode:0 description:@""];
                              
                              SAFE_CALLBACK2(nil, error);
                              return;
                          }
                          
                          Media *media = [self getMediaFromPoolWithInfo:resultDictionary];
                          
                          [self sendElementNotification:kAppData_Notification_MediaUpdated
                                                   user:nil
                                                  media:media];
                          
                          SAFE_CALLBACK2(media, nil);
                          return;
                      
                      } failure:^(NSError *error) {
                          NSLog(@"Error: %@", error);
                          SAFE_CALLBACK2(nil, error);
                      }];
}


- (void)getMediaForUser:(User *)user withDateOffset:(NSString*)dateOffset callback:(AppDataCallbackPagerElements)callback {
    [APICommunication getMediaForUser:user
                           dateOffset:(NSString*)dateOffset
                           completion:^(NSData *data) {
                               NSError *error = nil;
                          
                               if (data == nil) {
                                   error = [AppData errorWithCode:0 description:@"Invalid response from get media for user"];
                                   NSLog(@"Error: %@", error);

                                   SAFE_CALLBACK4(nil, -1, @"", error);
                                   return;
                               }
                          
                               NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];

                               if([resultDictionary objectForKey:@"data"]) {
                              
                                   Media *media;
                                   NSMutableArray *mediaArray = [NSMutableArray new];
                                   
                                   for(NSDictionary *mediaDict in [resultDictionary objectForKey:@"data"]) {
                                       media = [self getMediaFromPoolWithInfo:mediaDict];
                                       [mediaArray addObject:media];
                                   }
                                   
                                   SAFE_CALLBACK4(mediaArray, -1, @"", nil);
                                   return;
                              
                               } else {
                              
                                   NSLog(@"Failed to get media for user: Missing data from json: %@", resultDictionary);
                              
                                   error = [AppData errorWithCode:0 description:@"Invalid response from get user media"];
                                   SAFE_CALLBACK4(nil, -1, @"", error);
                                   return;
                               }
                          
                           } failure:^(NSError *error) {
                               NSLog(@"Error: %@", error);
                               SAFE_CALLBACK4(nil, -1, @"", error);
                           }];
}

- (void)stopFollowingUser:(User *)user callback:(AppDataCallback)callback {
    [APICommunication stopFollowingUser:user
                              completion:^(NSData *data) {
                                  NSError *error = nil;
                                  
                                  if (data == nil) {
                                      error = [AppData errorWithCode:0 description:@"Invalid response from unfollow user"];
                                      NSLog(@"Error: %@", error);
                                      
                                      SAFE_CALLBACK2(nil, error);
                                      return;
                                  }
                                  
                                  NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                                  
                                  if([resultDictionary objectForKey:@"data"]) {
                                      
                                      user.isFollowing = NO;
                                      [self sendElementNotification:kAppData_Notification_UserUpdated
                                                               user:user
                                                              media:nil];
                                      
                                      SAFE_CALLBACK2(user, Nil);
                                      return;
                                      
                                  } else {
                                      
                                      NSLog(@"Failed to follow user: Missing data from json: %@", resultDictionary);
                                      
                                      error = [AppData errorWithCode:0 description:@"Invalid response from unfollow user"];
                                      SAFE_CALLBACK2(nil, error);
                                      return;
                                  }
                                  
                              } failure:^(NSError *error) {
                                  NSLog(@"Error: %@", error);
                                  SAFE_CALLBACK2(nil, error);
                              }];
}


- (void)startFollowingUser:(User *)user callback:(AppDataCallback)callback {
    [APICommunication startFollowingUser:user
                              completion:^(NSData *data) {
                                  NSError *error = nil;
                                  
                                  if (data == nil) {
                                      error = [AppData errorWithCode:0 description:@"Invalid response from follow user"];
                                      NSLog(@"Error: %@", error);
                                      
                                      SAFE_CALLBACK2(nil, error);
                                      return;
                                  }
                                  
                                  NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                                  
                                  if([resultDictionary objectForKey:@"data"]) {
                                      
                                      user.isFollowing = YES;
                                      [self sendElementNotification:kAppData_Notification_UserUpdated
                                                               user:user
                                                              media:nil];
                                      
                                      SAFE_CALLBACK2(user, error);
                                      return;
                                      
                                  } else {
                                      
                                      NSLog(@"Failed to follow user: Missing data from json: %@", resultDictionary);
                                      
                                      error = [AppData errorWithCode:0 description:@"Invalid response from follow user"];
                                      SAFE_CALLBACK2(nil, error);
                                      return;
                                  }
                                  
                              } failure:^(NSError *error) {
                                  NSLog(@"Error: %@", error);
                                  SAFE_CALLBACK2(nil, error);
                              }];

}

- (void)unblockUser:(User *)user callback:(AppDataCallback)callback {
    [APICommunication unblockUser:user
                              completion:^(NSData *data) {
                                  NSError *error = nil;
                                  
                                  if (data == nil) {
                                      error = [AppData errorWithCode:0 description:@"Invalid response from unblock user"];
                                      NSLog(@"Error: %@", error);
                                      
                                      SAFE_CALLBACK2(nil, error);
                                      return;
                                  }
                                  
                                  NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                                  
                                  if([resultDictionary objectForKey:@"data"]) {
                                      
                                      [AppData sharedInstance].localUser.blockedUserIds = [[[resultDictionary objectForKey:@"data"] objectForKey:@"blockedUserIds"] mutableCopy];

                                      [self sendElementNotification:kAppData_Notification_UserUpdated
                                                               user:user
                                                              media:nil];
                                      
                                      SAFE_CALLBACK2(user, error);
                                      return;
                                      
                                  } else {
                                      
                                      NSLog(@"Failed to unblock user: Missing data from json: %@", resultDictionary);
                                      
                                      error = [AppData errorWithCode:0 description:@"Invalid response from unblock user"];
                                      SAFE_CALLBACK2(nil, error);
                                      return;
                                  }
                                  
                              } failure:^(NSError *error) {
                                  NSLog(@"Error: %@", error);
                                  SAFE_CALLBACK2(nil, error);
                              }];
}

- (void)blockUser:(User *)user callback:(AppDataCallback)callback {
    [APICommunication blockUser:user
                              completion:^(NSData *data) {
                                  NSError *error = nil;
                                  
                                  if (data == nil) {
                                      error = [AppData errorWithCode:0 description:@"Invalid response from block user"];
                                      NSLog(@"Error: %@", error);
                                      
                                      SAFE_CALLBACK2(nil, error);
                                      return;
                                  }
                                  
                                  NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
                                  
                                  if([resultDictionary objectForKey:@"data"]) {
                                      
                                      [AppData sharedInstance].localUser.blockedUserIds = [[[resultDictionary objectForKey:@"data"] objectForKey:@"blockedUserIds"] mutableCopy];
                                      user.isFollowing = NO;

                                      [self sendElementNotification:kAppData_Notification_UserUpdated
                                                               user:user
                                                              media:nil];
                                      
                                      SAFE_CALLBACK2(user, error);
                                      return;
                                      
                                  } else {
                                      
                                      NSLog(@"Failed to block user: Missing data from json: %@", resultDictionary);
                                      
                                      error = [AppData errorWithCode:0 description:@"Invalid response from block user"];
                                      SAFE_CALLBACK2(nil, error);
                                      return;
                                  }
                                  
                              } failure:^(NSError *error) {
                                  NSLog(@"Error: %@", error);
                                  SAFE_CALLBACK2(nil, error);
                              }];
    
}



- (void)getFollowersOfUser:(User *)user withOffset:(NSInteger)offset callback:(AppDataCallbackPagerElements)callback {
    
    [APICommunication getFollowersForUser:user
                               withOffset:offset
                               completion:^(NSData *data)
    {
        NSError *error = nil;
        
        if (data == nil) {
            error = [AppData errorWithCode:0 description:@"Invalid response from get followers for user"];
            NSLog(@"Error: %@", error);
            
            SAFE_CALLBACK4(nil, -1, @"", error);
            return;
        }
        
        NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
        
        if([resultDictionary objectForKey:@"data"]) {
            
            User *user;
            NSMutableArray *userArray = [NSMutableArray new];
            
            for(NSDictionary *userDict in [resultDictionary objectForKey:@"data"]) {
                user = [self getUserFromPoolWithInfo:[userDict objectForKey:@"userInfo"]];
                [userArray addObject:user];
            }
            
            SAFE_CALLBACK4(userArray, -1, @"", nil);
            return;
            
        } else {
            
            NSLog(@"Failed to get followers for user: Missing data from json: %@", resultDictionary);
            
            error = [AppData errorWithCode:0 description:@"Invalid response from get followers for user"];
            SAFE_CALLBACK4(nil, -1, @"", error);
            return;
        }
        
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error);
        SAFE_CALLBACK4(nil, -1, @"", error);
    }];

}


- (void)getFolloweesOfUser:(User *)user withOffset:(NSInteger)offset callback:(AppDataCallbackPagerElements)callback {
    [APICommunication getFolloweesForUser:user
                              withOffset:offset
                               completion:^(NSData *data)
     {
         NSError *error = nil;
         
         if (data == nil) {
             error = [AppData errorWithCode:0 description:@"Invalid response from get followees for user"];
             NSLog(@"Error: %@", error);
             
             SAFE_CALLBACK4(nil, -1, @"", error);
             return;
         }
         
         NSDictionary *resultDictionary = [APICommunication convertJsonToDictionary:data];
         
         if([resultDictionary objectForKey:@"data"]) {
             
             User *user;
             NSMutableArray *userArray = [NSMutableArray new];
             
             for(NSDictionary *userDict in [resultDictionary objectForKey:@"data"]) {
                 user = [self getUserFromPoolWithInfo:[userDict objectForKey:@"userInfo"]];
                 [userArray addObject:user];
             }
             
             SAFE_CALLBACK4(userArray, -1, @"", nil);
             return;
             
         } else {
             
             NSLog(@"Failed to get followees for user: Missing data from json: %@", resultDictionary);
             
             error = [AppData errorWithCode:0 description:@"Invalid response from get followees for user"];
             SAFE_CALLBACK4(nil, -1, @"", error);
             return;
         }
         
     } failure:^(NSError *error) {
         NSLog(@"Error: %@", error);
         SAFE_CALLBACK4(nil, -1, @"", error);
     }];
}


// update profile image in user_detail table
- (void)updateAvatarWithPhoto:(NSURL *)photoURL withFileName:(NSString*)fileName callback:(AppDataCallback)callback {
    [APICommunication upload:photoURL
                      forKey:fileName
                  completion:^(NSData *data) {
                      
                      [APICommunication updateAvatarWithFileName:fileName
                                                      completion:^(NSData *data) {
                                                          
                                                          [self.localUser updateAvatarUrl:fileName];
                                                          
                                                          [self sendElementNotification:kAppData_Notification_UserUpdated
                                                                                   user:self.localUser
                                                                                  media:nil];
                                                          
                                                          SAFE_CALLBACK2(nil, nil);

                                                      } failure:^(NSError *error) {
                                                          NSLog(@"Error updating user with avatar: %@", error);
                                                          SAFE_CALLBACK2(nil, error);

                                                      }];
                      
                  } progress:^(float progress, float progressSoFar, float length) {
                      
                  } failure:^(NSError *error) {
                      
                      NSLog(@"Error uploading: %@", error);
                      SAFE_CALLBACK2(nil, error);

                  }];
}

// update profile image in user_detail table
- (void)updateCoverWithPhoto:(NSURL *)photoURL withFileName:(NSString*)fileName callback:(AppDataCallback)callback {
    [APICommunication upload:photoURL
                      forKey:fileName
                  completion:^(NSData *data) {
                      
                      [APICommunication updateCoverWithFileName:fileName
                                                      completion:^(NSData *data) {
                                                          
                                                          [self.localUser updateCoverUrl:fileName];
                                                          
                                                          [self sendElementNotification:kAppData_Notification_UserUpdated
                                                                                   user:self.localUser
                                                                                  media:nil];
                                                          
                                                          SAFE_CALLBACK2(nil, nil);
                                                          
                                                      } failure:^(NSError *error) {
                                                          NSLog(@"Error updating user with avatar: %@", error);
                                                          SAFE_CALLBACK2(nil, error);
                                                          
                                                      }];
                      
                  } progress:^(float progress, float progressSoFar, float length) {
                      
                  } failure:^(NSError *error) {
                      
                      NSLog(@"Error uploading: %@", error);
                      SAFE_CALLBACK2(nil, error);
                      
                  }];
}



#pragma mark - Internal


+ (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description {
    
    NSString *desc = description ? description : @"An unknown error has occurred";
    return [NSError errorWithDomain:kAppAPIErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: desc}];
}


- (NSError *)parseServerResponseForError:(NSDictionary *)serverResponse {
    NSError *error = nil;
    id errorData = [serverResponse objectForKey:@"error"];
    if (errorData != nil) {
        if ([errorData isKindOfClass:[NSString class]]) {
            error = [AppData errorWithCode:0 description:errorData];
        }
    }
    if (error == nil) {
        [APICommunication validateAPIResult:serverResponse error:&error];
    }
    return error;
}



- (void)refreshNotifications {
    [self.pollTimer fire];
}


- (void)freeNotificationsPollTimer {
    if (self.pollTimer != nil) {
        [self.pollTimer invalidate];
        self.pollTimer = nil;
    }
}


- (void)startNotificationsPollingWithCallback:(AppDataCallback)callback {
    // kill existing timer
    [self freeNotificationsPollTimer];
//    self.pollTimer = [NSTimer scheduledTimerWithTimeInterval:60.0
//                                                      target:self
//                                                    selector:@selector(initiateNotificationsPoll:)
//                                                    userInfo:callback
//                                                     repeats:YES];
}

- (void)stopNotificationsPolling {
    [self.pollTimer invalidate];
    self.pollTimer = nil;
}

- (void)initiateNotificationsPoll:(NSTimer *)timer {
    [self performSelectorInBackground:@selector(longNotificationsPollWithCallback:) withObject:(AppDataCallback)[timer userInfo]];
}

//**** Modified for new Notifications API
- (void)longNotificationsPollWithCallback:(AppDataCallback)callback {
    
    [APICommunication getProfile:self.localUser
                     forceReload:YES
                      completion:^(NSData *data) {
                          
                          if(data == nil){
                              SAFE_CALLBACK2(nil, [NSError errorWithDomain:kAppAPIErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:@"Invalid response from get notification count" forKey:NSLocalizedDescriptionKey]]);
                              return;
                          }
                          
                          NSDictionary *result = [APICommunication convertJsonToDictionary:data];
                          
                          if ([result objectForKey:@"data"]) {
                              
                              [self.localUser supplyBasicInfoDictionary:[result objectForKey:@"data"]];
                              
                              [self sendElementNotification:kAppData_Notification_NotificationsReceived
                                                       user:self.localUser
                                                      media:nil];
                              
                              NSDictionary *response = @{@"count": [NSNumber numberWithInteger:self.localUser.totalUnreadNotifications]};
                              
                              SAFE_CALLBACK2(response, nil);
                              return;
                          }
                          
                          SAFE_CALLBACK2(nil, nil);
                          
                      } failure:^(NSError *error) {
                          
                          SAFE_CALLBACK2(nil, error);
                      }];
        
}


@end
