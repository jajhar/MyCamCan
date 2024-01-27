//
//  BGControllerPostEdit.m
//  Blog
//
//  Created by James Ajhar on 1/21/16.
//  Copyright © 2016 James Ajhar. All rights reserved.
//

#import "BGControllerPostEdit.h"
#import "MBProgressHUD.h"
#import "Media.h"
#import "WindowHitTest.h"
#import "UIPlaceHolderTextView.h"
#import <Social/Social.h>
#import "SocialVideoHelper.h"

@import Accounts;


typedef void(^FacebookAccessCompletionHandler)(BOOL granted, NSError *error, ACAccount *account);


@interface BGControllerPostEdit () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *postImageView;
@property (weak, nonatomic) IBOutlet UILabel *characterCountLabel;
@property (weak, nonatomic) IBOutlet UIPlaceHolderTextView *captionTextView;
@property (weak, nonatomic) IBOutlet UITextField *linkField;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;
@property (weak, nonatomic) IBOutlet UIStackView *facebookStackView;
@property (weak, nonatomic) IBOutlet UISwitch *facebookSwitch;

@property (strong, nonatomic) Media *media;
@property (strong, nonatomic) ACAccount *facebookAccount;

@end

@implementation BGControllerPostEdit


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.captionTextView.delegate = self;
    
    if([AppData sharedInstance].navigationManager.selectedIndex != 2) {
        // not camera tab
        self.skipButton.hidden = YES;
    }
    
    // add save button to nav bar
    UIButton *saveButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    [saveButton setTitle:@"save" forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(savePressed:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:saveButton];
    
    if (self.media.localFileURL != nil) {
        self.facebookStackView.hidden = NO;
        [self.facebookSwitch setOn:NO];
    } else {
        self.facebookStackView.hidden = YES;
    }
    
    // Notifications
    NSNotificationCenter *sharedNC = [NSNotificationCenter defaultCenter];
    
    [sharedNC addObserver:self
                 selector:@selector(notificationWindowHitTest:)
                     name:kBGNotificationWindowTapped
                   object:nil];

    [self.postImageView sd_setImageWithURL:self.media.thumbUrl];
    
    self.captionTextView.text = self.media.caption;
    self.captionTextView.placeholder = @"Write a Headline";
    self.captionTextView.placeholderColor = [UIColor lightGrayColor];
    self.linkField.text = self.media.linkURL.absoluteString;
    
    self.characterCountLabel.text = [NSString stringWithFormat:@"%lu", 40 - self.captionTextView.text.length];

    self.navigationItem.title = @"Edit";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
        
    [self.captionTextView becomeFirstResponder];
}

- (void)setInfo:(NSDictionary *)info animated:(BOOL)animated {
    [super setInfo:info animated:animated];
    
    if([info objectForKey:kVXKeyMedia] != nil) {
        self.media = [info objectForKey:kVXKeyMedia];
    } else {
        NSLog(@"Warning: Attempting to initialize Post Edit Controller with a nil media object");
    }
}

#pragma mark - Interface Actions


- (void)shareToFacebook:(ACAccount *)account {
    
    __block BGControllerPostEdit *blockSelf = self;
    
    [Media addWaterMarkToVideo:self.media.localFileURL completion:^(NSURL *url, NSError *error) {
        if(!error) {
            
            [self requestFacebookAccess:^(BOOL granted, NSError *error, ACAccount *fbaccount) {
                if (!error) {
                    
                    NSLog(@"account: %@", [AppData sharedInstance].facebookAccount);
                    
                    NSData *videoData = [NSData dataWithContentsOfURL:url];
                    
                    if (videoData == nil) {
                        NSLog(@"ERROR: Video Data is nil");
                        return;
                    }
                    
//                    NSString *caption = [NSString stringWithFormat:@"%@ - by %@ #MyCamCan www.mycamcan.com", blockSelf.media.caption];
                    
                    [SocialVideoHelper uploadFacebookVideo:videoData
                                                   comment:blockSelf.media.caption
                                                   account:fbaccount
                                            withCompletion:^(BOOL success, NSString *errorMessage) {
                                                NSLog(@"Uploaded: %@", errorMessage);
                                            }];
                }
            }];
            
            
        } else {
            NSLog(@"ERROR: %@", error);
        }
    }];

}

