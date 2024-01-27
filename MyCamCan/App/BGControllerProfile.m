//
//  ProfileViewController.m
//  Blog
//
//  Created by James Ajhar on 5/29/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//

#import "BGControllerProfile.h"
#import "BGViewProfileHeader.h"
#import "FeedPager.h"
#import "BGPostContentCell.h"
#import "MediaPlayerViewController.h"
#import "MBProgressHUD.h"
#import "BGControllerMediaPicker.h"
#import "Media.h"
#import "BGControllerImageCropper.h"
#import "Media_Uploads.h"
#import "UIImage+BGFixOrientation.h"
#import "ProfileMediaPager.h"

NSString *kBGControllerProfile = @"BGControllerProfile";


@interface BGControllerProfile () <UIActionSheetDelegate, BGImageCropperDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, BGViewFeedPostDelegate>
{
    BOOL isChangingAvatar;
    BOOL isChangingCover;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet BGViewProfileHeader *profileHeaderView;

@property (strong, nonatomic) ProfileMediaPager *feedPager;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) MBProgressHUD *progressHUD;
@property (strong, nonatomic) UIActionSheet *actionSheet;
@property (strong, nonatomic) UIActionSheet *settingsActionSheet;

@property (strong, nonatomic) User *user;

@end

@implementation BGControllerProfile

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.hidesBottomBarWhenPushed = NO;
    
    // camera/media picker action sheet
    self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel",@"Option for cancel the actionsheet")
                                     destructiveButtonTitle:NSLocalizedString(@"Photo Library",@"Option for presenting the photo library")
                                          otherButtonTitles:NSLocalizedString(@"Take Photo",@"Option for presenting the camera"), nil];
    
    // settings action sheet
    self.settingsActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel",@"Option for cancel the actionsheet")
                                             destructiveButtonTitle:NSLocalizedString(@"Log out",@"Option for delete media")
                                                  otherButtonTitles:nil];
    // settings action sheet
    self.settingsActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel",@"Option for cancel the actionsheet")
                                             destructiveButtonTitle:NSLocalizedString(@"Log out",@"Option for delete media")
                                                  otherButtonTitles:nil];
    
    // refresh control
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshView:) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl setTintColor:[UIColor whiteColor]];
    tableViewController.refreshControl = self.refreshControl;
    
    if(self.user == nil) {
        self.user = [AppData sharedInstance].localUser;
        [self setInfo:@{kVXKeyUser: self.user} animated:NO];
    }
    
    [self resizeHeaderView];
    
    if(self.user == [AppData sharedInstance].localUser) {
        // show settings button if this is the logged in user
        UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"options"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(settingsButtonPressed:)];
        [settingsButton setTintColor:[UIColor whiteColor]];
        
        self.navigationItem.rightBarButtonItem = settingsButton;
    } else {
        // show settings button if this is the logged in user
        UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"dropdown"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(optionsButtonPressed:)];
        [settingsButton setTintColor:[UIColor whiteColor]];
        
        self.navigationItem.rightBarButtonItem = settingsButton;

    }
    
    self.navigationItem.title = self.user.username;

    self.feedPager = self.user.profileMediaPager;
    
    UINib *nib = [UINib nibWithNibName:@"BGPostContentCell"
                                bundle:nil];
    // Register this Nib, which contains the cell
    [self.tableView registerNib:nib
         forCellReuseIdentifier:@"BGPostContentCell"];
    
    [self getProfileForceReload:YES];
    
    [self.profileHeaderView setupWithUser:_user ];
    
    // notifications
    NSNotificationCenter *sharedNC = [NSNotificationCenter defaultCenter];
    
    [sharedNC addObserver:self
                 selector:@selector(notificationFeedChanged:)
                     name:kAppData_Notification_ProfileMediaChanged
                   object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
//    [[BGControllerBase sharedInstance] setHeaderTitle:self.user.username];
    [self.tableView reloadData];
}

//- (void)viewDidLayoutSubviews
//{
//    [super viewDidLayoutSubviews];
//    CGRect rect = self.navigationController.navigationBar.frame;
//    float y = rect.size.height + rect.origin.y;
//    self.tableView.contentInset = UIEdgeInsetsMake(y ,0,0,0);
//}

/**
 * callback of the refresh control
 */
- (void)refreshView:(UIRefreshControl *)refresh {
    [self getProfileForceReload:YES];
    [self getFeedContentForceReload:YES];
}


#pragma mark Notifications


/**
 *<p>
 *  This method will be called via NSNotificationCenter whenever the list of feed media has changed in some way.
 *  It will add, remove, or refresh cells accordingly.
 */
