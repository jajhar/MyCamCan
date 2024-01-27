//
//  RegisterViewController.m
//  Blog
//
//  Created by James Ajhar on 6/2/14.
//  Copyright (c) 2014 James Ajhar. All rights reserved.
//

#import "BGControllerRegister.h"

#import "User.h"
#import "BGControllerLogin.h"
#import "MBProgressHUD.h"
#import "BGControllerWebBrowser.h"
#import "Media.h"
#import "Media_Uploads.h"

@import Firebase;

NSString *kBGControllerRegister = @"BGControllerRegister";


@interface BGControllerRegister () <UITextViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (strong, nonatomic) IBOutlet UITextField *phoneField;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *tosButton;
@property (weak, nonatomic) IBOutlet UITextView *tosTextView;
@property (weak, nonatomic) IBOutlet UITextField *emailField;

@property (strong, nonatomic) MBProgressHUD *progressHUD;
@property (strong, nonatomic) NSString *prepopulatedUsername;


- (IBAction)confirmRegisterPressed:(id)sender;

@end

@implementation BGControllerRegister


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
        
    self.usernameField.text = _prepopulatedUsername;
    
    NSMutableDictionary *titleAttributes = [NSMutableDictionary new];
    [titleAttributes setObject:[UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular] forKey:NSFontAttributeName];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"Tap to agree to our " attributes:titleAttributes];
    
    
    NSAttributedString *attributedTOS = [[NSMutableAttributedString alloc] initWithString:@"Terms of Service"
                                                                                      attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12 weight:UIFontWeightRegular],
                                                                                                   NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                                                                                                   NSBackgroundColorAttributeName: [UIColor clearColor],
                                                                                                   @"isTOS": @(YES)}];
    
    [attributedString appendAttributedString:attributedTOS];
    
    self.tosTextView.attributedText = attributedString;
    
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textViewTapped:)];
    [self.tosTextView addGestureRecognizer:recognizer];

    self.emailField.text = self.email;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setInfo:(NSDictionary *)info animated:(BOOL)animated {
    [super setInfo:info animated:animated];
    
    if([info objectForKey:kBGkeyUsername]) {
        _prepopulatedUsername = [info objectForKey:kBGkeyUsername];
    }
}

- (IBAction)tosButtonPressed:(UIButton *)sender {
    [sender setSelected:!sender.selected];
}

- (void)textViewTapped:(UITapGestureRecognizer *)recognizer {
    UITextView *textView = (UITextView *)recognizer.view;

    // Location of the tap in text-container coordinates
    NSLayoutManager *layoutManager = textView.layoutManager;
    CGPoint location = [recognizer locationInView:textView];
    location.x -= textView.textContainerInset.left;
    location.y -= textView.textContainerInset.top;

    // Find the character that's been tapped on

    NSUInteger characterIndex;
    characterIndex = [layoutManager characterIndexForPoint:location
                                           inTextContainer:textView.textContainer
                  fractionOfDistanceBetweenInsertionPoints:NULL];

    if (characterIndex < textView.textStorage.length) {
        NSRange range;
        NSDictionary *attributes = [textView.textStorage attributesAtIndex:characterIndex effectiveRange:&range];

        if([[attributes objectForKey:@"isTOS"] boolValue]){       // if this is the tos link

            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"BlogStoryboard" bundle:[NSBundle mainBundle]];
            BGControllerWebBrowser *controller = [storyboard instantiateViewControllerWithIdentifier:@"BGControllerWebBrowser"];
            controller.startURL = [NSURL URLWithString:@"http://www.mycamcan.com/tos.html"];
            [self.navigationController pushViewController:controller animated:YES];

        }
    }
}

#pragma mark - Internal


- (BOOL)allFieldsFilled {
    return (
            (![self.usernameField.text isEqualToString:@""] && !(self.usernameField.text == nil)) &&
            (![self.passwordField.text isEqualToString:@""] && !(self.passwordField.text == nil)) &&
            (![self.phoneField.text isEqualToString:@""] && !(self.phoneField.text == nil)) &&
            (![self.emailField.text isEqualToString:@""] && !(self.emailField.text == nil))
           );
}

- (void)resignKeyboard {
    [self.usernameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    [self.phoneField resignFirstResponder];
    [self.emailField resignFirstResponder];

}


#pragma mark - Actions


- (IBAction)confirmRegisterPressed:(id)sender {
    [self commitData];
}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
//    [[BGControllerBase sharedInstance] presentControllerForPurpose:kBGPurposeLogin
//                                                          animated:YES
//                                                         fromRight:YES
//                                                              info:nil];
    
}

