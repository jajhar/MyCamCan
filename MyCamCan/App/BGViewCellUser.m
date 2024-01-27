//
//  BGViewCellUser.m
//  Blog
//
//  Created by James Ajhar on 9/9/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGViewCellUser.h"

@interface BGViewCellUser ()

@property (strong, nonatomic) IBOutlet UIImageView *coverImageView;
@property (strong, nonatomic) IBOutlet UIButton *avatarButton;
@property (strong, nonatomic) IBOutlet UILabel *locationLabel;
@property (strong, nonatomic) IBOutlet UIButton *usernameButton;
@property (strong, nonatomic) IBOutlet UIButton *followButton;

@property (strong, nonatomic) User *user;

@end


@implementation BGViewCellUser

- (void)commonInit {
    [super commonInit];

    // notifications
    NSNotificationCenter *sharedNC = [NSNotificationCenter defaultCenter];
    
    [sharedNC addObserver:self
                 selector:@selector(notificationUserUpdated:)
                     name:kAppData_Notification_UserUpdated
                   object:nil];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.avatarButton.clipsToBounds = YES;
    self.avatarButton.layer.cornerRadius = CGRectGetWidth(self.avatarButton.frame) / 2.0;
    self.avatarButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    self.followButton.layer.cornerRadius = 5.0;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Interface Actions

- (IBAction)followPressed:(id)sender {
    
    self.followButton.enabled = NO;
    
    if(self.user.isFollowing) {
        [[AppData sharedInstance] stopFollowingUser:self.user
                                           callback:^(id result, NSError *error) {
                                               
                                               self.followButton.enabled = YES;
                                               
                                               if(error) {
                                                   [[[UIAlertView alloc] initWithTitle:@"Uh Oh!"
                                                                               message:@"Something went wrong. Please try again."
                                                                              delegate:nil
                                                                     cancelButtonTitle:@"Ok"
                                                                     otherButtonTitles:nil] show];
                                               }
                                           }];
    } else {
        [[AppData sharedInstance] startFollowingUser:self.user
                                            callback:^(id result, NSError *error) {
                                                
                                                self.followButton.enabled = YES;
                                                
                                                if(error) {
                                                    [[[UIAlertView alloc] initWithTitle:@"Uh Oh!"
                                                                                message:@"Something went wrong. Please try again."
                                                                               delegate:nil
                                                                      cancelButtonTitle:@"Ok"
                                                                      otherButtonTitles:nil] show];
                                                }
                                            }];
    }
}

- (IBAction)avatarPressed:(id)sender {
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [[AppData sharedInstance].navigationManager.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];

    [[AppData sharedInstance].navigationManager dismissViewControllerAnimated:NO completion:nil];
    
    [[AppData sharedInstance].navigationManager presentControllerForPurpose:kBGPurposeProfile
                                                                       info:@{kVXKeyUser: self.user}
                                                                 showTabBar:YES];
}


- (void)setupWithUser:(User *)user {
    _user = user;
    
    [self loadUserImages];
    [self.usernameButton setTitle:self.user.username forState:UIControlStateNormal];
//    self.locationLabel.text = self.user.location;
   
    if(self.user != [AppData sharedInstance].localUser) {
        self.followButton.hidden = NO;
        
        [self setupFollowButton];

    } else {
        self.followButton.hidden = YES;
    }
    
}

- (void)setupFollowButton {
    if(self.user.isFollowing) {
        
        [self.followButton setSelected:YES];
        self.followButton.backgroundColor = [UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1.0];
        self.followButton.layer.borderColor = [[UIColor whiteColor] CGColor];
        [self.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.followButton.layer.borderWidth = 1.0;
    } else {
        [self.followButton setSelected:NO];
        self.followButton.backgroundColor = [UIColor whiteColor];
        self.followButton.layer.borderColor = [[UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1.0] CGColor];
        [self.followButton setTitleColor:[UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        self.followButton.layer.borderWidth = 1.0;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)loadUserImages {
    
//    [self setupProgressView];

    __block BGViewCellUser *blockSelf = self;
    [blockSelf.avatarButton setImage:[UIImage imageNamed:@"default_avatar"] forState:UIControlStateNormal];

    SDWebImageDownloader *manager = [SDWebImageDownloader sharedDownloader];

    [manager downloadImageWithURL:self.user.avatarUrl
                          options:0
                         progress:nil
                        completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                            if(image && !error) {
                                [blockSelf.avatarButton setImage:image forState:UIControlStateNormal];
                            } else {
                                // handle default image
                                [blockSelf.avatarButton setImage:[UIImage imageNamed:@"default_avatar"] forState:UIControlStateNormal];
                            }
                        }];
}

#pragma mark Notifications


/**
 *<p>
 *  This method will be called via NSNotificationCenter whenever the list of feed media has changed in some way.
 *  It will add, remove, or refresh cells accordingly.
 */
- (void)notificationUserUpdated:(NSNotification *)notification {
    User *user = [[notification userInfo] objectForKey:kAppData_NotificationKey_User];
    if ([DataModelObject modelObject:user isEqualTo:self.user]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupWithUser:self.user];
        });
    }
}



@end
