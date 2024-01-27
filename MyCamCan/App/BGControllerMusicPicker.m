//
//  BGControllerMusicPicker.m
//  Blog
//
//  Created by James Ajhar on 7/22/15.
//  Copyright (c) 2015 James Ajhar. All rights reserved.
//

#import "BGControllerMusicPicker.h"
#import "BGItunesMusicXMLParser.h"
#import "BGMusicCell.h"
#import "MBProgressHUD.h"
#import "MusicItem.h"
#import "HysteriaPlayer.h"
#import "BGControllerCamera.h"
#import "BGViewButtonCarousel.h"
#import "DACircularProgressView.h"
#import "RETrimControl.h"
#import "BGViewSearchMusic.h"
#import "ILRemoteSearchBar.h"
#import "WindowHitTest.h"
#import "BGViewMyMusicLibrary.h"
#import "BGViewFeaturedArtist.h"

@import Firebase;
@import MediaPlayer;
@import GoogleMobileAds;

NSString *kBGControllerMusicPicker = @"BGControllerMusicPicker";

@interface BGControllerMusicPicker () <BGViewButtonCarouselDelegate, HysteriaPlayerDataSource, HysteriaPlayerDelegate, MPMediaPickerControllerDelegate, BGViewSearchMusicDelegate, BGViewMyMusicLibraryDelegate, BGViewFeaturedArtistDelegate, UISearchBarDelegate, ILRemoteSearchBarDelegate, GADBannerViewDelegate>
{
    NSUInteger _page;
    BOOL _finishedParsingItunes;
}

@property (weak, nonatomic) IBOutlet UIButton *firstTimeViewCloseButton;
@property (weak, nonatomic) IBOutlet UIButton *firstTimeViewStartButton;

@property (strong, nonatomic) HysteriaPlayer *musicPlayer;
@property (strong, nonatomic) IBOutlet UIButton *nextButton;
@property (strong, nonatomic) MusicItem *selectedMusicItem;
@property (strong, nonatomic) IBOutlet BGViewButtonCarousel *buttonCarousel;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
//@property (strong, nonatomic) IBOutlet UIView *ipodView;
@property (strong, nonatomic) RETrimControl *trimControl;
@property (weak, nonatomic) IBOutlet UIView *musicTrimView;
@property (strong, nonatomic) BGViewSearchMusic *searchMusicView;
@property (strong, nonatomic) BGViewMyMusicLibrary *musicLibraryView;
@property (strong, nonatomic) NSMutableArray *featuredArtistViews;
@property (strong, nonatomic) NSMutableDictionary *artistsAndSongs;
@property (strong, nonatomic) NSMutableArray *allArtists;

@property (strong, nonatomic) DACircularProgressView *uploadProgressView;
@property (nonatomic, assign) BOOL didSelectItem;
@property (strong, nonatomic) ILRemoteSearchBar *searchBar;
@property(nonatomic, strong) GADBannerView *bannerView;


@end


@implementation BGControllerMusicPicker

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Instantiate the banner with desired ad size.
    self.bannerView = [[GADBannerView alloc]
                       initWithAdSize:kGADAdSizeSmartBannerPortrait];
    
#ifdef RELEASE
    self.bannerView.adUnitID = @"ca-app-pub-4205559539892230/2409431022";
#else
    self.bannerView.adUnitID = @"ca-app-pub-3940256099942544/2934735716";
