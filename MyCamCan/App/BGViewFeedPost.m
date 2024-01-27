
/**
 *  BGViewFeedPostDetails.m
 *  MCC
 *  @author  James Ajhar
 *  @since 10/9/14.
 *  Copyright (c) 2014 D9. All rights reserved.
 */

#import "BGViewFeedPost.h"
#import "Media.h"
#import "AppData.h"
#import "BGViewLikeOverlay.h"
#import "MBProgressHUD.h"
#import "BGAlertViewDeleteMedia.h"
#import "BGControllerWebBrowser.h"
#import "VisualizerView.h"
#import <MessageUI/MessageUI.h>

@import Firebase;

static __weak BGViewFeedPost *_currentFullScreenView = nil;

@interface BGViewFeedPost() <UIActionSheetDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate>
{
    BOOL _gotDefaultSize;
    BOOL _isFullScreen;
    CGRect _defaultCaptionFrame;
    CGRect _defaultCreateTimeFrame;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mediaContainerViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *mediaImageView;
@property (weak, nonatomic) IBOutlet UIButton *avatarButton;
@property (weak, nonatomic) IBOutlet UIButton *likesCountButton;
@property (weak, nonatomic) IBOutlet UIView *detailsContainerView;
@property (weak, nonatomic) IBOutlet BGViewLikeOverlay *likesOverlayView;
@property (weak, nonatomic) IBOutlet UIView *mediaContainerView;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIButton *menuButton;
@property (weak, nonatomic) IBOutlet UIButton *captionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;

@property (strong, nonatomic) MBProgressHUD *loadingIndicator;
@property (strong, nonatomic) VisualizerView *visualizer;
@property (strong, nonatomic) UIActionSheet *actionSheet;

@property (nonatomic, assign) BOOL likeRequestInFlight;
@property (nonatomic) NSInteger likeRequestCounter;

@end


@implementation BGViewFeedPost


- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self.menuButton setImage:[[UIImage imageNamed:@"more"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.menuButton setTintColor:[UIColor whiteColor]];
    
//    self.layer.masksToBounds = NO;
//    self.layer.shadowOffset = CGSizeMake(-7, 7);
//    self.layer.shadowRadius = 5;
//    self.layer.shadowOpacity = 0.5;
    
    self.visualizer = [[VisualizerView alloc] initWithFrame:self.avatarButton.frame];
    self.visualizer.frame = self.mediaContainerView.frame;
    [_visualizer setBackgroundColor:[UIColor clearColor]];
    [_visualizer setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self.mediaContainerView insertSubview:_visualizer aboveSubview:self.mediaImageView];
    _visualizer.clipsToBounds = YES;
    _visualizer.center = self.avatarButton.center;
    _visualizer.userInteractionEnabled = NO;
    
    self.mediaContainerView.layer.borderColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5].CGColor;
    [self showBorder];
    
    _likeRequestInFlight = NO;
    _gotDefaultSize = NO;
    
    _likeRequestCounter = 0;
    
    self.avatarImageView.layer.cornerRadius = CGRectGetWidth(self.avatarImageView.frame) / 2.0;
    self.avatarButton.layer.cornerRadius = CGRectGetWidth(self.avatarButton.frame) / 2.0;
    
    _isFullScreen = NO;
    
    // notifications
    NSNotificationCenter *sharedNC = [NSNotificationCenter defaultCenter];
    
    [sharedNC addObserver:self
                 selector:@selector(notificationMediaUpdated:)
                     name:kAppData_Notification_MediaUpdated
                   object:nil];
    
    [sharedNC addObserver:self
                 selector:@selector(notificationUserUpdated:)
                     name:kAppData_Notification_UserUpdated
                   object:nil];
    
    self.captionLabel.titleLabel. numberOfLines = 0; // Dynamic number of lines
    self.captionLabel.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.captionLabel.titleLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _visualizer.center = self.mediaContainerView.center;
    
    [self.mediaContainerView bringSubviewToFront:self.detailsContainerView];
    [self.mediaContainerView bringSubviewToFront:self.captionLabel];
    [self bringSubviewToFront:self.menuButton];
}

