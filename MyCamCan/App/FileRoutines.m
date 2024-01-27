#import "FileRoutines.h"

@implementation FileRootines

NSString *DocumentPath = nil;

+ (NSString *)documentPath {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        if (documentPaths.count != 0) {
            DocumentPath = [documentPaths objectAtIndex:0];
        }
    });
    return DocumentPath;
}

+ (NSString *)moveFileToMoviesFolder:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentPath = [self documentPath];
    NSString *moveToPath = nil;
    if (documentPath == nil) {
        //can't get document path
        return path;
    } else {
        moveToPath = [documentPath stringByAppendingPathComponent:@"movies"];
        if ([moveToPath isEqualToString:[path stringByDeletingLastPathComponent]]) {
            //won't move to same path
            return path;
        } else {
            moveToPath = [moveToPath stringByAppendingPathComponent:[path lastPathComponent]];
        }
    }

    NSError *error = nil;
    if ([fileManager createDirectoryAtPath:[moveToPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error]) {
        if ([fileManager moveItemAtPath:path toPath:moveToPath error:&error]) {
            //file moved
            return moveToPath;
        } else {
            //can't move file
            return path;
        }
    } else {
        //can't create directory
        return path;
    }
}

@end