- (IBAction)skipPressed:(id)sender {
    if([AppData sharedInstance].navigationManager.selectedIndex == 2) {
        // camera tab
        [self.navigationController popToRootViewControllerAnimated:NO];
        [[AppData sharedInstance].navigationManager setSelectedIndex:0];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)savePressed:(id)sender {
    
    __block BGControllerPostEdit *blockSelf = self;
    
    if (self.facebookSwitch.on) {
        [self requestFacebookAccess:^(BOOL granted, NSError *error, ACAccount *account) {
            [AppData sharedInstance].facebookAccount = account;
            if (!error) {
                [blockSelf shareToFacebook:account];
            }
        }];
    }
    
    self.media.caption = self.captionTextView.text;
    
    NSString *urlText = self.linkField.text;
    
    if(urlText.length > 0) {
        if ([[urlText lowercaseString] hasPrefix:@"http://"] ||
            [[urlText lowercaseString] hasPrefix:@"https://"]) {
            self.media.linkURL = [NSURL URLWithString:self.linkField.text];
        } else {
            self.media.linkURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", urlText]];
        }
    }
        
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[AppData sharedInstance] updateMedia:self.media
                                 callback:^(id result, NSError *error) {
                                     
                                     [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                                     
                                     if (error) {
                                         UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Uh oh!" message:@"Something went wrong! Please try again." preferredStyle:UIAlertControllerStyleAlert];
                                         
                                         UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                                         [alertController addAction:ok];
                                         
                                         [self presentViewController:alertController animated:YES completion:nil];
                                     } else {
                                         
                                         if([AppData sharedInstance].navigationManager.selectedIndex == 2) {
                                             // camera tab
                                             [blockSelf.navigationController popToRootViewControllerAnimated:NO];
                                             [[AppData sharedInstance].navigationManager setSelectedIndex:0];
                                         } else {
                                             [blockSelf.navigationController popViewControllerAnimated:YES];
                                         }
                                     }
                                     
                                 }];
}

#pragma mark Notifications


- (void)notificationWindowHitTest:(NSNotification *)notification {
    UIView *touchedView = [notification object];
    
    if ([self.captionTextView isFirstResponder] && touchedView != self.captionTextView) {
        [self.captionTextView resignFirstResponder];
    }
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    self.characterCountLabel.text = [NSString stringWithFormat:@"%lu", 40 - self.captionTextView.text.length];

    if (((textView.text.length + text.length) > 65) && (text.length > 0)) {
        return false;
    }
    
    return true;
}

- (IBAction)facebookSwitchFlipped:(UISwitch *)sender {
    if (sender.on) {
        [self requestFacebookAccess:^(BOOL granted, NSError *error, ACAccount *account) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Uh Oh!" message:@"Facebook was unable to grant us access to post on your behalf! Please check your Facebook permissions under Settings->Facebook." preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                    
                    [self presentViewController:alert animated:YES completion:nil];
                });
            }
        }];
    }
}

- (void)requestFacebookAccess:(FacebookAccessCompletionHandler)completion {
    
    [self requestFacebookReadAccess:^(BOOL granted, NSError *error, ACAccount *account) {
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        
        NSDictionary *publishWritePermisson = @{
                                                ACFacebookAppIdKey : @"1746151452289766",
                                                ACFacebookPermissionsKey : @[@"publish_actions"],
                                                ACFacebookAudienceKey : ACFacebookAudienceFriends
                                                };
        
        ACAccountType *facebookAccountType = [accountStore
                                              accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
        
        //Request for write permission
        [accountStore requestAccessToAccountsWithType:facebookAccountType options:publishWritePermisson completion:^(BOOL granted, NSError *error) {
            
            if (granted) {
                
                NSLog(@"Access to Facebook granted!");
                
                NSArray *accounts = [accountStore
                                     accountsWithAccountType:facebookAccountType];
                self.facebookAccount = [accounts lastObject];
                NSLog(@"Successfull access for account: %@", self.facebookAccount.username);
                
                if (completion != nil) {
                    completion(granted, error, [accounts lastObject]);
                }
            }
            else
            {
                NSLog(@"Access to Facebook is not granted");
                
                // Fail gracefully...
                NSLog(@"ERROR: %@",error);
                
                if (completion != nil) {
                    completion(granted, error, nil);
                }
            }
            
        }];
    }];
    
}

- (void)requestFacebookReadAccess:(FacebookAccessCompletionHandler)completion {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    
    NSDictionary *publishWritePermisson = @{
                                            ACFacebookAppIdKey : @"1746151452289766",
                                            ACFacebookPermissionsKey : @[@"email"],
                                            ACFacebookAudienceKey : ACFacebookAudienceFriends
                                            };
    
    ACAccountType *facebookAccountType = [accountStore
                                          accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    
    //Request for write permission
    [accountStore requestAccessToAccountsWithType:facebookAccountType options:publishWritePermisson completion:^(BOOL granted, NSError *error) {
        
        if (granted) {
            
            NSLog(@"Access to Facebook granted!");
            
            NSArray *accounts = [accountStore
                                 accountsWithAccountType:facebookAccountType];
            self.facebookAccount = [accounts lastObject];
            NSLog(@"Successfull access for account: %@", self.facebookAccount.username);
            
            if (completion != nil) {
                completion(granted, error, [accounts lastObject]);
            }
        }
        else
        {
            NSLog(@"Access to Facebook is not granted");
            
            // Fail gracefully...
            NSLog(@"ERROR: %@",error);
            
            if (completion != nil) {
                completion(granted, error, nil);
            }
        }
        
    }];
}

@end
