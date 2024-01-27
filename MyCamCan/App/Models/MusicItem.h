//
//  MusicItem.h
//  Blog
//
//  Created by James Ajhar on 7/22/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "DataModelObject.h"

@interface MusicItem : DataModelObject

//--inits
+ (MusicItem *)musicItemWithBasicInfoDictionary:(NSDictionary *)basicInfo;
+ (MusicItem *)musicItemWithSearchInfoDictionary:(NSDictionary *)searchInfo;

@property (strong, nonatomic) NSURL *previewURL;
@property (strong, nonatomic) NSURL *localFileURL;
@property (strong, nonatomic) NSURL *imageURL;
@property (strong, nonatomic) NSURL *imageURLHighResolution;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *album;
@property (strong, nonatomic) NSString *artist;
@property (strong, nonatomic) NSString *grouping;
@property (strong, nonatomic) NSString *genre;
@property (strong, nonatomic) UIImage *artwork;
@property (strong, nonatomic) NSURL *musicURL;

@property (nonatomic) CGFloat startTime;
@property (nonatomic) CGFloat endTime;
@property (nonatomic, assign) BOOL needsExport;

@end
