//
//  BGTouchDownGestureRecognizer.m
//  Blog
//
//  Created by James Ajhar on 9/11/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGTouchDownGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation BGTouchDownGestureRecognizer

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    if (self.state == UIGestureRecognizerStatePossible) {
        self.state = UIGestureRecognizerStateRecognized;
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    self.state = UIGestureRecognizerStateFailed;
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    self.state = UIGestureRecognizerStateRecognized;
}


@end
