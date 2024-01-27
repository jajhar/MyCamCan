//
//  Media.m
//  RedSoxApp
//
//  Created by James Ajhar on 11/25/13.
//  Copyright (c) 2013 James Ajhar. All rights reserved.
//


#import "Media.h"
#import "Media_Uploads.h"

#import "AppData.h"
#import "AppData_ModelInternal.h"

#import "DataModelObject_Inherit.h"
#import "User.h"

#import "NSURL+RefersLocalProperty.h"
#import "FileRoutines.h"

#import "MusicItem.h"
#import "UIImage+BGFixOrientation.h"
#import "LikesPager.h"
#import "URLs.h"

@import Photos;

NSString *kVXKeyMediaTypesAllowed = @"BGKeyMediaTypesAllowed";


@implementation Media

#pragma mark - Initialization


+ (Media *)mediaWithBasicInfoDictionary:(NSDictionary *)basicInfo {
    Media *media = [[Media alloc] initWithBasicInfoDictionary:basicInfo];
	if (media.theId == nil) {
		media = nil;
    }
	return media;
}


+ (Media *)mediaWithId:(NSString *)theId {
	return [[Media alloc] initWithId:theId];
}


+ (Media *)mediaWithImage:(UIImage *)image {
    //should we use 2001 as reference date?
    return [[Media alloc] initWithOwner:[AppData sharedInstance].localUser
                                  image:image
                               mediaURL:[NSURL urlReferringLocalProperty:@"content"]
                             createTime:@"< 1 min ago"];
}


+ (Media *)mediaWithMovieAtPath:(NSString *)pathToMovieTmp {
    return [[Media alloc] initWithOwner:[AppData sharedInstance].localUser
                                   name:@""
                                caption:@""
                               mediaURL:[NSURL fileURLWithPath:[FileRootines moveFileToMoviesFolder:pathToMovieTmp]]
                             createTime:@"< 1 min ago"];
}


- (id)initWithOwner:(User *)owner image:(UIImage *)image mediaURL:(NSURL *)mediaURL createTime:(NSString *)createTime {
    self = [self initWithId:nil];
    if (self != nil) {
        _mediaUrl = mediaURL;
        _owner = owner;
        _createTime = createTime;
    }
    return self;
}


- (id)initWithOwner:(User *)owner name:(NSString *)name caption:(NSString *)caption mediaURL:(NSURL *)mediaURL createTime:(NSString *)createTime {
    // for videos
    self = [self initWithId:nil];
    if (self != nil) {
        _owner = owner;
        _name = name;
        _caption = caption;
        _mediaUrl = mediaURL;
        _createTime = createTime;
    }
    return self;
}


- (id)init {
    self = [super init];
	if (self != nil) {
        self.musicItem = [[MusicItem alloc] init];
	}
	return self;
}

@synthesize likesPager = _likesPager;

#pragma mark - Accessors

- (LikesPager *)likesPager {
    if (_likesPager == nil) {
        _likesPager = [LikesPager likesPagerForMedia:self];
    }
    return _likesPager;
}

#pragma mark - Parsing


- (void)supplyBasicInfoDictionary:(NSDictionary *)basicInfo {
    [super supplyBasicInfoDictionary:basicInfo];
    
    // owner
    id temp = [basicInfo objectForKey:@"owner"];
    if ([temp isKindOfClass:[NSDictionary class]]) {
        _owner = [[AppData sharedInstance] getUserFromPoolWithInfo:temp];
    } else if ([basicInfo objectForKey:@"ownerId"]) {
        _owner = [[AppData sharedInstance] getUserFromPoolWithID:[basicInfo objectForKey:@"ownerId"]];
    }
    
    // media URL
    temp = [basicInfo objectForKey:@"fileName"];
    if ([temp isKindOfClass:[NSString class]]) {
        _mediaUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [URLs s3CDN], temp]];
    }
    
    // thumb URL
    temp = [basicInfo objectForKey:@"thumbName"];
    if ([temp isKindOfClass:[NSString class]]) {
        _thumbUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [URLs s3CDN], temp]];
    }
    
    // link URL
    temp = [basicInfo objectForKey:@"link"];
    if ([temp isKindOfClass:[NSString class]] && [temp length] > 0) {
        
        if ([[(NSString *)temp lowercaseString] hasPrefix:@"http://"] ||
            [[(NSString *)temp lowercaseString] hasPrefix:@"https://"]) {
            _linkURL = [NSURL URLWithString:temp];
        } else {
            _linkURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", temp]];
        }
    }
    
    // preview URL
    temp = [basicInfo objectForKey:@"musicUrl"];
    if ([temp isKindOfClass:[NSString class]]) {
        self.musicItem.previewURL = [NSURL URLWithString:temp];
    }

    temp = [basicInfo objectForKey:@"caption"];
    if(temp != nil && [temp isKindOfClass:[NSString class]]) {
        _caption = temp;
    }
    
    temp = [basicInfo objectForKey:@"likeCount"];
    if (temp != nil && [temp isKindOfClass:[NSNumber class]]) {
        _totalLikes = [temp integerValue];
    }
    
    // created time
    temp = [basicInfo objectForKey:@"createdAt"];
    if ([temp isKindOfClass:[NSString class]]) {
        _createdAt = temp;
    }
    
    // Get time created in proper format "n ago"
    unsigned long long result;
    BOOL success = [[NSScanner scannerWithString:[self.theId substringToIndex:8]] scanHexLongLong:&result];
    if (success) {
        NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:result];
        _createTime = [[AppData sharedInstance] dateStringRelativeFromDateSince1970:date];
    } else {
        _createTime = nil;
    }
}