- (void)notificationFeedChanged:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)blockButtonPressed {
    
    if ([[AppData sharedInstance].localUser.blockedUserIds containsObject:self.user.theId]) {
        // unblock
        [[AppData sharedInstance] unblockUser:self.user callback:^(id result, NSError *error) {
            if (error) {
                [[[UIAlertView alloc] initWithTitle:@"Uh Oh!"
                                            message:@"Something went wrong. Please try again."
                                           delegate:nil
                                  cancelButtonTitle:@"Ok"
                                  otherButtonTitles:nil] show];
            }
        }];
    } else {
        // block
        
        UIAlertController *alert =   [UIAlertController
                                      alertControllerWithTitle:@"Wait!"
                                      message:@"Are you sure you want to block this user?"
                                      preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* yes = [UIAlertAction
                              actionWithTitle:@"Yes"
                              style:UIAlertActionStyleDestructive
                              handler:^(UIAlertAction * action)
                              {
                                  [[AppData sharedInstance] blockUser:self.user callback:^(id result, NSError *error) {
                                      if (error) {
                                          [[[UIAlertView alloc] initWithTitle:@"Uh Oh!"
                                                                      message:@"Something went wrong. Please try again."
                                                                     delegate:nil
                                                            cancelButtonTitle:@"Ok"
                                                            otherButtonTitles:nil] show];
                                      }
                                  }];
                                  
                              }];
        
        [alert addAction:yes];
        UIAlertAction* no = [UIAlertAction
                             actionWithTitle:@"No"
                             style:UIAlertActionStyleDefault
                             handler:nil];
        [alert addAction:no];
        
        [[AppData sharedInstance].navigationManager presentViewController:alert animated:YES completion:nil];
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
}

- (void)setUser:(User *)user {
    _user = user;
}

- (void)getProfileForceReload:(BOOL)forceReload {
    [[AppData sharedInstance] getProfileForUser:_user
                                       callback:^(id result, NSError *error) {
                                           // process error
                                       }];
}

- (void)getFeedContentForceReload:(BOOL)forceReload {
    PagerCompletionBlock completionBlock = ^(NSError *error) {
        // hide all spinners
        [self.refreshControl endRefreshing];
        
        if(error) {
            // process error
        }
    };
    
    if (forceReload) {
        [_feedPager reloadWithCompletion:completionBlock];
    } else {
        [_feedPager getNextPageWithCompletion:completionBlock];
    }
}

- (void)resizeHeaderView {
    CGRect frame = self.profileHeaderView.frame;
    
    if(self.user == [AppData sharedInstance].localUser) {
        frame.size.height = 135.0;
    } else {
        frame.size.height = 175.0;
    }
    
    self.profileHeaderView.frame = frame;
    [self.tableView setTableHeaderView:self.profileHeaderView];
}

#pragma mark - Interface Actions

- (void)settingsButtonPressed:(id)sender {
    [self.settingsActionSheet showInView:self.view];
}

- (void)optionsButtonPressed:(id)sender {
    
    UIAlertController *alert =   [UIAlertController
                                  alertControllerWithTitle:@"Options"
                                  message:nil
                                  preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([[AppData sharedInstance].localUser.blockedUserIds containsObject:self.user.theId]) {
        // unblock
        UIAlertAction* unblock = [UIAlertAction
                                       actionWithTitle:[NSString stringWithFormat:@"Unblock %@", self.user.username]
                                       style:UIAlertActionStyleDestructive
                                       handler:^(UIAlertAction * action)
                                       {
                                           [self blockButtonPressed];
                                       }];
        [alert addAction:unblock];

    } else {
        // block
        UIAlertAction* block = [UIAlertAction
                                       actionWithTitle:[NSString stringWithFormat:@"Block %@", self.user.username]
                                       style:UIAlertActionStyleDestructive
                                       handler:^(UIAlertAction * action)
                                       {
                                           [self blockButtonPressed];
                                       }];
        [alert addAction:block];
    }
    
    UIAlertAction* cancel = [UIAlertAction
                            actionWithTitle:@"Cancel"
                            style:UIAlertActionStyleCancel
                            handler:nil];
    [alert addAction:cancel];

    [[AppData sharedInstance].navigationManager presentViewController:alert animated:YES completion:nil];
}

- (IBAction)uploadAvatarPressed:(id)sender {
    isChangingAvatar = YES;
    isChangingCover = NO;
    
    [self.actionSheet showInView:self.view];
}

#pragma mark - UITableViewDataSource, UITableViewDelegate


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_feedPager.isEndOfPages) {
        return [_feedPager elementsCount];
    } else {
        return [_feedPager elementsCount] + 1;  // last cell - refreshing spinner. When scrolled to, it will trigger a fetch of the next page
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [_feedPager elementsCount]) {
        // refreshing cell
        return 75.0;
    }
    
    return 320.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [_feedPager elementsCount]) {
        // refresh cell
        UITableViewCell *cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:@"TableLoadingCell"];
        
        // MBProgressHUD
        [_progressHUD removeFromSuperview];
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        _progressHUD.color = [UIColor clearColor];
        _progressHUD.activityIndicatorColor = [UIColor whiteColor];
        _progressHUD.opacity = 1.0f;
        [cell.contentView addSubview:_progressHUD];
        [_progressHUD show:YES];
        
        // when this cell gets shown to user, we start loading new portion of feed data
        [self getFeedContentForceReload:NO];
        
        return cell;
    } else {
        // feed cell
        BGPostContentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BGPostContentCell"];
        cell.feedView.delegate = self;
        [cell setMediaInfo:[_feedPager elementAtIndex:indexPath.row]];
        return cell;
    }
}

