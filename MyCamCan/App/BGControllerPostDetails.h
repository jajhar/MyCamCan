//
//  BGControllerPostDetails.h
//  Blog
//
//  Created by James Ajhar on 11/9/15.
//  Copyright © 2015 James Ajhar. All rights reserved.
//

#import "BGController.h"

typedef enum BGPostDetailsConfiguration: NSUInteger {
    BGPostDetailsConfigurationExplore,
    BGPostDetailsConfigurationSinglePost
} BGPostDetailsConfiguration;

@interface BGControllerPostDetails : BGController

@property (nonatomic, assign) BGPostDetailsConfiguration configuration;

@end
