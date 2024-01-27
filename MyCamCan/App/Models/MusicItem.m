//
//  MusicItem.m
//  Blog
//
//  Created by James Ajhar on 7/22/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "MusicItem.h"
#import "DataModelObject_Inherit.h"
#import "AppData.h"

@interface MusicItem ()

@end


@implementation MusicItem


#pragma mark - Initialization

- (id)init {
    self = [super init];
    
    if(self) {
        self.needsExport = NO;
    }
    
    return self;
}

+ (MusicItem *)musicItemWithBasicInfoDictionary:(NSDictionary *)basicInfo {
    MusicItem *musicItem = [[MusicItem alloc] initWithBasicInfoDictionary:basicInfo];
    musicItem.needsExport = NO;
    
    return musicItem;
}

+ (MusicItem *)musicItemWithSearchInfoDictionary:(NSDictionary *)searchInfo {
    MusicItem *musicItem = [[MusicItem alloc] init];
    
    [musicItem supplySearchInfoDictionary:searchInfo];
    musicItem.needsExport = NO;
    
    return musicItem;
}

#pragma mark - Parsing


- (void)supplyBasicInfoDictionary:(NSDictionary *)basicInfo {
    [super supplyBasicInfoDictionary:basicInfo];
    
    
    id temp = [basicInfo objectForKey:@"name"];
    if(temp != nil) {
        self.title = temp;
    }
    
    temp = [basicInfo objectForKey:@"images"];
    if(temp != nil && [temp isKindOfClass:[NSArray class]]) {
        self.imageURL = [NSURL URLWithString:[temp lastObject]];
        
        NSString *string = [[temp lastObject] substringToIndex:[[temp lastObject] length] - 17];
        self.imageURLHighResolution = [NSURL URLWithString:[NSString stringWithFormat:@"%@/300x300.jpg", string]];
    }
    
    temp = [basicInfo objectForKey:@"artist"];
    if(temp != nil) {
        self.artist = temp;
    }
    
    temp = [basicInfo objectForKey:@"link"];
    if(temp != nil) {
        self.previewURL = [NSURL URLWithString:temp];
    }
        
    temp = [basicInfo objectForKey:@"url"];
    if(temp != nil) {
        self.musicURL = [NSURL URLWithString:temp];
    }
}

- (void)supplySearchInfoDictionary:(NSDictionary *)searchInfo {
    //    [super supplyBasicInfoDictionary:searchInfo];
    
    id temp = [searchInfo objectForKey:@"trackName"];
    if(temp != nil) {
        self.title = temp;
    }
    
    temp = [searchInfo objectForKey:@"artworkUrl100"];
    if(temp != nil) {
        self.imageURL = [NSURL URLWithString:temp];
        
        NSString *string = [temp substringToIndex:[temp length] - 13];
        self.imageURLHighResolution = [NSURL URLWithString:[NSString stringWithFormat:@"%@300x300.jpg", string]];
        
    }
    
    temp = [searchInfo objectForKey:@"trackViewUrl"];
    if(temp != nil) {
        self.musicURL = [NSURL URLWithString:temp];
    }
    
    temp = [searchInfo objectForKey:@"artistName"];
    if(temp != nil) {
        self.artist = temp;
    }
    
    temp = [searchInfo objectForKey:@"previewUrl"];
    if(temp != nil) {
        self.previewURL = [NSURL URLWithString:temp];
    }
}


@end
