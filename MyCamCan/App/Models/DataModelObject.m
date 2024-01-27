//
//  DataModelObject.m
//  RedSoxApp
//
//  Created by Shakuro Developer on 5/5/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//


#import "DataModelObject.h"
#import "DataModelObject_Inherit.h"


@interface DataModelObject()
//TODO:clean?
@end


@implementation DataModelObject

@synthesize theId = _theId;

#pragma mark - Initialization


- (id)initWithBasicInfoDictionary:(NSDictionary *)basicInfo {
    NSString *theId = [[self class] IDFromBasicInfoDictionary:basicInfo];
    self = [self initWithId:theId];
    if (self) {
        [self supplyBasicInfoDictionary:basicInfo];
    }
    return self;
}


- (id)initWithSearchInfoDictionary:(NSDictionary *)searchInfo {
    NSString *theID = [[self class] IDFromSearchInfoDictionary:searchInfo];
    self = [self initWithId:theID];
    if (self) {
        [self supplySearchInfoDictionary:searchInfo];
    }
    return self;
}


- (id)initWithId:(NSString *)theId {
    self = [self init];
	if (self != nil) {
		_theId = theId;
	}
	return self;
}


#pragma mark - Parsing server results


+ (NSString *)IDFromBasicInfoDictionary:(NSDictionary *)basicInfo {
    return [basicInfo objectForKey:@"id"];
}


- (void)supplyBasicInfoDictionary:(NSDictionary *)basicInfo {
    _theId = [[self class] IDFromBasicInfoDictionary:basicInfo];
}


+ (NSString *)IDFromSearchInfoDictionary:(NSDictionary *)searchInfo {
    return [self IDFromBasicInfoDictionary:searchInfo];
}

+ (NSString *)IDFromUploadResult:(NSDictionary *)uploadResult {
    return [self IDFromBasicInfoDictionary:uploadResult];
}

- (void)supplySearchInfoDictionary:(NSDictionary *)searchInfo {
    _theId = [[self class] IDFromSearchInfoDictionary:searchInfo];
}


- (void)supplyUploadResult:(NSDictionary *)uploadResult {
    _theId = [[self class] IDFromUploadResult:uploadResult];
}

#pragma mark - Accessors


- (void)setTheID:(NSString *)newValue {
    _theId = newValue;
}


#pragma mark - Supplemental


+ (BOOL)modelObject:(DataModelObject *)a isEqualTo:(DataModelObject *)b {
    if (a == b) {
        return YES;
    } else {
        if ((a != nil) && (b != nil)) {
            return [a.theId isEqualToString:b.theId];
        } else {
            return NO;
        }
    }
}


- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[DataModelObject class]]) {
        return [DataModelObject modelObject:self isEqualTo:(DataModelObject *)object];
    } else {
        return NO;
    }
}


@end
