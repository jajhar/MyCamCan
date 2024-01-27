/**
*  BGAlertViewDeleteMedia.h
*  MCC
*  @author Shakuro Developer
*  @since 8/6/14.
*  Copyright (c) 2014 D9. All rights reserved.
*/


#import <UIKit/UIKit.h>

#import "AppData.h"


@interface BGAlertViewDeleteMedia : UIAlertView

/**
 * This alert view is called when the user wants to remove a media from his capsule.
 */
+ (void)showDeletionPromptForMedia:(Media *)media completion:(AppDataCallback)completionBlock;

@end
