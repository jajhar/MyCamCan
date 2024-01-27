/**
 *  BGViewMediaOverlay.m
 *  MCC
 *@author James Ajhar
 *@since  10/15/14.
 *  Copyright (c) 2014 D9. All rights reserved.
 */

#import "BGViewMediaOverlay.h"

#import "Media.h"

@interface BGViewMediaOverlay ()

// interface
@property (strong, nonatomic) IBOutlet UIButton *doneButton;
@property (strong, nonatomic) IBOutlet UIView *overlayView;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
// data
@property (strong, nonatomic) Media *media;
@property (assign, nonatomic) BOOL interfaceVisible;

// methods
- (IBAction)donePressed:(id)sender;

@end


@implementation BGViewMediaOverlay

- (void)updateWithMedia:(Media *)media {
    _media = media;
    [self setupView];
}

- (void)setupView {
    
//    [self.likeButton setSelected:[self.media liked]];
//    [self displayCaption];
}
/**
 * Return YES for supported orientations
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
        return NO;
}

//- (void)displayCaption {
//    
//    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:@""];
//
//    if(self.media.caption.length != 0 && self.media.type != kMediaTypeText) {
//        NSString *captionString = self.media.caption;
//        
//        NSAttributedString *captionAttributedString = [[NSAttributedString alloc] initWithString:captionString
//                                                                                      attributes:@{NSFontAttributeName: [[BGStyle sharedInstance] fontWithName:kVXStyle_Font_Text],
//                                                                                                   NSForegroundColorAttributeName: [UIColor whiteColor]}];
//        
//        [attrString appendAttributedString: captionAttributedString];
//        
//        NSError *error = nil;
//        NSRegularExpression *tagRegex = [NSRegularExpression regularExpressionWithPattern:@"(?:(?<=\\s)|^)#(\\w*[A-Za-z_]+\\w*)" options:0 error:&error];
//        NSArray *tagMatches = [tagRegex matchesInString:[attrString string] options:0 range:NSMakeRange(0, [attrString string].length)];
//        
//        // parse for hashtags
//        for (NSTextCheckingResult *match in tagMatches) {
//            NSRange wordRange = [match rangeAtIndex:0];
//            
//            [attrString beginEditing];
//            
//            [attrString addAttribute:NSFontAttributeName
//                               value:[[BGStyle sharedInstance] fontWithName:kVXStyle_Font_Tag]
//                               range:wordRange];
//            
//            [attrString addAttribute:NSForegroundColorAttributeName value:[[BGStyle sharedInstance] colorWithName: kVXStyle_Color_Pulse_Hashtag] range:wordRange];
//            
//            [attrString addAttribute:@"tag"
//                               value:@(YES)
//                               range:wordRange];
//            
//            [attrString endEditing];
//        }
//    }
//    
//    self.captionTextView.attributedText = attrString;
//    self.captionTextView.textAlignment = NSTextAlignmentCenter;
//}


- (void)toggleInterfaceControls {
    if(_interfaceVisible) {
        [self hideInterfaceControlsAnimated:YES];
    } else {
        [self showInterfaceControlsAnimated:YES];
    }
}

- (void)hideInterfaceControlsAnimated:(BOOL)animated {
    if(animated) {
        [UIView animateWithDuration:.3 animations:^{
            self.overlayView.alpha = 0.0;
        } completion:^(BOOL finished) {
            _interfaceVisible = NO;
        }];
    } else {
        self.overlayView.alpha = 0.0;
    }
    
    [self.delegate interfaceHidden];
}

- (void)showInterfaceControlsAnimated:(BOOL)animated {
    if(animated) {
        [UIView animateWithDuration:.3 animations:^{
            self.overlayView.alpha = 1.0;
        } completion:^(BOOL finished) {
            _interfaceVisible = YES;
        }];
    } else {
        self.overlayView.alpha = 1.0;
    }
    
    [self.delegate interfaceShown];
}

#pragma mark - Interface Actions

/**
 *This method is called action to dismiss the full screen when done pressed
 */
- (IBAction)donePressed:(id)sender {
    [self.delegate donePressed:sender];
}

- (IBAction)sharePressed:(id)sender {
    
    self.shareButton.enabled = NO;
    
    [MBProgressHUD showHUDAddedTo:self animated:YES];
    
    __block BGViewMediaOverlay *blockSelf = self;
    
    [Media addWaterMarkToVideo:self.media.mediaUrl completion:^(NSURL *url, NSError *error) {
        
        self.shareButton.enabled = YES;
        [MBProgressHUD hideAllHUDsForView:self animated:NO];

        if(!error) {
            NSArray *itemsToShare = @[[NSString stringWithFormat:@"%@ - by %@ MyCamCan www.mycamcan.com", self.media.caption, self.media.owner.username], url];
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:[NSArray new]];
            activityVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList];
            
            activityVC.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
                if (completed) {
                    NSLog(@"The selected activity was %@", activityType);
                }
            };
            
            if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {
                // iOS8
                activityVC.popoverPresentationController.sourceView = blockSelf.shareButton;
            }
            
            [[AppData sharedInstance].navigationManager presentViewController:activityVC animated:YES completion:nil];
            
        } else {
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Uh Oh!" message:@"We were unable to share this. Please try again." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:action];
            
            [[AppData sharedInstance].navigationManager presentViewController:alertController animated:YES completion:nil];

        }
    }];
    
}

