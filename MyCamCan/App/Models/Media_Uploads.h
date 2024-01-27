//
//  Media_Uploads.h
//  RedSoxApp
//
//  Created by Shakuro Developer on 5/28/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//

#import "Media.h"


@interface Media ()

/**
 * This method is called action to generate upload file name
 */
- (void)generateUploadFileName;
/**
 * This method is called action to supply caption with new value
 */
- (void)supplyCaption:(NSString *)newValue;

@end
