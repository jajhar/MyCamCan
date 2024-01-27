//
//  FeedViewController.h
//  Blog
//
//  Created by James Ajhar on 5/29/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppData.h"

@class User;

extern NSString *kBGControllerFeed;

@interface BGControllerFeed : BGController <UITableViewDelegate, UITableViewDataSource>

@end
