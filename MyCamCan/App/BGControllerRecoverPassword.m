//
//  BGControllerRecoverPassword.m
//  Blog
//
//  Created by James Ajhar on 2/13/16.
//  Copyright © 2016 James Ajhar. All rights reserved.
//

#import "BGControllerRecoverPassword.h"

@interface BGControllerRecoverPassword ()

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;

@end

@implementation BGControllerRecoverPassword

- (void)viewDidLoad {
    [super viewDidLoad];

}


#pragma mark - Interface Actions

- (IBAction)submitPressed:(id)sender {
    
    if (self.emailTextField.text.length < 3) {
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:@"Please enter a valid email address"
                                  delegate:nil
                         cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
    
        return;
    }
    
    [[AppData sharedInstance] sendForgotPasswordRequestWithEmail:self.emailTextField.text andCallback:^(id result, NSError *error) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                        message:@"Something went wrong! Please try again."
                                       delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil] show];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Success!"
                                        message:@"Please check your email for instructions on how to reset your password"
                                       delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil] show];
        }
    }];
}


@end