#pragma mark - Register


- (void)commitData {
    [self resignKeyboard];
    
    if(!self.tosButton.selected) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You must accept our terms of service before continuing." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
        return;

    }
    
    // trim whitespace from username text field
    NSString *username = [self.usernameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([username length] < 3) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Name must be at least 3 characters" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
        return;
    }
    if ([[self.passwordField text] length] < 6) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Password must be at least 6 characters" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
        return;
    }
    if ([[self.emailField text] length] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Email address required" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
        return;
    }
//    if ([[self.phoneField text] length] == 0) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Phone number required" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
//        [alert show];
//        return;
//    }
    
    if(![self validateEmail:self.emailField.text]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"This doesn't appear to be a valid email address"
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    // else register user
    User *newUser = [User userWithUsername:username
                                     email:self.emailField.text];
    newUser.phone = self.phoneField.text;
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

	__block BGControllerRegister *blockSelf = self;
	[[AppData sharedInstance] registerUser:newUser
                                     password:[self.passwordField text]
                                     callback:^(id result, NSError *error) {
                                         
                                         if (error == nil) {
                                             
                                             [[AppData sharedInstance] setLocalSessionWithEmail:newUser.username
                                                                                       password:self.passwordField.text];
                                             
                                             __block BGControllerRegister *blockSelf2 = blockSelf;
                                             
                                             [[AppData sharedInstance] loginWithEmail:newUser.username
                                                                             password:self.passwordField.text
                                                                          andCallback:^(id result, NSError *error) {
                                                                              
                                                                              [MBProgressHUD hideAllHUDsForView:self.view animated:YES];

                                                                              if(!error) {
                                                                                  
                                                                                  [FIRAnalytics logEventWithName:@"signed_up"
                                                                                                      parameters:@{
                                                                                                                   @"user":[NSString stringWithFormat:@"USER_ID_%@", [AppData sharedInstance].localUser.theId],
                                                                                                                   }];
                                                                                  
                                                                                  CATransition *transition = [CATransition animation];
                                                                                  transition.duration = 0.3;
                                                                                  transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                                                                                  transition.type = kCATransitionFade;
                                                                                  [blockSelf2.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];
                                                                                  [[AppData sharedInstance].navigationManager setModalPresentationStyle: UIModalPresentationFullScreen];
                                                                                  [blockSelf2.navigationController presentViewController:[AppData sharedInstance].navigationManager animated:NO completion:nil];
                                                                                  [[AppData sharedInstance].navigationManager setSelectedIndex:2];
                                                                                  
                                                                                  [blockSelf2.navigationController popToRootViewControllerAnimated:NO];

                                                                                  
                                                                              } else {
                                                                                  [blockSelf2.delegate registrationFinished:blockSelf withUser:newUser];
                                                                              }
                                                                              
                                                                          }];
                                             
                                         } else {
                                             [MBProgressHUD hideAllHUDsForView:self.view animated:YES];

                                             [[[UIAlertView alloc] initWithTitle:@"Registration Failed!"
                                                                        message:error.localizedDescription
                                                                       delegate:nil
                                                              cancelButtonTitle:@"Ok"
                                                               otherButtonTitles:nil] show];
                                         }
                                         
                                         blockSelf = nil;
                                     }];
}

- (BOOL)validateEmail:(NSString *)candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:candidate];
}

#pragma mark - UITextFieldDelegate protocol

/**
 * This delegate is called when focus the text field should
 */
- (void)focusTextField:(UITextField *)textField {
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width, self.view.frame.size.height);
    
    CGRect frame = textField.frame;
    frame.origin.y += 15.0;
    [self.scrollView scrollRectToVisible:frame animated:YES];
}
/**
 * This delegate is called that editing began for the specified text field.
 */
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // have to focus textField at next runloop because keyboard may not be in position yet
    [self performSelectorOnMainThread:@selector(focusTextField:) withObject:textField waitUntilDone:NO];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
    
    if (textField == self.emailField) {
        // submit data
        [self commitData];
        
    } else if (textField == self.usernameField) {
        [self.passwordField becomeFirstResponder];
        
    } else if (textField == self.passwordField) {
        [self.emailField becomeFirstResponder];
    }
    
    return true;
}

@end
