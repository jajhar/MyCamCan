//
//  AppDelegate.m
//  Blog
//
//  Created by James Ajhar on 5/29/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//

#import "AppDelegate.h"
#import "WindowHitTest.h"
#import <AWSCore/AWSCore.h>
#import <AWSCognito/AWSCognito.h>
#import "BGTabBarController.h"
#import "BGControllerUpdatePassword.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

@import Firebase;

@implementation AppDelegate

- (UIWindow *)window {
    if (_window == nil) {
        _window = [[WindowHitTest alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    }
    return _window;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    // Use Firebase library to configure APIs
    [FIRApp configure];
    
    // Initialize the Google Mobile Ads SDK.
    [GADMobileAds configureWithApplicationID:@"ca-app-pub-4205559539892230~8285408386"];
    
    // Initialize the Amazon Cognito credentials provider
    
    AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
                                                          initWithRegionType:AWSRegionUSEast1
                                                          identityPoolId:@"us-east-1:3877ed5e-cbb1-4ad0-a4c7-a0916f0df22e"];
    
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:credentialsProvider];
    
    // Facebook setup
    [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];

    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"BlogStoryboard" bundle:nil];
    [AppData sharedInstance].navigationManager = (BGTabBarController *)[storyboard instantiateViewControllerWithIdentifier:@"BGTabBarController"];
    UINavigationController *loginNavController = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"LoginNavigationController"];
    [loginNavController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [loginNavController.navigationBar setShadowImage:[UIImage new]];
    [loginNavController.navigationBar setTranslucent:NO];
    [loginNavController.navigationBar setAlpha:0.0];
    [loginNavController.navigationBar setBarTintColor:[UIColor whiteColor]];
    loginNavController.navigationBar.tintColor = [UIColor redColor];

    [AppData sharedInstance].LoginNavigationController = loginNavController;
    self.window.rootViewController = loginNavController;

//    if([AppData sharedInstance].restoreLocalSession) {
//        [loginNavController presentViewController:[AppData sharedInstance].navigationManager animated:NO completion:nil];
//    }
    
    [Fabric with:@[[Crashlytics class]]];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    UIApplication *app = [UIApplication sharedApplication];
    UIBackgroundTaskIdentifier bgTask;
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:bgTask];
    }];
}
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
 
    [FBSDKAppEvents activateApp];
    
    // reload the feed on app startup to get new data
    if([AppData sharedInstance].localUser != nil) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        NSDate *lastRefreshDate = [defaults objectForKey:@"MCCLastRefreshDate"];
        if (!lastRefreshDate) {
            lastRefreshDate = [NSDate date];
            [defaults setObject:lastRefreshDate forKey:@"MCCLastRefreshDate"];
        }
        
        [defaults synchronize];

        NSInteger interval = (NSInteger) [[NSDate date] timeIntervalSinceDate: lastRefreshDate] / 60;
        
        if(interval < 10) {
            // 10 min
            return;
        }
        
        BGFeedFilterType prevFilter = [AppData sharedInstance].localUser.feedPager.filter;
        
        [AppData sharedInstance].localUser.feedPager.filter = kBGFeedFilterDefault;
        [[AppData sharedInstance].localUser.feedPager reloadWithCompletion:^(NSError *error) {
            if(error) {
                NSLog(@"Error reloading feed: %@", error);
            }
        }];
        
        [AppData sharedInstance].localUser.globalFeedPager.filter = kBGFeedFilterGlobal;
        [[AppData sharedInstance].localUser.globalFeedPager reloadWithCompletion:^(NSError *error) {
            if(error) {
                NSLog(@"Error reloading search pager: %@", error);
            }
        }];
        
        [AppData sharedInstance].localUser.feedPager.filter = prevFilter;
        
        [defaults setObject:[NSDate date] forKey:@"MCCLastRefreshDate"];
        [defaults synchronize];
    }
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(nonnull NSError *)error
{
    NSLog(@"Failed to get token, error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {

}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}

// iOS 7 or iOS 6
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSLog(@"token: %@", token);
    [[AppData sharedInstance] setDeviceToken:token];
    
    if([AppData sharedInstance].localUser != nil) {
        if(![[AppData sharedInstance].localUser.deviceToken isEqualToString:token]) {
            [[AppData sharedInstance] updateUserDeviceId:token
                                                callback:^(id result, NSError *error) {
                                                    NSLog(@"updated device token of user");
                                                }];
        }
    }
    
    // Send token to server
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    NSLog(@"***************************");
    NSLog(@"url recieved: %@", url);
    NSLog(@"query string: %@", [url query]);
    NSLog(@"host: %@", [url host]);
    NSLog(@"url path: %@", [url path]);
    NSDictionary *dict = [self parseQueryString:[url query]];
    NSLog(@"query dict: %@", dict);
    NSLog(@"***************************");
    
    if(![[url host] isEqualToString:@"mycamcan"]) {
        return [[FBSDKApplicationDelegate sharedInstance] application:app openURL:url options:options];
    }
    
    if([[url path] isEqualToString:@"/resetPassword"]) {
        
        if([dict objectForKey:@"token"]) {
            NSString *token = [dict objectForKey:@"token"];
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"BlogAutolayoutStoryboard" bundle:[NSBundle mainBundle]];
            BGControllerUpdatePassword *controller = [storyboard instantiateViewControllerWithIdentifier:@"BGControllerUpdatePassword"];
            controller.token = token;
            [[AppData sharedInstance].LoginNavigationController pushViewController:controller animated:YES];

            
        } else {
            NSLog(@"URL Scheme was missing token param");
            return NO;
        }
        
        
    }
    
    return YES;
}

- (NSDictionary *)parseQueryString:(NSString *)query {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:6];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *val = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [dict setObject:val forKey:key];
    }
    return dict;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}

@end
