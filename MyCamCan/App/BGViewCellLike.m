//
//  BGViewCellLike.m
//  Blog
//
//  Created by James Ajhar on 9/25/15.
//  Copyright © 2015 James Ajhar. All rights reserved.
//

#import "BGViewCellLike.h"
#import "Like.h"

@interface BGViewCellLike ()

// Interface
@property (strong, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) IBOutlet UILabel *countLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;

// Data
@property (strong, nonatomic) Like *like;

@end


@implementation BGViewCellLike

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = CGRectGetWidth(self.avatarImageView.frame) / 2.0;
}

- (void)setupWithLike:(Like *)like {
    
    _like = like;
    
    self.usernameLabel.text = _like.owner.username;
    self.countLabel.text = [NSString stringWithFormat:@"%lu", _like.total];
    
    [self loadAvatarImage];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.avatarImageView setImage:[UIImage imageNamed:@"default_avatar"]];
}

- (void)loadAvatarImage {
    [self.avatarImageView sd_setImageWithURL:self.like.owner.avatarUrl placeholderImage:[UIImage imageNamed:@"default_avatar"]];
}

- (IBAction)avatarPressed:(id)sender {
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [[AppData sharedInstance].navigationManager.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];
    
    [[AppData sharedInstance].navigationManager dismissViewControllerAnimated:NO completion:nil];

    [[AppData sharedInstance].navigationManager presentControllerForPurpose:kBGPurposeProfile info:@{kVXKeyUser: self.like.owner} showTabBar:YES];
}

@end
