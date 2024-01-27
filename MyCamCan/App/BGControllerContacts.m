//
//  BGControllerContacts.m
//  Blog
//
//  Created by James Ajhar on 9/13/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGControllerContacts.h"
#import <APAddressBook/APAddressBook.h>
#import <APAddressBook/APContact.h>
#import "MBProgressHUD.h"
#import "BGCellContact.h"
#import <MessageUI/MessageUI.h>

NSString *kBGControllerContacts = @"BGControllerContacts";

@interface BGControllerContacts () <UITableViewDataSource, UITableViewDelegate, MFMessageComposeViewControllerDelegate>
{
    NSInteger _currentCellIndex;
    BOOL _firstHeaderSet;
    BOOL _allSelected;
}

// UI
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIButton *sendInvitesButton;
@property (strong, nonatomic) IBOutlet UIButton *skipButton;

// Data
@property (strong, nonatomic) NSMutableDictionary *contacts;
@property (strong, nonatomic) NSMutableArray *invitedContacts;

@end

@implementation BGControllerContacts

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.contacts = [NSMutableDictionary new];
    self.invitedContacts = [NSMutableArray new];
    _currentCellIndex = 0;
    _firstHeaderSet = NO;
    _allSelected = NO;
    
    [self loadContacts];
    
}


#pragma mark - Interface Actions


- (IBAction)inviteButtonPressed:(UIButton *)sender {
    [sender setSelected:!sender.selected];
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    BGCellContact *cell = (BGCellContact *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    if(sender.selected) {
        [self.invitedContacts addObject:cell.contact];
    } else {
        [self.invitedContacts removeObject:cell.contact];
    }
    
    if(self.invitedContacts.count > 0) {
        self.sendInvitesButton.hidden = NO;
        self.skipButton.hidden = YES;
    } else {
        self.sendInvitesButton.hidden = YES;
        self.skipButton.hidden = NO;
    }
}

- (IBAction)skipPressed:(id)sender {
    
    [self.navigationController popToRootViewControllerAnimated:NO];

    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [self.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];
    [self.navigationController presentViewController:[AppData sharedInstance].navigationManager animated:NO completion:nil];
    [[AppData sharedInstance].navigationManager setSelectedIndex:2];
}

- (IBAction)sendInvitationsPressed:(id)sender {
    [self showSMS];
}

- (IBAction)selectAllContacts:(UIButton *)sender {

    [sender setSelected:!sender.selected];
    
    // start fresh
    [self.invitedContacts removeAllObjects];
    
    if(_allSelected) {
        
        // remove all from list
        for (NSInteger j = 0; j < [self.tableView numberOfSections]; ++j)
        {
            for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:j]; ++i)
            {
                BGCellContact *cell = (BGCellContact *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:j]];
                
                [cell setInviteSelected:NO];
                // contacts already removed above
            }
        }
        
        _allSelected = NO;

    } else {

        // add all to list
        for (NSInteger j = 0; j < [self.tableView numberOfSections]; ++j)
        {
            for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:j]; ++i)
            {
                BGCellContact *cell = (BGCellContact *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:j]];
                
                [cell setInviteSelected:YES];
                [self.invitedContacts addObject:cell.contact];
            }
        }
        
        _allSelected = YES;

    }
    
    if(self.invitedContacts.count > 0) {
        self.sendInvitesButton.hidden = NO;
        self.skipButton.hidden = YES;
    } else {
        self.sendInvitesButton.hidden = YES;
        self.skipButton.hidden = NO;
    }    
}

#pragma mark - Helpers


