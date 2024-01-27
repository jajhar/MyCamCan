//
//  BGViewCellNotification.m
//  Blog
//
//  Created by James Ajhar on 9/14/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGViewCellNotification.h"
#import "Notification.h"
#import "Media.h"

@interface BGViewCellNotification ()
@property (strong, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet UIImageView *actionImageView;

@property (strong, nonatomic) Notification *notification;
@end


@implementation BGViewCellNotification

- (void)commonInit {
    [super commonInit];
    
    self.actionImageView.layer.cornerRadius = CGRectGetWidth(self.actionImageView.frame) / 2;
    self.actionImageView.clipsToBounds = YES;
    
}

- (void)setupWithNotification:(Notification *)notification {
    
    _notification = notification;
    
    self.messageLabel.text = notification.message;
    [self.actionImageView sd_setImageWithURL:self.notification.fromUser.avatarUrl placeholderImage:[UIImage imageNamed:@"default_avatar"]];
}

@end
