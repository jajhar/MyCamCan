//
//  Like.h
//  RedSoxApp
//
//  Created by James Ajhar on 2/3/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "DataModelObject.h"


@interface Like : DataModelObject

//--inits
+ (Like *)likeWithBasicInfoDictionary:(NSDictionary *)basicInfo;

//--data
@property (strong, nonatomic) User *owner;
@property (strong, nonatomic) NSString *createdAt;
@property (nonatomic) NSInteger total;

@end