- (void)showBorder {
    self.mediaContainerView.layer.borderWidth = 0.5;
}

- (void)hideBorder {
    self.mediaContainerView.layer.borderWidth = 0;
}

- (void)setMediaInfo:(Media *)mediaInfo displayFeedView:(BOOL)display showCompactHeader:(BOOL)compactHeader {
    _mediaInfo = mediaInfo;

//    self.menuButton.hidden = _mediaInfo.owner != [AppData sharedInstance].localUser;
    
    [self.mediaImageView sd_setImageWithURL:_mediaInfo.thumbUrl];
    
    if (self.mediaInfo.owner == [AppData sharedInstance].localUser) {
        self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel",@"Option for cancel the actionsheet")
                                         destructiveButtonTitle:NSLocalizedString(@"Delete",@"Option for delete media")
                                              otherButtonTitles:@"Edit", @"Share", nil];
    } else {
        self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel",@"Option for cancel the actionsheet")
                                         destructiveButtonTitle:NSLocalizedString(@"Report",@"Option for delete media")
                                              otherButtonTitles:@"Share", nil];
    }
    
    [self setAvatarImage];
    [self populateMediaInfo];
    [self setupLikesView];
    
    [self layoutIfNeeded];
}

- (void)populateMediaInfo {
    [self.likesCountButton setTitle:[NSString stringWithFormat:@"%lu", self.mediaInfo.totalLikes + _likeRequestCounter] forState:UIControlStateNormal];
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObject:[UIFont fontWithName:@"SFUIText-Heavy" size:30.0] forKey:NSFontAttributeName];
    [attributes setObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    [attributes setObject:@(-1.3f) forKey:NSKernAttributeName];

    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    shadow.shadowBlurRadius = 0.0;
    shadow.shadowOffset = CGSizeMake(0, 1);
    [attributes setObject:shadow forKey:NSShadowAttributeName];
    
    [self.captionLabel setTitle:@"" forState:UIControlStateNormal];
    [self.captionLabel setAttributedTitle:nil forState:UIControlStateNormal];
    
    if(self.mediaInfo.caption.length > 0) {
        
        if(self.mediaInfo.linkURL != nil) {
            [attributes setObject:@(NSUnderlineStyleSingle) forKey:NSUnderlineStyleAttributeName];
            [attributes setObject:[UIColor clearColor] forKey:NSBackgroundColorAttributeName];
        }
        
        NSAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\"%@\"", [self.mediaInfo.caption uppercaseString]]
                                                                                      attributes:attributes];
        [self.captionLabel setAttributedTitle:attributedString forState:UIControlStateNormal];
    
    } else if(self.mediaInfo.linkURL != nil) {
        [attributes setObject:@(NSUnderlineStyleSingle) forKey:NSUnderlineStyleAttributeName];
        [attributes setObject:[UIColor clearColor] forKey:NSBackgroundColorAttributeName];

        NSAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\"%@\"", [self.mediaInfo.linkURL.absoluteString uppercaseString]]
                                                                                      attributes:attributes];
        [self.captionLabel setAttributedTitle:attributedString forState:UIControlStateNormal];
    }
    else {
        [self.captionLabel setTitle:@"" forState:UIControlStateNormal];
        [self.captionLabel setAttributedTitle:nil forState:UIControlStateNormal];
    }
    
//    NSAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.mediaInfo.caption
//                                                                                  attributes:attributes];
//    [self.captionLabel setAttributedTitle:attributedString forState:UIControlStateNormal];

    if (self.mediaInfo.linkURL == nil) {
        self.captionLabel.enabled = NO;
    } else {
        self.captionLabel.enabled = YES;
    }
    
    if(_mediaInfo.isDeleting) {
        self.alpha = 0.5;
        
        [self showLoadingIndicator];
        
        self.userInteractionEnabled = NO;
        return;
    } else {
        self.alpha = 1.0;
        [self.loadingIndicator hide:NO];
        self.userInteractionEnabled = YES;
    }
}

