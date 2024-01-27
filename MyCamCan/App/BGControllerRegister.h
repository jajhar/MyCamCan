//
//  RegisterViewController.h
//  Blog
//
//  Created by James Ajhar on 6/2/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//

#import "BGController.h"

extern NSString *kBGControllerRegister;

@class BGControllerRegister;

@protocol BGControllerRegisterDelegate <NSObject>

- (void)registrationFinished:(BGControllerRegister *)controller withUser:(User *)user;

@end


@interface BGControllerRegister : BGController

@property (nonatomic, assign) id delegate;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *avatarURLString;

@end
