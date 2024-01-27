//
//  BGTouchDownGestureRecognizer.m
//  Blog
//
//  Created by James Ajhar on 9/11/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGTouchUpGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation BGTouchUpGestureRecognizer

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    if (self.state == UIGestureRecognizerStatePossible) {
        self.state = UIGestureRecognizerStateBegan;
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    self.state = UIGestureRecognizerStateFailed;
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if (self.state == UIGestureRecognizerStatePossible) {
        self.state = UIGestureRecognizerStateRecognized;
}}


@end
