//
//  DataModelObject_Inherit.h
//  RedSoxApp
//
//  Created by Shakuro Developer on 5/5/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//


#import "DataModelObject.h"


@interface DataModelObject ()

// proper inits
- (id)initWithId:(NSString *)theId;
- (id)initWithBasicInfoDictionary:(NSDictionary *)basicInfo;
- (id)initWithSearchInfoDictionary:(NSDictionary *)searchInfo;

// internal accessors
- (void)setTheID:(NSString *)neweValue;

@end