- (void)setupLikesView {
    
    CGFloat birthRate = 0.0;
    CGFloat lifetime = 0.0;
    NSUInteger totalLikes = self.mediaInfo.totalLikes;
    
    if (totalLikes == 0 ) {
        [self.visualizer setupWithBirthRate:birthRate lifeTime:lifetime colorPallete:nil image:nil];
        [self.visualizer setHidden:YES];
        return;
    } else {
        [self.visualizer setHidden:NO];
    }
    
    UIColor *colorPallete = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
    UIImage *image;
    
    if(totalLikes > 0 && totalLikes <= 2) {
        birthRate = 3.0;
        lifetime = 2.0;
        image = [UIImage imageNamed:@"happy"];
        
    } else if (totalLikes > 2 && totalLikes <= 4) {
        birthRate = 3.0;
        lifetime = 2.0;
        image = [UIImage imageNamed:@"cool"];

    } else if (totalLikes > 4 && totalLikes <= 6) {
        birthRate = 3.0;
        lifetime = 2.0;
        image = [UIImage imageNamed:@"winkface"];

    } else if(totalLikes > 6 && totalLikes <= 8) {
        birthRate = 3.0;
        lifetime = 2.0;
        image = [UIImage imageNamed:@"big-laugh"];

    } else if(totalLikes > 8) {
        birthRate = 3.0;
        lifetime = 2.0;
        image = [UIImage imageNamed:@"heart"];
    }
    
    [self.visualizer setupWithBirthRate:birthRate lifeTime:lifetime colorPallete:colorPallete image:image];
    
//    [self.likesOverlayView setCurrentLikesCount:self.mediaInfo.totalLikes];
}

- (void)setAvatarImage {
    [self.avatarImageView sd_setImageWithURL:self.mediaInfo.owner.avatarUrl placeholderImage:[UIImage imageNamed:@"default_avatar"]];
}

- (CGFloat)heightOfViewWithMedia:(Media *)media showFeedDisplay:(BOOL)display {
    
    [self layoutSubviews];
    return CGRectGetMaxY(self.detailsContainerView.frame) + 25.0;
}

- (void)showLoadingIndicator {
    [self.loadingIndicator removeFromSuperview];
    self.loadingIndicator = [[MBProgressHUD alloc] initWithView:self.mediaContainerView];
    self.loadingIndicator.color = [UIColor clearColor];
    self.loadingIndicator.activityIndicatorColor = [UIColor lightGrayColor];
    self.loadingIndicator.opacity = 1.0f;
    [self.loadingIndicator removeFromSuperview];
    self.loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.mediaContainerView addSubview:self.loadingIndicator];
    [self.loadingIndicator show:YES];
}

#pragma mark Notifications

/**
 <p>
 * This method will be called via NSNotificationCenter whenever the media has been updated in some
 * way.
 *It will add , remove or refresh cell accordingly.
 */
- (void)notificationMediaUpdated:(NSNotification *)notification {
    /**
     kAppData_Notification_Element_Media
     */
    
    Media *updatedMedia = [[notification userInfo] objectForKey:kAppData_NotificationKey_Media];
    
    if(updatedMedia && [DataModelObject modelObject:_mediaInfo isEqualTo:updatedMedia]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self populateMediaInfo];
        });
    }
    
}

/**
 <p>
 * This method will be called via NSNotificationCenter whenever the media has been updated in some
 * way.
 *It will add , remove or refresh cell accordingly.
 */
- (void)notificationUserUpdated:(NSNotification *)notification {
    /**
     kAppData_Notification_Element_Media
     */
    
    User *updatedUser = [[notification userInfo] objectForKey:kAppData_NotificationKey_User];
    
    if(updatedUser && [DataModelObject modelObject:updatedUser isEqualTo:_mediaInfo.owner]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setAvatarImage];
        });
    }
    
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Interface Actions

- (IBAction)avatarPressed:(id)sender {
    
    if(!self.mediaInfo.owner){
        NSLog(@"WARNING: media owner is nil");
        return;
    }
    
    [[AppData sharedInstance].navigationManager presentControllerForPurpose:kBGPurposeProfile
                                                                       info:@{kVXKeyUser: self.mediaInfo.owner}
                                                                 showTabBar:YES];
}