#endif
    
    self.bannerView.delegate = self;
    self.bannerView.rootViewController = self;
    [self.bannerView loadRequest:[GADRequest request]];
    
    // add next button to nav bar
    self.nextButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [_nextButton setTitle:@"next" forState:UIControlStateNormal];
    [_nextButton addTarget:self action:@selector(nextPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_nextButton];
    
    self.searchBar = [[ILRemoteSearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 64)];
    self.searchBar.showsCancelButton = NO;
    self.searchBar.delegate = self;
    self.searchBar.timeToWait = 0.0;
    
    self.featuredArtistViews = [NSMutableArray new];
    self.artistsAndSongs = [NSMutableDictionary new];
    self.allArtists = [NSMutableArray new];

    _finishedParsingItunes = NO;
    
    self.firstTimeViewStartButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.firstTimeViewStartButton.layer.borderWidth = 1.0f;

    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if([defaults objectForKey:@"hasViewedMusicPickerToolTip"] != nil &&
       [[defaults objectForKey:@"hasViewedMusicPickerToolTip"] boolValue])
    {
        self.musicTrimView.hidden = YES;
    } else {
        self.musicTrimView.hidden = NO;
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"hasViewedMusicPickerToolTip"];
    }
    
    _uploadProgressView = [[DACircularProgressView alloc] initWithFrame:CGRectMake(0.0, 0.0, 80.0, 80.0)];
    [_uploadProgressView setCenter:self.view.center];
    _uploadProgressView.autoresizingMask = UIViewAutoresizingNone;
    _uploadProgressView.roundedCorners = YES;
    _uploadProgressView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_uploadProgressView];
    _uploadProgressView.hidden = YES;
    
    self.buttonCarousel.delegate = self;
    
    self.musicPlayer = [HysteriaPlayer new];
    
    // Styling
    self.nextButton.layer.cornerRadius = 3.0;
    
    _page = 0;
    
    [self getFeaturedArtists];

    // Notifications
    NSNotificationCenter *sharedNC = [NSNotificationCenter defaultCenter];
    [sharedNC addObserver:self
                 selector:@selector(notificationWindowHitTest:)
                     name:kBGNotificationWindowTapped
                   object:nil];
}

- (void)addBannerViewToView:(UIView *)bannerView {
    bannerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:bannerView];
    [self.view addConstraints:@[
                                [NSLayoutConstraint constraintWithItem:bannerView
                                                             attribute:NSLayoutAttributeBottom
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.bottomLayoutGuide
                                                             attribute:NSLayoutAttributeTop
                                                            multiplier:1
                                                              constant:0],
                                [NSLayoutConstraint constraintWithItem:bannerView
                                                             attribute:NSLayoutAttributeCenterX
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeCenterX
                                                            multiplier:1
                                                              constant:0]
                                ]];
}

- (void)getFeaturedArtists {
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[AppData sharedInstance] getFeaturedArtistMusicWithCallback:^(NSArray *results, NSError *error) {
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        self.artistsAndSongs = [NSMutableDictionary new];
        
        if(!error && results) {
            
            for (MusicItem *musicItem in results) {
                
                if ([self.artistsAndSongs objectForKey:musicItem.grouping]) {
                    
                    // already exists in datasource
                    NSMutableArray *array = [self.artistsAndSongs objectForKey:musicItem.grouping];
                    [array addObject:musicItem];
                    
                } else {
                    
                    [self.allArtists addObject:musicItem.grouping];
                    [self.artistsAndSongs setObject:[NSMutableArray arrayWithObject:musicItem] forKey:musicItem.grouping];
                }
            }
            
            CGRect frame = self.scrollView.bounds;

            for (NSInteger i=0; i < self.allArtists.count; i++) {
                NSString *artist = [self.allArtists objectAtIndex:i];
                
                UIView *slideView = [[[NSBundle mainBundle] loadNibNamed:@"BGViewFeaturedArtist" owner:self options:nil] objectAtIndex:0];
                slideView.frame = frame;
                slideView.backgroundColor = [UIColor redColor];
                [self.scrollView addSubview:slideView];
                BGViewFeaturedArtist *view = (BGViewFeaturedArtist *)slideView;
                view.delegate = self;
                
                view.musicItems = [self.artistsAndSongs objectForKey:artist];
                [view.tableView reloadData];
                
                [self.featuredArtistViews addObject:view];
                frame.origin.x = CGRectGetMaxX(slideView.frame);
            }

            UIView *slide2View = [[[NSBundle mainBundle] loadNibNamed:@"BGViewMyMusicLibrary" owner:self options:nil] objectAtIndex:0];
//            frame = self.scrollView.bounds;
//            frame.origin.x = CGRectGetMaxX(slide1View.frame);
            slide2View.frame = frame;
            [self.scrollView addSubview:slide2View];
            self.musicLibraryView = (BGViewMyMusicLibrary *)slide2View;
            self.musicLibraryView.delegate = self;

            self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * ([self.artistsAndSongs count] + 1), self.scrollView.frame.size.height);

        } else {
            
            CGRect frame = self.scrollView.bounds;
            UIView *slide2View = [[[NSBundle mainBundle] loadNibNamed:@"BGViewMyMusicLibrary" owner:self options:nil] objectAtIndex:0];
            frame = self.scrollView.bounds;
            slide2View.frame = frame;
            [self.scrollView addSubview:slide2View];
            self.musicLibraryView = (BGViewMyMusicLibrary *)slide2View;
            self.musicLibraryView.delegate = self;
            
            self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.scrollView.frame.size.height);
        }
        
        if (self.allArtists.count == 0) {
            // show search bar
            self.navigationItem.titleView = self.searchBar;
        } else {
            self.navigationItem.titleView = nil;
        }
        
        [self.buttonCarousel reloadData];
        [self.view layoutIfNeeded];
        
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
//    [self.musicLibraryView fetchMusicLibrary];
    
    self.navigationItem.title = @"Choose Clip";
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Hysteria Music Player
    self.musicPlayer.delegate = self;
    self.musicPlayer.datasource = self;
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.searchMusicView pausePlayer];
    [self.musicPlayer pause];
    [self.musicPlayer removeAllItems];
    [self.musicLibraryView pausePlayer];
    
    for (BGViewFeaturedArtist *view in self.featuredArtistViews) {
        [view pausePlayer];
    }
}

