//
//  Like.m
//  RedSoxApp
//
//  Created by James Ajhar on 2/3/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//


#import "Like.h"
#import "DataModelObject_Inherit.h"
#import "AppData_ModelInternal.h"


@implementation Like

@synthesize owner = _owner;
@synthesize createdAt = _createdAt;

#pragma mark - Initialization


+ (Like *)likeWithBasicInfoDictionary:(NSDictionary *)basicInfo {
    Like *like = [[Like alloc] initWithBasicInfoDictionary:basicInfo];
	if (like.theId == nil) {
		like = nil;
    }
	return like;
}


#pragma mark - Parsing


- (void)supplyBasicInfoDictionary:(NSDictionary *)basicInfo {
    [super supplyBasicInfoDictionary:basicInfo];
    
    // owner
    id temp = [basicInfo objectForKey:@"userInfo"];
    if ([temp isKindOfClass:[NSDictionary class]]) {
        _owner = [[AppData sharedInstance] getUserFromPoolWithInfo:temp];
    } else if ([temp isKindOfClass:[NSString class]]) {
        _owner = [[AppData sharedInstance] getUserFromPoolWithID:temp];
    }
    
    // total likes
    temp = [basicInfo objectForKey:@"total"];
    if ([temp isKindOfClass:[NSNumber class]]) {
        _total = [temp integerValue];
    }
    
    // created time
    temp = [basicInfo objectForKey:@"createdAt"];
    if ([temp isKindOfClass:[NSString class]]) {
        _createdAt = temp;
    }
}


@end