#pragma mark - MediaContentTarget protocol


- (void)contentPrepared:(id)info {
    //nop
}


- (void)startContentSupply:(id)info {
    //nop
}


- (void)supplyVideoContent:(void *)content info:(id)info {
    //nop
}


- (void)supplyAudioContent:(void *)content info:(id)info {
    //nop
}


- (void)stopContentSupply:(id)info {
    //nop
}


- (void)contentWillBeCleared:(id)info {
    //nop
}


#pragma mark - Actions

+ (void)addWaterMarkToVideo:(NSURL *)videoURL completion:(mediaWatermarkCallback)completion {
    
    NSURL *video_url = videoURL;
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:video_url options:nil];
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    CGSize videoSize = [[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
    
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo  preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *clipVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                   ofTrack:clipVideoTrack
                                    atTime:kCMTimeZero error:nil];
    
    [compositionVideoTrack setPreferredTransform:[[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] preferredTransform]];
    
    CATextLayer *titleLayer = [CATextLayer layer];
    titleLayer.string = @"MyCamCan - www.mycamcan.com";
    titleLayer.font = (__bridge CFTypeRef _Nullable)([UIFont fontWithName:@"Helvetica" size:18.0]);
    titleLayer.opacity = 0.5;
    titleLayer.shadowOpacity = 0.5;
    titleLayer.alignmentMode = kCAAlignmentRight;
    titleLayer.frame = CGRectMake(0, 0, videoSize.width-50.0, 100.0); // You may need to adjust this for proper display
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:titleLayer];
    
    AVMutableVideoComposition* videoComp = [AVMutableVideoComposition videoComposition];
    videoComp.renderSize = videoSize;
    videoComp.frameDuration = CMTimeMake(1, 30);
    videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    /// instruction
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
    AVAssetTrack *videoTrack = [[mixComposition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    
    AVAssetTrack *audioTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    CMTime duration = audioTrack.timeRange.duration;
    compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, duration)
                                   ofTrack:audioTrack
                                    atTime:kCMTimeZero error:nil];
    
    
    
    [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    
    AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    videoComp.instructions = [NSArray arrayWithObject: instruction];
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *outputFilePath = [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"FinalVideoWithWatermark-%f.mov", [NSDate timeIntervalSinceReferenceDate]]];
    NSURL *outputFileUrl = [NSURL fileURLWithPath:outputFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputFilePath])
        [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
    
    // Now create an AVAssetExportSession object that will save your final video at specified path.
    AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    _assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    _assetExport.outputURL = outputFileUrl;
    _assetExport.videoComposition = videoComp;
    
    [_assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         dispatch_async(dispatch_get_main_queue(), ^{
             
             if(_assetExport.status == AVAssetExportSessionStatusCompleted){
                 completion(outputFileUrl, nil);
             } else if(_assetExport.status == AVAssetExportSessionStatusFailed ) {
                 NSLog(@"ERROR: %@", _assetExport.error);
                 completion(nil, _assetExport.error);
             }
         });
     }];
    
}

#pragma mark - Upload


- (void)generateUploadFileName {
    if (self.uploadFileName == nil) {
        NSString *postfix = @"mov";
        NSString *key = @"";

        if (self.theId != nil) {
            key = [[AppData sharedInstance] md5Conversion:self.theId];
        } else {
            NSURL *url = self.mediaUrl;

            if (url != nil) {
                key = [[AppData sharedInstance] md5Conversion:[url absoluteString]];
            } else if (self.createTime != nil) {
                key = [[AppData sharedInstance] md5Conversion:[NSString stringWithFormat:@"%lu", (unsigned long)[self.createTime hash]]];
            }
        }

        _uploadFileName = [NSString stringWithFormat:@"%@.%@",key,postfix];
    }
}


- (void)supplyCaption:(NSString *)newValue {
    _caption = newValue;
}


@end