- (void)loadContacts {
    
//    switch([APAddressBook access])
//    {
//        case APAddressBookAccessUnknown:
//            // Application didn't request address book access yet
//            break;
//            
//        case APAddressBookAccessGranted:
//            // Access granted
//            break;
//            
//        case APAddressBookAccessDenied:
//            [[[UIAlertView alloc] initWithTitle:@"Access Denied"
//                                        message:@"Please grant the app access to your contacts in your phone settings"
//                                       delegate:nil
//                              cancelButtonTitle:@"Ok"
//                              otherButtonTitles:nil] show];
//            break;
//    }
//    
//    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    
//    APAddressBook *addressBook = [[APAddressBook alloc] init];
//    
//    addressBook.filterBlock = ^BOOL(APContact *contact)
//    {
//        return contact.phones.count > 0;
//    };
//    
//    addressBook.sortDescriptors = @[
//                                    [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES],
//                                    [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES]
//                                    ];
//    
//
//    [addressBook loadContacts:^(NSArray *contacts, NSError *error)
//     {
//         [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
//         
//         if (!error)
//         {
//             NSMutableArray *curElements;
//             NSString * firstLetter;
//             
//             for(APContact *contact in contacts) {
//                 
//                 firstLetter = [[contact.lastName substringToIndex:1] uppercaseString];
//                 curElements = [self.contacts objectForKey:firstLetter];
//                 
//                 if(curElements == nil) {
//                     curElements = [NSMutableArray new];
//                 }
//                 
//                 if(firstLetter == nil) {
//                     firstLetter = @"";
//                 }
//                 
//                 [curElements addObject:contact];
//                 
//                 [self.contacts setObject:curElements forKey:firstLetter];
//             }
//             
//             [self.tableView reloadData];
//         }
//         else
//         {
//             NSLog(@"Error retrieving contacts: %@", error);
//             // show error
//         }
//     }];
}

#pragma mark - UITableViewDelegate/Datasource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.contacts allKeys] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 44)];
    /* Create custom view to display section header... */
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width, 44)];
    [label setFont:[UIFont boldSystemFontOfSize:17]];
    NSString *title = [[[self.contacts allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section];

    [label setText:title];
    [view addSubview:label];
    
    if(!_firstHeaderSet) {
        _firstHeaderSet = YES;
        
        UIButton *selectAllButton = [[UIButton alloc] initWithFrame:CGRectMake(tableView.frame.size.width - 80, 0, 80, 44)];
        [selectAllButton addTarget:self
                            action:@selector(selectAllContacts:)
                  forControlEvents:UIControlEventTouchUpInside];
        [selectAllButton setTitle:@"Invite all" forState:UIControlStateNormal];
        [view addSubview:selectAllButton];
    }
    
    [view setBackgroundColor:[UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0]];
    
    return view;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.contacts valueForKey:[[[self.contacts allKeys]
                                         sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section]] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BGCellContact *cell = [tableView dequeueReusableCellWithIdentifier:@"BGCellContact"];
    
    if(_currentCellIndex % 2 != 0) {
        // odd cell color
//        [cell.contentView setBackgroundColor:[UIColor colorWithRed:166/255.0 green:177/255.0 blue:186/255.0 alpha:1.0]]; //your background color...
    }

    _currentCellIndex++;

    APContact *contact = [[self.contacts valueForKey:[[[self.contacts allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    
    [cell setupWithContact:contact];
    
    return cell;
}


#pragma mark - Messaging


- (void)showSMS {
    
//    if(![MFMessageComposeViewController canSendText]) {
//        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//        [warningAlert show];
//        return;
//    }
//    
//    NSMutableArray *recipents = [NSMutableArray new];
//    
//    for(APContact *contact in self.invitedContacts) {
//        if([[contact.phones firstObject] isKindOfClass:[NSString class]]) {
//            [recipents addObject:[contact.phones firstObject]];
//        } else {
//            [recipents addObject:[[contact.phones firstObject] phoneNumber]];
//        }
//    }
//    
//    NSString *message = [NSString stringWithFormat:@"Hey! Check out this cool app called MyCamCan!"];
//    
//    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
//    messageController.messageComposeDelegate = self;
//    [messageController setRecipients:recipents];
//    [messageController setBody:message];
//    
//    // Present message view controller on screen
//    [self presentViewController:messageController animated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    switch (result) {
        case MessageComposeResultCancelled:
            break;
            
        case MessageComposeResultFailed:
        {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to send SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            break;
        }
            
        case MessageComposeResultSent:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                            message:@"Invitations sent!"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            break;
        }
            
        default:
            break;
    }
    
    [controller dismissViewControllerAnimated:YES completion:^{
        CATransition *transition = [CATransition animation];
        transition.duration = 0.3;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        [self.view.window.layer addAnimation:transition forKey:@"BGCustomAnim"];
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self.navigationController presentViewController:[AppData sharedInstance].navigationManager animated:NO completion:nil];
        [[AppData sharedInstance].navigationManager setSelectedIndex:2];
    }];
}


@end