- (void)feedView:(id)view mediaItemTapped:(Media *)media {
    
    UINib *mediaPlayerNib = [UINib nibWithNibName:@"MediaPlayerViewController" bundle:nil];
    MediaPlayerViewController *mediaPlayerController = [mediaPlayerNib instantiateWithOwner:self options:nil].firstObject;
    
    [mediaPlayerController setMediaInfo:media];
    
    [mediaPlayerController setModalPresentationStyle:UIModalPresentationCustom];
    [mediaPlayerController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];

    [self presentViewController:mediaPlayerController animated:YES completion:nil];
}

#pragma mark - Actions



#pragma mark BGController

- (void)setInfo:(NSDictionary *)info animated:(BOOL)animated {
    [super setInfo:info animated:animated];
    
    if([info objectForKey:kVXKeyUser] != nil) {
        self.user = [info objectForKey:kVXKeyUser];
    } else {
        self.user = [AppData sharedInstance].localUser;
    }
    
}

- (void)beginUploadingImage:(UIImage *)croppedImage {
    // begin uploading
    
    NSData *imageData = UIImagePNGRepresentation(croppedImage);
    
    NSString *directory = NSTemporaryDirectory();
    
    NSString *imagePath =[directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",@"cached"]];
    
    NSLog(@"pre writing to file");
    if (![imageData writeToFile:imagePath atomically:NO])
    {
        NSLog(@"Failed to cache image data to disk");
        
        [[[UIAlertView alloc] initWithTitle:@"Uh oh!"
                                    message:@"Something went wrong. Please try again"
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
        return;
    }
    
    NSLog(@"the cachedImagedPath is %@",imagePath);
    
    Media *media = [Media mediaWithImage:croppedImage];
    [media generateUploadFileName];
    
    if(isChangingAvatar) {
        [[AppData sharedInstance] updateAvatarWithPhoto:[NSURL fileURLWithPath:imagePath]
                                           withFileName:media.uploadFileName
                                               callback:^(id result, NSError *error) {
                                                   if(error) {
                                                       [[[UIAlertView alloc] initWithTitle:@"Uh oh!"
                                                                                   message:@"Something went wrong. Please try again"
                                                                                  delegate:nil
                                                                         cancelButtonTitle:@"Ok"
                                                                         otherButtonTitles:nil] show];
                                                   }
                                               }];
    } else if(isChangingCover) {
        [[AppData sharedInstance] updateCoverWithPhoto:[NSURL fileURLWithPath:imagePath]
                                          withFileName:media.uploadFileName
                                              callback:^(id result, NSError *error) {
                                                  if(error) {
                                                      [[[UIAlertView alloc] initWithTitle:@"Uh oh!"
                                                                                  message:@"Something went wrong. Please try again"
                                                                                 delegate:nil
                                                                        cancelButtonTitle:@"Ok"
                                                                        otherButtonTitles:nil] show];
                                                  }
                                              }];
    }

    isChangingCover = NO;
    isChangingAvatar = NO;
}


#pragma mark - BGImageCropperDelegate

- (void)didFinishCroppingImage:(UIImage *)croppedImage {
    [self beginUploadingImage:croppedImage];
}


#pragma Picker Delegates

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    if(image) {
        [[AppData sharedInstance].navigationManager presentControllerForPurpose:kBGPurposeImageCropper info:@{kVXKeyMedia: image,
                                                                                                              kBGKeyImagePickerDelegate: self} showTabBar:NO];
    }

}

#pragma mark - UIActionSheetDelegate


/**
 * This method handles camera/library presentation.
 */
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if(actionSheet == self.actionSheet) {
        // camera action sheet
        
        switch (buttonIndex) {
            case 0:
            {
                ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
                
                if (status != ALAuthorizationStatusNotDetermined && status != ALAuthorizationStatusAuthorized) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Camera roll access denied!",@"Camera roll access disabled ") message:NSLocalizedString(@"Please enable camera Roll access! Go to Setting -> Privacy -> Camera roll to allow access.",@"Message displays steps to enable camera roll access") delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok",@"Option for cancel the alert message") otherButtonTitles:nil, nil];
                    [alert show];
                    return;
                }
                
                // Camera-Roll
                
                [[AppData sharedInstance].navigationManager presentMediaPickerWithAllowedMediaTypes:kBGAllowedTypesPhoto
                                                                                      usingDelegate:self];
                break;
            }
            case 1:
                // Camera
                [[AppData sharedInstance].navigationManager presentCameraWithCaptureMode:UIImagePickerControllerCameraCaptureModePhoto
                                                                       allowedMediaTypes:kBGAllowedTypesPhoto
                                                                                delegate:self];
                break;
            case 2:
                // Cancel
                break;
                
        }
    } else if(actionSheet == self.settingsActionSheet) {
        
        switch (buttonIndex) {
            case 0:
                // logout
                [[AppData sharedInstance] clearLocalSession];
                [[AppData sharedInstance].navigationManager presentControllerForPurpose:kBGPurposeLogin info:nil showTabBar:YES];
                [[AppData sharedInstance] resetNavigationManager];
                break;
        }
    }
}


@end
