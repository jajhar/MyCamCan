//
//  MediaPlayerViewController.m
//  Blog
//
//  Created by James Ajhar on 4/16/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

#import "MediaPlayerViewController.h"
#import "MediaPlayerView.h"
#import "Media.h"
#import "MBProgressHUD.h"
#import "AppData.h"
#import "BGControllerLikes.h"

@interface MediaPlayerViewController () <BGMediaPlayerViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet MediaPlayerView *mediaPlayerView;
@property (weak, nonatomic) IBOutlet UIButton *likesCountButton;
@property (weak, nonatomic) IBOutlet UIButton *avatarButton;
@property (weak, nonatomic) IBOutlet UIButton *captionLabel;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIView *postDetailsView;

@property (nonatomic, assign) BOOL likeRequestInFlight;
@property (nonatomic) NSInteger likeRequestCounter;

@property (nonatomic, strong) Media *media;

@end

@implementation MediaPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
 
    self.doneButton.layer.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5].CGColor;
    self.doneButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.doneButton.layer.cornerRadius = 8.0f;
    self.doneButton.layer.borderWidth = 1.0f;
    
    self.shareButton.layer.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5].CGColor;
    self.shareButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.shareButton.layer.cornerRadius = 8.0f;
    self.shareButton.layer.borderWidth = 1.0f;
    
    self.avatarButton.layer.cornerRadius = CGRectGetWidth(self.avatarButton.frame) / 2.0;
    self.avatarButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarButton.contentMode = UIViewContentModeScaleAspectFill;
    
    self.captionLabel.titleLabel. numberOfLines = 0; // Dynamic number of lines
    self.captionLabel.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.captionLabel.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    self.mediaPlayerView.delegate = self;
}

- (void)setMediaInfo:(Media *)media {
    self.media = media;
    
    [self.mediaPlayerView setMedia:media];
    
    [self populateMediaInfo];
}

- (void)toggleInterface:(BOOL)show {
    
    CGFloat alpha = show ? 1.0 : 0.0;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.captionLabel.alpha = alpha;
        self.doneButton.alpha = alpha;
        self.shareButton.alpha = alpha;
        self.postDetailsView.alpha = alpha;
    }];
}

- (IBAction)donePressed:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)sharePressed:(id)sender {
    
    self.shareButton.enabled = NO;
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    __block MediaPlayerViewController *blockSelf = self;
    
    [Media addWaterMarkToVideo:self.media.mediaUrl completion:^(NSURL *url, NSError *error) {
        
        self.shareButton.enabled = YES;
        [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
        
        if(!error) {
            NSArray *itemsToShare = @[[NSString stringWithFormat:@"%@ - by %@ MyCamCan www.mycamcan.com", self.media.caption, self.media.owner.username], url];
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:[NSArray new]];
            activityVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList];
            
            activityVC.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
                if (completed) {
                    NSLog(@"The selected activity was %@", activityType);
                }
            };
            
            if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {
                // iOS8
                activityVC.popoverPresentationController.sourceView = blockSelf.shareButton;
            }
            
            [self presentViewController:activityVC animated:YES completion:nil];
            
        } else {
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Uh Oh!" message:@"We were unable to share this. Please try again." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:action];
            
            [self presentViewController:alertController animated:YES completion:nil];
            
        }
    }];
    
}

- (IBAction)avatarPressed:(id)sender {
    
    [[AppData sharedInstance].navigationManager presentControllerForPurpose:kBGPurposeProfile info:@{kVXKeyUser: self.media.owner} showTabBar:YES];

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)likeButtonPressed:(id)sender {
    _likeRequestCounter++;
    //    [self.likesOverlayView addLikeAnimated:YES];
    
    [self.likesCountButton setTitle:[NSString stringWithFormat:@"%lu", self.media.totalLikes + _likeRequestCounter] forState:UIControlStateNormal];
    
    [self likeMedia];
}

- (void)likeMedia {
    
    __block MediaPlayerViewController *blockSelf = self;
    
    if(_likeRequestInFlight) {
        return;
    }
    
    self.likeRequestCounter--;
    
    _likeRequestInFlight = YES;
    
    [[AppData sharedInstance] likeMedia:self.media
                               callback:^(id result, NSError *error) {
                                   
                                   blockSelf.likeRequestInFlight = NO;
                                   
                                   if(self.likeRequestCounter > 0){
                                       [blockSelf likeMedia];
                                   }
                               }];
}

- (IBAction)likeCountPressed:(id)sender {
    
    BGControllerLikes *controller = (BGControllerLikes *)[[AppData sharedInstance].navigationManager controllerForPurpose:kBGPurposeLikes];
    [controller setInfo:@{kVXKeyMedia: self.media} animated:YES];
    
    [controller setModalPresentationStyle:UIModalPresentationCustom];
    [controller setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];

    [self presentViewController:controller animated:YES completion:nil];
}

- (void)setAvatarImage {
    
    __block MediaPlayerViewController *blockSelf = self;
    
    [blockSelf.avatarButton setImage:[UIImage imageNamed:@"default_avatar"] forState:UIControlStateNormal];
    
    SDWebImageDownloader *manager = [SDWebImageDownloader sharedDownloader];
    
    [manager downloadImageWithURL:self.media.owner.avatarUrl
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

- (void)populateMediaInfo {
    
    [self setAvatarImage];
    
    [self.likesCountButton setTitle:[NSString stringWithFormat:@"%lu", self.media.totalLikes + _likeRequestCounter] forState:UIControlStateNormal];
    
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
    
    if(self.media.caption.length > 0) {
        
        if(self.media.linkURL != nil) {
            [attributes setObject:@(NSUnderlineStyleSingle) forKey:NSUnderlineStyleAttributeName];
            [attributes setObject:[UIColor clearColor] forKey:NSBackgroundColorAttributeName];
        }
        
        NSAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\"%@\"", [self.media.caption uppercaseString]]
                                                                                      attributes:attributes];
        [self.captionLabel setAttributedTitle:attributedString forState:UIControlStateNormal];
        
    } else if(self.media.linkURL != nil) {
       
        [attributes setObject:@(NSUnderlineStyleSingle) forKey:NSUnderlineStyleAttributeName];
        [attributes setObject:[UIColor clearColor] forKey:NSBackgroundColorAttributeName];
        
        NSAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\"%@\"", [self.media.linkURL.absoluteString uppercaseString]]
                                                                                      attributes:attributes];
        [self.captionLabel setAttributedTitle:attributedString forState:UIControlStateNormal];
    
    } else {
        
        [self.captionLabel setTitle:@"" forState:UIControlStateNormal];
        [self.captionLabel setAttributedTitle:nil forState:UIControlStateNormal];
    }
}

- (void)mediaPlayerDidBeginPlaying:(MediaPlayerView *)mediaPlayer {
    [self toggleInterface:NO];
}
/**
 * This method is called action to when media player is pause
 */
- (void)mediaPlayerDidPause:(MediaPlayerView *)mediaPlayer {
    [self toggleInterface:YES];
}

/**
 * This method is called action to when player is resume
 */
- (void)mediaPlayerDidResumePlaying:(MediaPlayerView *)mediaPlayer {
    [self toggleInterface:NO];
}

/**
 * This method is called action to when player is stop
 */
- (void)mediaPlayerDidStopPlaying:(MediaPlayerView *)mediaPlayer {
    [self toggleInterface:YES];
}


@end
