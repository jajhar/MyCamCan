//
//  BGControllerUpdatePassword.m
//  Blog
//
//  Created by James Ajhar on 4/5/16.
//  Copyright © 2016 James Ajhar. All rights reserved.
//

#import "BGControllerUpdatePassword.h"
#import "MBProgressHUD.h"

@interface BGControllerUpdatePassword ()

@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation BGControllerUpdatePassword

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Interface Actions

- (IBAction)submitPressed:(id)sender {
    
    if (self.passwordTextField.text.length < 6) {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Password must be at least 6 characters" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];

        
        return;
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[AppData sharedInstance] updatePassword:self.passwordTextField.text token:self.token callback:^(id result, NSError *error) {
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
        
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                        message:@"Something went wrong! Please try again."
                                       delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil] show];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success!" message:@"Please log in with your new password" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self.navigationController popToRootViewControllerAnimated:YES];
            }];
            
            [alert addAction:action];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}


@end
