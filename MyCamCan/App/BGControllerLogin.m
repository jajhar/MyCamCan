//
//  ViewController.m
//  Blog
//
//  Created by James Ajhar on 5/29/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//

#import "BGControllerLogin.h"

#import "AppData.h"
#import "BGControllerRegister.h"
#import "MBProgressHUD.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@import Firebase;

NSString *kBGControllerLogin = @"BGControllerLogin";
NSString *kBGkeyUsername = @"BGKeyUsername";

@interface BGControllerLogin () <UITextFieldDelegate, BGControllerRegisterDelegate, FBSDKLoginButtonDelegate>
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet FBSDKLoginButton *facebookLoginButton;

@property (strong, nonatomic) NSString *prepopulatedUsername;
@end

@implementation BGControllerLogin

#pragma mark - Properties

@synthesize loginButton = _loginButton;
@synthesize usernameTextField = _usernameTextField;
@synthesize passwordTextField = _passwordTextField;

#pragma mark - Initialization


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.loginButton.layer.borderColor = [UIColor colorWithRed:217.0/255.0 green:51.0/255.0 blue:42.0/255.0 alpha:1].CGColor;
    self.loginButton.layer.borderWidth = 1.0;
    self.loginButton.layer.cornerRadius = 3.0;
    
    self.facebookLoginButton.readPermissions = @[@"public_profile", @"email"];
    self.facebookLoginButton.delegate = self;
    [self.facebookLoginButton setHidden:YES];
    
    self.usernameTextField.text = _prepopulatedUsername;
}

- (void)setInfo:(NSDictionary *)info animated:(BOOL)animated {
    [super setInfo:info animated:animated];
    
    if([info objectForKey:kBGkeyUsername]) {
        _prepopulatedUsername = [info objectForKey:kBGkeyUsername];
    }
}


#pragma mark - Routines