- (BOOL)fileExistsAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:path];
}

- (void)downloadAudioFile {

    [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
    
    if(self.selectedMusicItem.needsExport) {
        [self exportAssetWithURL:self.selectedMusicItem.previewURL];
        [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
        return;
    }
    
    NSString *docDirPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                NSUserDomainMask,
                                                                YES) lastObject];
    
    NSString *fileName = [[NSString stringWithFormat:@"%@", self.selectedMusicItem.previewURL] stringByReplacingOccurrencesOfString:@"/" withString:@""];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", docDirPath, fileName];
   
    // Check if file already exists in documents
    if ([self fileExistsAtPath:filePath]) {
        self.selectedMusicItem.localFileURL = [NSURL fileURLWithPath:filePath];
        [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
        return;
    }
    
    // Synchronously download audio file
    NSData *audioData = [NSData dataWithContentsOfURL:self.selectedMusicItem.previewURL];
    
    [audioData writeToFile:filePath atomically:YES];

    self.selectedMusicItem.localFileURL = [NSURL fileURLWithPath:filePath];
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Interface Actions

- (IBAction)startPressed:(id)sender {
    
    [UIView animateWithDuration:.3
                     animations:^{
                         self.musicTrimView.alpha = 0.0;
                     }];
}

- (IBAction)cancelButtonPressed:(id)sender {
    
    if([AppData sharedInstance].localUser.isFirstTimeUser) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        
        // go to feed
        [[AppData sharedInstance].navigationManager setSelectedIndex:0];

    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)nextPressed:(id)sender {
    
    if(self.selectedMusicItem == nil) {
        [[[UIAlertView alloc] initWithTitle:@""
                                   message:@"Please select a song"
                                  delegate:nil cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
    } else {
        
        [self.musicPlayer pause];
        [self.searchMusicView pausePlayer];
        [self.musicLibraryView pausePlayer];
        
        for (BGViewFeaturedArtist *view in self.featuredArtistViews) {
            [view pausePlayer];
        }
        [self downloadAudioFile];
        
        NSString *userID = [AppData sharedInstance].localUser.theId ? [AppData sharedInstance].localUser.theId : @"Unknown";
        NSString *artist = [self.selectedMusicItem artist] ? [self.selectedMusicItem artist] : @"Unknown";
        NSString *title = [self.selectedMusicItem title] ? [self.selectedMusicItem title] : @"Unknown";
        
        [FIRAnalytics logEventWithName:@"music_selected"
                            parameters:@{
                                         @"user":[NSString stringWithFormat:@"USER_ID_%@", userID],
                                         @"title":title,
                                         @"artist":artist,
                                         kFIRParameterContentType:@"audio"
                                         }];
        
        [[AppData sharedInstance].navigationManager presentControllerForPurpose:kBGPurposeMusicTrim
                                                                           info:@{kBGInfoMusicItem: self.selectedMusicItem}
                                                                     showTabBar:NO];

//        }
        
    }
}

#pragma mark - Helpers

- (void)scrollUIScrollView:(UIScrollView*)scrollView toPage:(NSInteger)page {
    
    CGFloat pageWidth = scrollView.frame.size.width;
    CGFloat pageHeight = scrollView.frame.size.height;
    CGRect scrollTarget = CGRectMake(page * pageWidth, 0, pageWidth, pageHeight);
    [scrollView scrollRectToVisible:scrollTarget animated:YES];
}
#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self.buttonCarousel scrollToIndex:_page];
    
    if (_page == [self.allArtists count]) {
        // show search bar
        self.navigationItem.titleView = self.searchBar;
    } else {
        // hide search bar
        self.navigationItem.titleView = nil;
    }
    
    [self.musicPlayer pause];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    // Update the page when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.scrollView.frame.size.width;
    NSInteger newPage = floor((self.scrollView.contentOffset.x - pageWidth / 4) / pageWidth) + 1;
    _page = newPage;
    
    //    [self.buttonCarousel scrollToIndex:_page];
    //    [self.buttonCarousel scrolltoOffset:scrollView.contentOffset.x];
    
}


- (void)exportAssetWithURL:(NSURL *)url {
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL: url options:nil];

    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset: songAsset
                                                                      presetName:AVAssetExportPresetAppleM4A];


//    CMTime _10 = CMTimeMake(15, 1);
//
//    exporter.timeRange = CMTimeRangeMake(_10, _10);

    exporter.outputFileType =   @"com.apple.m4a-audio";

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString * myDocumentsDirectory = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;

    [[NSDate date] timeIntervalSince1970];
    NSTimeInterval seconds = [[NSDate date] timeIntervalSince1970];
    NSString *intervalSeconds = [NSString stringWithFormat:@"%0.0f",seconds];

    NSString * fileName = [NSString stringWithFormat:@"%@.m4a",intervalSeconds];

    NSString *exportFile = [myDocumentsDirectory stringByAppendingPathComponent:fileName];

    NSURL *exportURL = [NSURL fileURLWithPath:exportFile];
    exporter.outputURL = exportURL;

    dispatch_semaphore_t semaphor = dispatch_semaphore_create(0);

    // do the export
    // (completion handler block omitted)
    [exporter exportAsynchronouslyWithCompletionHandler:
     ^{
         int exportStatus = exporter.status;

         switch (exportStatus)
         {
             case AVAssetExportSessionStatusFailed:
             {
                 NSError *exportError = exporter.error;
                 NSLog (@"AVAssetExportSessionStatusFailed: %@", exportError);
                 break;
             }
             case AVAssetExportSessionStatusCompleted:
             {
                 NSLog (@"AVAssetExportSessionStatusCompleted");

                 self.selectedMusicItem.localFileURL = exportURL;

                 break;
             }
             case AVAssetExportSessionStatusUnknown:
             {
                 NSLog (@"AVAssetExportSessionStatusUnknown"); break;
             }
             case AVAssetExportSessionStatusExporting:
             {
                 NSLog (@"AVAssetExportSessionStatusExporting"); break;
             }
             case AVAssetExportSessionStatusCancelled:
             {
                 NSLog (@"AVAssetExportSessionStatusCancelled"); break;
             }
             case AVAssetExportSessionStatusWaiting:
             {
                 NSLog (@"AVAssetExportSessionStatusWaiting"); break;
             }
             default:
             {
                 NSLog (@"didn't get export status"); break;
             }
         }
         
         dispatch_semaphore_signal(semaphor);

     }];
    
    dispatch_semaphore_wait(semaphor, DISPATCH_TIME_FOREVER);


}

#pragma mark - BGViewButtonCarouselDelegate

- (void)buttonTappedAtIndex:(NSInteger)index {
    [self scrollUIScrollView:self.scrollView toPage:index];
    [self.musicPlayer pause];
    [self.searchMusicView pausePlayer];
    [self.musicLibraryView pausePlayer];

    for (BGViewFeaturedArtist *view in self.featuredArtistViews) {
        [view pausePlayer];
    }
    
    CATransition *fadeAnimation = [CATransition animation];
    fadeAnimation.duration = 0.3;
    fadeAnimation.type = kCATransitionFade;
    
    [self.navigationController.navigationBar.layer addAnimation: fadeAnimation forKey: @"fadeText"];

    if (index == [self.allArtists count]) {
        // show search bar
        self.navigationItem.titleView = self.searchBar;
    } else {
        // hide search bar
        self.navigationItem.titleView = nil;
    }
}

- (NSInteger)numberOfButtonsInCarousel:(iCarousel *)carousel {
    return [self.allArtists count] + 1;    // +1 for My Music
}

- (NSString *)titleForButtonInCarousel:(iCarousel *)carousel atIndex:(NSInteger)index {
    
    if (index < self.allArtists.count) {
        return [self.allArtists objectAtIndex:index];
    }
    
    return @"My Music";
}

#pragma mark - BGItunesMusicParserDelegate


- (void)parserDidFinishParsingDocument {
    _finishedParsingItunes = YES;
}


#pragma mark - HysteriaPlayerDataSource


//- (NSInteger)hysteriaPlayerNumberOfItems {
//    return [self.songParser.musicItems count];
//}
//
//- (NSURL *)hysteriaPlayerURLForItemAtIndex:(NSInteger)index preBuffer:(BOOL)preBuffer {
//    return [[self.songParser.musicItems objectAtIndex:index] previewURL];
//
//}

- (void)hysteriaPlayerCurrentItemChanged:(AVPlayerItem *)item {
    [self.musicPlayer play];
    _didSelectItem = NO;
}


#pragma mark - BGViewSearchMusicDelegate

- (void)BGViewSearchMusicDidSelectMusicItem:(MusicItem *)item {
    
    [FIRAnalytics logEventWithName:@"music_previewed"
                        parameters:@{
                                     @"user":[NSString stringWithFormat:@"USER_ID_%@", [AppData sharedInstance].localUser.theId],
                                     @"title":[self.selectedMusicItem title],
                                     @"artist":[self.selectedMusicItem artist],
                                     kFIRParameterContentType:@"audio"
                                     }];
    
    self.selectedMusicItem = item;
}

#pragma mark - UISearchBarDelegate


- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {

}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    return YES;
}

