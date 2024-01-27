//
//  LocalSession.h
//  RedSoxApp
//
//  Created by Shakuro Developer on 5/8/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//


#import <Foundation/Foundation.h>


@interface LocalSession : NSObject

@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *oauthToken;
@property (strong, nonatomic) NSURL *avatarUrl;
@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSString *phone;
@property (strong, nonatomic) NSDate *birthday;

@end
