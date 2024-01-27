//
//  DataModelObject.h
//  RedSoxApp
//
//  Created by Shakuro Developer on 5/5/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//


#import <Foundation/Foundation.h>


@interface DataModelObject : NSObject

//--data
@property (strong, nonatomic, readonly) NSString *theId;   // id of this object

//--parsing
+ (NSString *)IDFromBasicInfoDictionary:(NSDictionary *)basicInfo;
- (void)supplyBasicInfoDictionary:(NSDictionary *)basicInfo;
+ (NSString *)IDFromSearchInfoDictionary:(NSDictionary *)searchInfo;
+ (NSString *)IDFromUploadResult:(NSDictionary *)uploadResult;
- (void)supplySearchInfoDictionary:(NSDictionary *)searchInfo;
- (void)supplyUploadResult:(NSDictionary *)uploadResult;

+ (BOOL)modelObject:(DataModelObject *)a isEqualTo:(DataModelObject *)b;

@end