#pragma mark - BGViewMyMusicLibraryDelegate

- (void)BGViewMyMusicLibraryDidSelectMusicItem:(MusicItem *)item {
    
    self.selectedMusicItem = item;

    NSString *userID = [AppData sharedInstance].localUser.theId ? [AppData sharedInstance].localUser.theId : @"Unknown";
    NSString *songTitle = [self.selectedMusicItem title] ? [self.selectedMusicItem title] : @"Unknown";
    NSString *artist = [self.selectedMusicItem artist] ? [self.selectedMusicItem artist] : @"Unknown";

    [FIRAnalytics logEventWithName:@"music_previewed"
                        parameters:@{
                                     @"user":userID,
                                     @"title":songTitle,
                                     @"artist":artist,
                                     kFIRParameterContentType:@"audio"
                                     }];
}

- (void)BGViewFeaturedArtistDidSelectMusicItem:(MusicItem *)item {
    
    self.selectedMusicItem = item;

    [FIRAnalytics logEventWithName:@"music_previewed"
                        parameters:@{
                                     @"user":[NSString stringWithFormat:@"USER_ID_%@", [AppData sharedInstance].localUser.theId],
                                     @"title":[self.selectedMusicItem title],
                                     @"artist":[self.selectedMusicItem artist],
                                     kFIRParameterContentType:@"audio"
                                     }];
}