/**
 *This method is called action to send the comment when comment button pressed
 */
//- (IBAction)commentPressed:(id)sender {
//    [self.delegate donePressed:nil];
//    
//    [[BGMCC sharedInstance] presentMediaDetailControllerAnimated:YES
//                                                          fromRight:YES
//                                                               info:@{kVXKeyMedia: self.media}];
//}
/**
 *This method is called action to set like when user click like pressed
 */
//- (IBAction)likePressed:(id)sender {
//    // Toggle like on media
//    if (self.likeButton.selected) {
//        self.likeButton.selected = NO;
//        
//        [[MCCData sharedInstance] unlikeMedia:self.media
//                                        callback:^(id result, NSError *error) {
//                                            if (error) {
//                                                self.likeButton.selected = YES;
//                                            }
//                                        }];
//    } else {
//        // like
//        self.likeButton.selected = YES;
//        
//        [[MCCData sharedInstance] likeMedia:self.media
//                                      callback:^(id result, NSError *error) {
//                                          if (error) {
//                                              self.likeButton.selected = NO;
//                                          }
//                                      }];
//    }
//}

#pragma mark - notifications

/**
 <p>
 * This method will be called via NSNotificationCenter whenever the media has been updated in some
 * way.
 *It will add , remove or refresh cell accordingly.
 */
//- (void)notificationMediaUpdated:(NSNotification *)notification {
//    /**
//     kMCCData_Notification_Element_Media
//     */
//    
//    Media *updatedMedia = [[notification userInfo] objectForKey:kMCCData_NotificationKey_Media];
//    
//    if(updatedMedia && [DataModelObject modelObject:_media isEqualTo:updatedMedia]) {
//        
//        //        [self.zoomingViewController updateWithMedia:_mediaInfo];
//        [self setupView];
//    }
//    
//}

#pragma mark BGView
/**
* This method is called to create GUI for the media overlay.
 */
- (void)commonInit {
    [super commonInit];
    
    self.doneButton.layer.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5].CGColor;
    self.doneButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.doneButton.layer.cornerRadius = 8.0f;
    self.doneButton.layer.borderWidth = 1.0f;
    
    self.shareButton.layer.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5].CGColor;
    self.shareButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.shareButton.layer.cornerRadius = 8.0f;
    self.shareButton.layer.borderWidth = 1.0f;
    
//    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textViewTapped:)];
//    [self.captionTextView addGestureRecognizer:recognizer];
    
    _interfaceVisible = YES;
    
//    NSNotificationCenter *sharedNC = [NSNotificationCenter defaultCenter];
//    
//    [sharedNC addObserver:self
//                 selector:@selector(notificationMediaUpdated:)
//                     name:kMCCData_Notification_Element_Media
//                   object:nil];
    
}

/**
 * Unlinks the view from its superview and its window, and removes it from the responder chain.
 */
- (void)removeFromSuperview {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super removeFromSuperview];
}

/**
 * Deallocates the memory occupaid by the notification observer,mediaview.
 */
- (void)dealloc {    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 * This function is called when user tapped the textview for rearranging the in the layout
 */
//- (void)textViewTapped:(UITapGestureRecognizer *)recognizer {
//    UITextView *textView = (UITextView *)recognizer.view;
//    
//    // Location of the tap in text-container coordinates
//    NSLayoutManager *layoutManager = textView.layoutManager;
//    CGPoint location = [recognizer locationInView:textView];
//    location.x -= textView.textContainerInset.left;
//    location.y -= textView.textContainerInset.top;
//    
//    // Find the character that's been tapped on
//    
//    NSUInteger characterIndex;
//    characterIndex = [layoutManager characterIndexForPoint:location
//                                           inTextContainer:textView.textContainer
//                  fractionOfDistanceBetweenInsertionPoints:NULL];
//    
//    if (characterIndex < textView.textStorage.length) {
//        NSRange range;
//        NSDictionary *attributes = [textView.textStorage attributesAtIndex:characterIndex effectiveRange:&range];
//        
//        if([[attributes objectForKey:@"tag"] boolValue]){       // if this is a tag
//            NSString *tagWithoutHash = [[textView.text substringWithRange:range] stringByReplacingOccurrencesOfString:@"#" withString:@""];
//            
//            [self.delegate donePressed:nil];
//
//            [[BGMCC sharedInstance] presentFeedControllerAnimated:YES
//                                                           fromRight:YES
//                                                                info:[NSDictionary dictionaryWithObjectsAndKeys:
//                                                                      tagWithoutHash,                                                    kVXKeyFeedTag,
//                                                                      [NSNumber numberWithUnsignedInteger:kVXControllerFeedFilterTag],   kVXKeyFeedFilter,
//                                                                      nil]];
//            
//        }
//    }
//}


#pragma mark Hit Test
/**
* Returns the farthest descendant of the receiver in the view hierarchy (including itself) that contains a specified point
 */
-(id)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    id hitView = [super hitTest:point withEvent:event];
    
    if(!_interfaceVisible) {
        return nil;
    }
    
    if (hitView == self.doneButton || hitView == self.shareButton) {
        return hitView;
    } else {
        return nil;
    }
}


@end
