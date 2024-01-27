//
//  BGViewProfileHeader.m
//  Blog
//
//  Created by James Ajhar on 9/4/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGViewProfileHeader.h"

#import "User.h"
#import "DACircularProgressView.h"
#import "BGControllerUsers.h"

@interface BGViewProfileHeader ()

// Interface
@property (strong, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (strong, nonatomic) IBOutlet UIImageView *coverPhotoImageView;
@property (strong, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) IBOutlet UIButton *menuButton;
@property (strong, nonatomic) IBOutlet UIButton *followButton;
@property (strong, nonatomic) IBOutlet UIButton *uploadCoverButton;
@property (strong, nonatomic) IBOutlet UIButton *uploadAvatarButton;
@property (strong, nonatomic) IBOutlet UIButton *totalFollowingButton;
@property (strong, nonatomic) IBOutlet UIButton *totalFollowersButton;

@property (strong, nonatomic) DACircularProgressView *progressView;

// Data
@property (strong, nonatomic) User *user;

@end

@implementation BGViewProfileHeader

- (void)commonInit {
    [super commonInit];
    
    self.avatarImageView.layer.cornerRadius = CGRectGetWidth(self.avatarImageView.frame) / 2.0;

    // notifications
    NSNotificationCenter *sharedNC = [NSNotificationCenter defaultCenter];
    
    [sharedNC addObserver:self
                 selector:@selector(notificationUserUpdated:)
                     name:kAppData_Notification_UserUpdated
                   object:nil];
    
    self.followButton.layer.cornerRadius = 5.0;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Interface Actions


- (IBAction)totalFollowingPressed:(id)sender {
    UIViewController *controller = [[AppData sharedInstance].navigationManager presentControllerForPurpose:kBGPurposeUsers info:@{kVXKeyUser: self.user, kBGKeyUsersFilter: [NSNumber numberWithInteger:kBGControllerUsersFilterTypeFollowees]} showTabBar:YES pushImmediately:NO];
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [[AppData sharedInstance].navigationManager.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];
    
    [[AppData sharedInstance].navigationManager presentViewController:controller animated:NO completion:nil];

}

- (IBAction)totalFollowersPressed:(id)sender {
    UIViewController *controller = [[AppData sharedInstance].navigationManager presentControllerForPurpose:kBGPurposeUsers info:@{kVXKeyUser: self.user, kBGKeyUsersFilter: [NSNumber numberWithInteger:kBGControllerUsersFilterTypeFollowers]} showTabBar:YES pushImmediately:NO];
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [[AppData sharedInstance].navigationManager.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];
    
    [[AppData sharedInstance].navigationManager presentViewController:controller animated:NO completion:nil];
}

- (IBAction)followPressed:(id)sender {
    
    self.followButton.enabled = NO;
    
    if(self.user.isFollowing) {
        
        [self.followButton setSelected:NO];
        self.followButton.backgroundColor = [UIColor whiteColor];
        self.followButton.layer.borderColor = [[UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1.0] CGColor];
        [self.followButton setTitleColor:[UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        self.followButton.layer.borderWidth = 1.0;
        
        [[AppData sharedInstance] stopFollowingUser:self.user
                                            callback:^(id result, NSError *error) {
                                                
                                                self.followButton.enabled = YES;
                                            
                                                if(error) {
                                                    
                                                    [self.followButton setSelected:YES];
                                                    self.followButton.backgroundColor = [UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1.0];
                                                    self.followButton.layer.borderColor = [[UIColor whiteColor] CGColor];
                                                    [self.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                                                    self.followButton.layer.borderWidth = 1.0;
                                                    
                                                    [[[UIAlertView alloc] initWithTitle:@"Uh Oh!"
                                                                                message:@"Something went wrong. Please try again."
                                                                               delegate:nil
                                                                      cancelButtonTitle:@"Ok"
                                                                      otherButtonTitles:nil] show];
                                                }
                                            }];
    } else {
        
        [self.followButton setSelected:YES];
        self.followButton.backgroundColor = [UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1.0];
        self.followButton.layer.borderColor = [[UIColor whiteColor] CGColor];
        [self.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.followButton.layer.borderWidth = 1.0;
        
        [[AppData sharedInstance] startFollowingUser:self.user
                                            callback:^(id result, NSError *error) {
                                                
                                                self.followButton.enabled = YES;

                                                if(error) {
                                                    
                                                    [self.followButton setSelected:NO];
                                                    self.followButton.backgroundColor = [UIColor whiteColor];
                                                    self.followButton.layer.borderColor = [[UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1.0] CGColor];
                                                    [self.followButton setTitleColor:[UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1.0] forState:UIControlStateNormal];
                                                    self.followButton.layer.borderWidth = 1.0;
                                                    
                                                    [[[UIAlertView alloc] initWithTitle:@"Uh Oh!"
                                                                               message:@"Something went wrong. Please try again."
                                                                              delegate:nil
                                                                     cancelButtonTitle:@"Ok"
                                                                      otherButtonTitles:nil] show];
                                                }
                                            }];
    }
}

#pragma mark - Helpers


- (void)setupWithUser:(User *)user {
    _user = user;
     
    [self loadUserImages];
    self.usernameLabel.text = self.user.username;
    
    if(self.user != [AppData sharedInstance].localUser) {
        self.menuButton.hidden = YES;
        self.followButton.hidden = NO;
        self.uploadCoverButton.hidden = YES;
        self.uploadAvatarButton.hidden = YES;
        [self setupFollowButton];

    } else {
        self.menuButton.hidden = NO;
        self.followButton.hidden = YES;
        self.uploadCoverButton.hidden = NO;
        self.uploadAvatarButton.hidden = NO;
    }
    
    self.totalFollowersButton.titleLabel. numberOfLines = 2; // Dynamic number of lines
    self.totalFollowersButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.totalFollowersButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    self.totalFollowingButton.titleLabel. numberOfLines = 2; // Dynamic number of lines
    self.totalFollowingButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.totalFollowingButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.totalFollowersButton setTitle:[NSString stringWithFormat:@"%lu\nFollowers", self.user.totalFollowers] forState:UIControlStateNormal];
    [self.totalFollowingButton setTitle:[NSString stringWithFormat:@"%lu\nFriends", self.user.totalFollowing] forState:UIControlStateNormal];

}

- (void)setupFollowButton {
    if(self.user.isFollowing) {
        [self.followButton setSelected:YES];
        self.followButton.backgroundColor = [UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1.0];
        self.followButton.layer.borderColor = [[UIColor whiteColor] CGColor];
        [self.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.followButton.layer.borderWidth = 1.0;
    } else {
        self.followButton.backgroundColor = [UIColor whiteColor];
        self.followButton.layer.borderColor = [[UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1.0] CGColor];
        [self.followButton setTitleColor:[UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        self.followButton.layer.borderWidth = 1.0;
        [self.followButton setSelected:NO];
    }
}

- (void)layoutSubviews {
    
//    [_progressView setCenter:self.coverPhotoImageView.center];

    [super layoutSubviews];
}

//- (void)setupProgressView {
//    [_progressView removeFromSuperview];
//    _progressView = [[DACircularProgressView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];
//    [_progressView setCenter:self.coverPhotoImageView.center];
//    _progressView.autoresizingMask = UIViewAutoresizingNone;
//    _progressView.roundedCorners = YES;
//    _progressView.backgroundColor = [UIColor clearColor];
//    [self addSubview:_progressView];
//}

- (void)loadUserImages {
    
//    [self setupProgressView];
    
    [self.avatarImageView sd_setImageWithURL:self.user.avatarUrl
                            placeholderImage:[UIImage imageNamed:@"default_avatar"]
                                   completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                       // nuthin yet
                                   }];
    
    __block BGViewProfileHeader *blockSelf = self;
        
    [self.coverPhotoImageView sd_setImageWithURL:self.user.coverPhotoURL placeholderImage:nil options:0
                                        progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        CGFloat progress = ((CGFloat)receivedSize / (CGFloat)expectedSize);
        dispatch_async(dispatch_get_main_queue(), ^{
            [blockSelf.progressView setProgress:progress animated:NO];
        });
    } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
       
        if(!image) {
            [blockSelf.uploadCoverButton setTitle:@"+ Upload a cover photo" forState:UIControlStateNormal];
        } else {
            [blockSelf.uploadCoverButton setTitle:@"" forState:UIControlStateNormal];
        }
        
        [blockSelf.progressView removeFromSuperview];
        blockSelf.progressView = nil;

    }];
//    [self.coverPhotoImageView sd_setImageWithURL:self.user.coverPhotoURL
//                            placeholderImage:nil
//                                   completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
//                                       // nuthin yet
//                                   }];
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
