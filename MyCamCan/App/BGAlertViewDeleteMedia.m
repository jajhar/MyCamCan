/**
*  BGAlertViewDeleteMedia.m
*  MCC
*  @author Shakuro Developer
*  @since 8/6/14.
*  Copyright (c) 2014 D9. All rights reserved.
*/


#import "BGAlertViewDeleteMedia.h"

#import "Media.h"


@interface BGAlertViewDeleteMedia () <UIAlertViewDelegate>

@property (nonatomic, weak) Media *mediaToDelete;
@property (nonatomic, copy) AppDataCallback completionBlock;

@end


@implementation BGAlertViewDeleteMedia


#pragma mark - L0


+ (void)showDeletionPromptForMedia:(Media *)media completion:(AppDataCallback)completionBlock {
    BGAlertViewDeleteMedia* alert = [[BGAlertViewDeleteMedia alloc] initWithTitle:@"Wait!"
                                                                          message:@"Are you sure you'd like to delete this?"
                                                                         delegate:self
                                                                cancelButtonTitle:NSLocalizedString(@"Cancel",@"Option to cancel the alert message")
                                                                otherButtonTitles:NSLocalizedString(@"Delete",@"Option to confrim delete operation"), nil];
    alert.delegate = alert; // handle oneself
    alert.mediaToDelete = media;
    alert.completionBlock = completionBlock;
    [alert show];
}


#pragma mark - L1


@synthesize mediaToDelete = _mediaToDelete;


#pragma mark - Protocols

/**
*This method is called when the user selects cancel Button Index to remove media from the user/capsule.
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == self &&
        buttonIndex != [alertView cancelButtonIndex]) {
        // confirmation is here - delete media
        Media *strongMedia = [(BGAlertViewDeleteMedia *)alertView mediaToDelete];
        AppDataCallback completionBlock = [(BGAlertViewDeleteMedia *)alertView completionBlock];
       
        if (strongMedia != nil && [strongMedia isKindOfClass:[DataModelObject class]]) {

            [[AppData sharedInstance] deleteMedia:strongMedia
                                         callback:^(id result, NSError *error) {
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 if (completionBlock != nil) {
                                                     completionBlock(result, error);
                                                 }
                                             });
                                         }];
            
        }
        else
        {
            NSLog(@"Error: Delete media failed");
        }
    }
}


@end
