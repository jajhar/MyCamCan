//
//  Media.h
//  RedSoxApp
//
//  Created by James Ajhar on 11/25/13.
//  Copyright (c) 2013 James Ajhar. All rights reserved.
//

#import "DataModelObject.h"
#import "MBProgressHUD.h"

@class LikesPager;
@class MusicItem;
@class User;
@class CommentsPager;

typedef void (^mediaWatermarkCallback)(NSURL *url, NSError *error);

typedef NS_OPTIONS(NSUInteger, BGMediaTypes) {
    kVXMediaTypeNone    = 0,
    kVXMediaTypePhoto   = 1 << 0,
    kVXMediaTypeVideo   = 1 << 1,
    
    kVXMediaTypeAll     =
    kVXMediaTypePhoto |
    kVXMediaTypeVideo
};


@interface Media : DataModelObject //<MediaContentTarget>


//--inits
+ (Media *)mediaWithBasicInfoDictionary:(NSDictionary *)basicInfo;
+ (Media *)mediaWithId:(NSString *)theId;
+ (Media *)mediaWithImage:(UIImage *)image;
+ (Media *)mediaWithMovieAtPath:(NSString *)pathToMovie;

//--data
@property (strong, nonatomic, readonly) NSString *name;             // name of media (user defined)
@property (strong, nonatomic) NSString *caption;          // text caption of this media (user defined)
@property (strong, nonatomic, readonly) NSString *createdAt;        // Time at which media was created (MongoDB ISO Format)
@property (strong, nonatomic, readonly) User *owner;                // the user that created this media
@property (strong, nonatomic, readonly) CommentsPager *commentsPager;
@property (strong, nonatomic, readonly) LikesPager *likesPager;
@property (strong, nonatomic) NSURL *mediaUrl;
@property (strong, nonatomic) NSURL *thumbUrl;
@property (strong, nonatomic) NSURL *linkURL;
@property (strong, nonatomic) NSURL *localFileURL;
@property (strong, nonatomic) NSString *uploadFileName;             // S3FileName
@property (strong, nonatomic) NSString *thumbName;
@property (strong, nonatomic, readonly) NSString *createTime;                 // Time at which media was created (readable format)
@property (nonatomic, readonly) BOOL liked;
@property (assign, nonatomic) BOOL isDeleted;
@property (assign, nonatomic) BOOL isDeleting;
@property (nonatomic) NSInteger totalLikes;
@property (nonatomic, strong) MusicItem *musicItem;

//--actions

+ (void)addWaterMarkToVideo:(NSURL *)videoURL completion:(mediaWatermarkCallback)completion;

@end