- (void)hideProgress {
	[MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void) displayLoginError:(NSError *)error {
	NSString *title = nil;
	NSString *message = nil;
	if (error == nil) {
		title = @"Login Failed";
		message = @"Please check login information";
	} else {
		if ([error.domain isEqualToString:kAppAPIErrorDomain]) {
			title = @"Conection error";
		}
		else if ([error.domain isEqualToString:kAppErrorDomain]) {
			title = @"Error";
		}
		message = error.localizedDescription;
	}
	
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
	[_usernameTextField becomeFirstResponder];
}


- (BOOL)allFieldsFilled {
	return ((_usernameTextField.text.length != 0) &&
			(_passwordTextField.text.length != 0));
}


#pragma mark - IB Actions

#pragma mark Button Actions

- (IBAction)loginPressed:(id)sender {
    [self supplyCredentialsAndSignIn];
}

- (IBAction)registerPressed:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LoginStoryboard" bundle:[NSBundle mainBundle]];
    BGControllerRegister *controller = [storyboard instantiateViewControllerWithIdentifier:@"BGControllerRegister"];
    controller.delegate = self;
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - Login

- (void)supplyCredentialsAndSignIn {
	[self.usernameTextField resignFirstResponder];
	[self.passwordTextField resignFirstResponder];
	
    NSString *username = [self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (([username length] != 0) && ([self.passwordTextField.text length] != 0)) {

        __weak BGControllerLogin *blockSelf = self;
        
        [[AppData sharedInstance] setLocalSessionWithEmail:username
                                                  password:self.passwordTextField.text];
        
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        [[AppData sharedInstance] loginWithEmail:username
                                        password:self.passwordTextField.text
                                     andCallback:^(id result, NSError *error) {
                                         [blockSelf completeSignInWithError:error];
                                     }];
    }
}


- (void)completeSignInWithError:(NSError *)error {
    [self hideProgress];
    if (error == nil) {
        
        [FIRAnalytics logEventWithName:@"signed_in"
                            parameters:@{
                                         @"user":[NSString stringWithFormat:@"USER_ID_%@", [AppData sharedInstance].localUser.theId],
                                         }];
        
        CATransition *transition = [CATransition animation];
        transition.duration = 0.3;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        [self.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];
        [[AppData sharedInstance].navigationManager setModalPresentationStyle: UIModalPresentationFullScreen];
        [self.navigationController presentViewController:[AppData sharedInstance].navigationManager animated:NO completion:nil];
        [[AppData sharedInstance].navigationManager setSelectedIndex:0];
        
    } else {
        [self displayLoginError:error];
    }
    //    [self hideSplashScreenIfNeededAfterDelay:0.0f];
}

#pragma mark - UITextFieldDelegate protocol


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if ([self allFieldsFilled]) {
		[self supplyCredentialsAndSignIn];
	}
	else {
		if (textField == _usernameTextField) {
			[_passwordTextField becomeFirstResponder];
		}
		else {
			[_usernameTextField becomeFirstResponder];
		}
	}
    [textField resignFirstResponder];
    return YES;
}

/**
 * This delegate is called when focus the text field should
 */
- (void)focusTextField:(UITextField *)textField {
//    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width, self.view.frame.size.height);
//    
    CGRect frame = textField.frame;
    frame.origin.y += 15.0;
    [self.scrollView scrollRectToVisible:frame animated:YES];
}
/**
 * This delegate is called that editing began for the specified text field.
 */
- (void)textFieldDidBeginEditing:(UITextField *)textField {
//    // have to focus textField at next runloop because keyboard may not be in position yet
    [self performSelectorOnMainThread:@selector(focusTextField:) withObject:textField waitUntilDone:NO];
}

#pragma mark - BGControllerRegisterDelegate

- (void)registrationFinished:(BGControllerRegister *)controller withUser:(User *)user {
    [self.navigationController popViewControllerAnimated:YES];
    self.usernameTextField.text = user.username;
}

#pragma mark - FBSDKLoginDelegate

- (void)loginButton:(FBSDKLoginButton *)loginButton didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error {
    
    if (error != nil) {
        NSLog(@"error: %@", error);
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Whoa!" message:@"Something went wrong! Please try again" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    if ([result isCancelled]) {
        return;
    }
    
    NSString *token = result.token.tokenString;
    
    [MBProgressHUD showHUDAddedTo:self.view animated:true];
    
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:@"id,email" forKey:@"fields"];
    
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:parameters];
    
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        
        [[[FBSDKLoginManager alloc] init] logOut];

        if (error || ![result isKindOfClass:[NSDictionary class]]) {
            [MBProgressHUD hideAllHUDsForView:self.view animated:true];

            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Whoa!" message:@"Something went wrong! Please try again" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];

            return;
        }
        
        NSString *email = [result objectForKey:@"email"];
        NSString *facebookID = [result objectForKey:@"id"];

        [[AppData sharedInstance] setLocalSessionWithEmail:email
                                                  password:token];

        [[AppData sharedInstance] loginWithFacebookToken:token
                                             andCallback:^(id result, NSError *error) {
                                                 
                                                 [MBProgressHUD hideAllHUDsForView:self.view animated:true];
                                                 
                                                 if (error != nil && error.code == 404) {
                                                     // user does not exist, register
                                                 
                                                     UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LoginStoryboard" bundle:[NSBundle mainBundle]];
                                                     BGControllerRegister *controller = [storyboard instantiateViewControllerWithIdentifier:@"BGControllerRegister"];
                                                     controller.delegate = self;
                                                     controller.email = email;
                                                     controller.avatarURLString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", facebookID];
                                                     [self.navigationController pushViewController:controller animated:YES];
                                                     
                                                 } else if (error != nil) {
                                                     
                                                     UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Whoa!" message:@"Something went wrong! Please try again" preferredStyle:UIAlertControllerStyleAlert];
                                                     [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
                                                     [self presentViewController:alert animated:YES completion:nil];

                                                 } else {
                                                     
                                                     [FIRAnalytics logEventWithName:@"signed_in"
                                                                         parameters:@{
                                                                                      @"user":[NSString stringWithFormat:@"USER_ID_%@", [AppData sharedInstance].localUser.theId],
                                                                                      }];

                                                     CATransition *transition = [CATransition animation];
                                                     transition.duration = 0.3;
                                                     transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                                                     transition.type = kCATransitionFade;
                                                     [self.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];
                                                     [self.navigationController presentViewController:[AppData sharedInstance].navigationManager animated:NO completion:nil];
                                                     [[AppData sharedInstance].navigationManager setSelectedIndex:0];

                                                 }
                                             }];
        
    }];
    
    
}

- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton {
    
}

@end