- (IBAction)linkButtonPressed:(id)sender {
    if(self.mediaInfo.linkURL != nil) {
        
        [[AppData sharedInstance].navigationManager presentControllerForPurpose:kBGPurposeWebBrowser
                                                                           info:@{kBGKeyURL: self.mediaInfo.linkURL}
                                                                     showTabBar:NO];
    }
}

- (IBAction)usernameButtonPressed:(id)sender {
    [[AppData sharedInstance].navigationManager presentControllerForPurpose:kBGPurposeProfile info:@{kVXKeyUser: self.mediaInfo.owner} showTabBar:YES];
}

- (IBAction)viewAllLikesPressed:(id)sender {

    UIViewController *likesController = [[AppData sharedInstance].navigationManager presentControllerForPurpose:kBGPurposeLikes info:@{kVXKeyMedia: self.mediaInfo} showTabBar:YES pushImmediately: NO];
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [[AppData sharedInstance].navigationManager.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];

    [[AppData sharedInstance].navigationManager presentViewController:likesController animated:NO completion:nil];
}

- (IBAction)likeButtonPressed:(UIButton *)sender {
    
    _likeRequestCounter++;
//    [self.likesOverlayView addLikeAnimated:YES];

    [self.likesCountButton setTitle:[NSString stringWithFormat:@"%lu", self.mediaInfo.totalLikes + _likeRequestCounter] forState:UIControlStateNormal];

    [self likeMedia];
}

- (void)likeMedia {
    
    __block BGViewFeedPost *blockSelf = self;
    
    if(_likeRequestInFlight) {
        return;
    }
    
    self.likeRequestCounter--;
    
    _likeRequestInFlight = YES;
    
    [[AppData sharedInstance] likeMedia:self.mediaInfo
                               callback:^(id result, NSError *error) {
                                   
                                   blockSelf.likeRequestInFlight = NO;
                                   if(result && !error) {
                                       [blockSelf setupLikesView];
                                   } else {
//                                       [blockSelf.likesOverlayView removeLike];
                                   }
                                   
                                   if(self.likeRequestCounter > 0){
                                       [blockSelf likeMedia];
                                   }
                               }];

}

- (void)editPressed {
    [[AppData sharedInstance].navigationManager presentControllerForPurpose:kBGPurposePostEdit info:@{kVXKeyMedia: self.mediaInfo} showTabBar:NO];
}

- (void)sharePressed {
    
    __block BGViewFeedPost *blockSelf = self;
    
    [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] delegate] window] animated:NO];
    
    [Media addWaterMarkToVideo:self.mediaInfo.mediaUrl completion:^(NSURL *url, NSError *error) {
        [MBProgressHUD hideAllHUDsForView:[[[UIApplication sharedApplication] delegate] window] animated:NO];
        
        if(!error) {
            NSArray *itemsToShare = @[[NSString stringWithFormat:@"%@ - by %@ MyCamCan www.mycamcan.com", self.mediaInfo.caption, self.mediaInfo.owner.username], url];
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:[NSArray new]];
            activityVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList];
            
            activityVC.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
                if (completed) {
                    NSLog(@"The selected activity was %@", activityType);
                }
            };
            
            if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {
                // iOS8
                activityVC.popoverPresentationController.sourceView = blockSelf.menuButton;
            }
            
            [[AppData sharedInstance].navigationManager presentViewController:activityVC animated:YES completion:nil];
        }
    }];
}

- (void)prepareForReuse {
    [self.avatarImageView setImage:[UIImage imageNamed:@"default_avatar"]];
    [self.captionLabel setTitle:@"" forState:UIControlStateNormal];
    [self.captionLabel setAttributedTitle:nil forState:UIControlStateNormal];
}

#pragma mark BGZoomingViewControllerDelegate

/**
 * This method is called to set up the aspect ratio to show full image
 */