# pragma mark - ILRemoteSearchBarDelegate

- (void)remoteSearchBar:(ILRemoteSearchBar *)searchBar
          textDidChange:(NSString *)searchText
{
    [self.musicLibraryView searchForContentWithKeyword:searchText];
    
}

#pragma mark Notifications

- (void)notificationWindowHitTest:(NSNotification *)notification {
    UIView *touchedView = [notification object];
    
    if ([self.searchBar isFirstResponder] && touchedView != self.searchBar) {
        [self.searchBar resignFirstResponder];
    }
}

/// Tells the delegate an ad request loaded an ad.
- (void)adViewDidReceiveAd:(GADBannerView *)adView {
    NSLog(@"adViewDidReceiveAd");
    [self addBannerViewToView:self.bannerView];
}

/// Tells the delegate an ad request failed.
- (void)adView:(GADBannerView *)adView
didFailToReceiveAdWithError:(GADRequestError *)error {
    NSLog(@"adView:didFailToReceiveAdWithError: %@", [error localizedDescription]);
}

/// Tells the delegate that a full-screen view will be presented in response
/// to the user clicking on an ad.
- (void)adViewWillPresentScreen:(GADBannerView *)adView {
    NSLog(@"adViewWillPresentScreen");
}

/// Tells the delegate that the full-screen view will be dismissed.
- (void)adViewWillDismissScreen:(GADBannerView *)adView {
    NSLog(@"adViewWillDismissScreen");
}

/// Tells the delegate that the full-screen view has been dismissed.
- (void)adViewDidDismissScreen:(GADBannerView *)adView {
    NSLog(@"adViewDidDismissScreen");
}

/// Tells the delegate that a user click will open another app (such as
/// the App Store), backgrounding the current app.
- (void)adViewWillLeaveApplication:(GADBannerView *)adView {
    NSLog(@"adViewWillLeaveApplication");
}

@end
