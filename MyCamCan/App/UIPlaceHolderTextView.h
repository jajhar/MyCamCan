//
//  TextViewWithPlaceholder.h
//  Blog
//
//  Created by James Ajhar on 4/5/16.
//  Copyright © 2016 James Ajhar. All rights reserved.
//

#import <Foundation/Foundation.h>
IB_DESIGNABLE
@interface UIPlaceHolderTextView : UITextView

@property (nonatomic, retain) IBInspectable NSString *placeholder;
@property (nonatomic, retain) IBInspectable UIColor *placeholderColor;

-(void)textChanged:(NSNotification*)notification;

@end
