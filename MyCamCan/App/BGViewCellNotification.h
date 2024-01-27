//
//  BGViewCellNotification.h
//  Blog
//
//  Created by James Ajhar on 9/14/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGViewCell.h"

@class Notification;

@interface BGViewCellNotification : BGViewCell

- (void)setupWithNotification:(Notification *)notification;

@end
