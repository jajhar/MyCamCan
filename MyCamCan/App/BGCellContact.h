//
//  BGCellContact.h
//  Blog
//
//  Created by James Ajhar on 9/13/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGViewCell.h"

@class APContact;

@interface BGCellContact : BGViewCell

@property (strong, nonatomic, readonly) APContact *contact;

- (void)setInviteSelected:(BOOL)selected;
- (void)setupWithContact:(APContact *)contact;

@end