- (void)didEnterFullScreen {
    
    [FIRAnalytics logEventWithName:@"video_viewed"
                        parameters:@{
                                     @"user":[NSString stringWithFormat:@"USER_ID_%@", [AppData sharedInstance].localUser.theId],
                                     @"video_url": [self.mediaInfo.mediaUrl absoluteString],
                                     @"video_owner": self.mediaInfo.owner.theId
                                     }];
    
    _isFullScreen = YES;
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.backgroundView.alpha = 0.0;
                         self.visualizer.alpha = 0.0;
                     } completion:^(BOOL finished) {
                     }];
    
    self.mediaContainerViewHeightConstraint.constant = [UIScreen mainScreen].bounds.size.height;
    [self.mediaContainerView.leadingAnchor constraintEqualToAnchor:self.mediaContainerView.superview.leadingAnchor constant: 0.0].active = true;
    [self.mediaContainerView.trailingAnchor constraintEqualToAnchor:self.mediaContainerView.superview.trailingAnchor constant: 0.0].active = true;
    [self.mediaContainerView.topAnchor constraintEqualToAnchor:self.mediaContainerView.superview.topAnchor constant: 0.0].active = true;
    [self.mediaContainerView layoutIfNeeded];
    
    [self hideBorder];
    
    _currentFullScreenView = self;
    
//    [self bringSubviewToFront:self.mediaContainerView];
}

/**
 * This method is called to raise the movie slider
 */
- (void)interfaceShown {

}
/**
 * This method is called to lower the movie slider
 */
- (void)interfaceHidden {
}
/**
 * This method is called whenever the BGControllerMediaZoom controller finishes transforming via device rotation
 */
- (void)orientationDidChange:(UIDeviceOrientation)orientation {
  
}

- (IBAction)mediaButtonTapped:(id)sender {
    [self.delegate feedView:self mediaItemTapped:self.mediaInfo];
}

- (IBAction)menuButtonPressed:(id)sender {
    [self.actionSheet showInView:self];
}

#pragma mark - UIActionSheetDelegate
/**
 * This method is called to present action sheet to share, delete, edit media in feed page.
 */
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    if(actionSheet == self.actionSheet) {
        
        if (_mediaInfo.owner != [AppData sharedInstance].localUser) {
            
            switch (buttonIndex) {
                case 0:
                {
                    // report media
                    
                    // From within your active view controller
                    if([MFMailComposeViewController canSendMail]) {
                        MFMailComposeViewController *mailCont = [[MFMailComposeViewController alloc] init];
                        mailCont.mailComposeDelegate = self;
                        
                        [mailCont setSubject:@"Report Content"];
                        [mailCont setToRecipients:[NSArray arrayWithObject:@"mycamcan@gmail.com"]];
                        [mailCont setMessageBody:[NSString stringWithFormat:@"Media: %@\nUser: %@\n\nPlease give a brief description about why you are reporting this content.", self.mediaInfo.theId, self.mediaInfo.owner.username] isHTML:NO];
                        
                        [[AppData sharedInstance].navigationManager presentViewController:mailCont animated:YES completion:nil];
                    }
                    break;
                }
                case 1:
                {
                    [self sharePressed];
                    break;
                }
            }

            
        } else {
            
            switch (buttonIndex) {
                case 0:
                {
                    // delete media
                    [BGAlertViewDeleteMedia showDeletionPromptForMedia:self.mediaInfo
                                                            completion:^(id result, NSError *error) {
                                                                if(error) {
                                                                    [[[UIAlertView alloc] initWithTitle:@"Whoops!"
                                                                                                message:@"We were unable to delete that. Please try again."
                                                                                               delegate:self
                                                                                      cancelButtonTitle:@"Ok"
                                                                                      otherButtonTitles:nil] show];
                                                                }
                                                            }];
                    break;
                }
                case 1:
                    // edit media
                    [self editPressed];
                    break;
                case 2:
                    // Share media
                    [self sharePressed];
                    break;
            }

        }
        
    }
}

// Then implement the delegate method
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [[AppData sharedInstance].navigationManager dismissViewControllerAnimated:true completion:nil];
}


@end
