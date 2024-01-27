//
//  BGCellContact.m
//  Blog
//
//  Created by James Ajhar on 9/13/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGCellContact.h"
#import <APAddressBook/APContact.h>

@interface BGCellContact ()

@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UIButton *inviteButton;
@property (strong, nonatomic) APContact *contact;


@end


@implementation BGCellContact

- (void)commonInit {
    [super commonInit];
    
}

- (void)setInviteSelected:(BOOL)selected {    
    self.inviteButton.selected = selected;
}

- (void)setupWithContact:(APContact *)contact {
    _contact = contact;
    
//    self.nameLabel.text = [NSString stringWithFormat:@"%@ %@", contact.firstName, contact.lastName];
}


@end
