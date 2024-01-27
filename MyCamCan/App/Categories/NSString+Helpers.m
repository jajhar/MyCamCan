//
//  NSString+Helpers.m
//  MCC
//
//  Created by Cameron Pierce on 1/26/15.
//  Copyright (c) 2015 D9. All rights reserved.
//

#import "NSString+Helpers.h"

@implementation NSString (Helpers)

- (NSString*) truncateStringAtLength:(NSUInteger) maxLength {
    NSRange nameRange = {0, MIN([self length], maxLength)};
    NSUInteger nameLength = [self length];
    NSMutableString *mutableTruncatedName = [NSMutableString stringWithString:[self substringWithRange:nameRange]];
    if (nameLength > mutableTruncatedName.length) {
        [mutableTruncatedName appendString:@"..." ];
    }
    return mutableTruncatedName;
}

@end
