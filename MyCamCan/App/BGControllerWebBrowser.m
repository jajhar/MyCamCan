
#import "BGControllerWebBrowser.h"

@interface BGControllerWebBrowser () <UIWebViewDelegate> 

@property BOOL webviewIsLoading; // NOTE: this variable is manually updated because the UIWebView's own isLoading property is notoriously unreliable

@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (strong, nonatomic) IBOutlet UIToolbar *bottomToolbar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *forwardButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *stopButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end


@implementation BGControllerWebBrowser


#pragma mark - L1



#pragma mark - Inherited


#pragma mark UIViewController

/**
* This method is called to load the given url in web view.
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.backButton.enabled = NO;
    self.forwardButton.enabled = NO;
    self.refreshButton.enabled = NO;
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.navigationItem.title = _startURL.absoluteString;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(webViewHistoryDidChange:)
                                                 name:@"WebHistoryItemChangedNotification"
                                               object:nil];
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)webViewHistoryDidChange:(NSNotification*)notification{
    
    [self setButtonEnabledStates];
    
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.webView.delegate = self;
    
    [self.webView setMediaPlaybackRequiresUserAction:NO];
    [self.webView setAllowsInlineMediaPlayback:NO];
    self.webView.scrollView.bounces = NO;
    
    if (_startURL != nil )
    {
        self.webView.allowsInlineMediaPlayback = NO;
        self.webView.mediaPlaybackRequiresUserAction = NO;
        
        NSURLRequest * request = [[NSURLRequest alloc] initWithURL:_startURL];
        [self.webView loadRequest:request];
        
    }
}


#pragma mark BGController

- (void)setInfo:(NSDictionary *)info animated:(BOOL)animated {
    [super setInfo:info animated:animated];
    
    _startURL = [info objectForKey:kBGKeyURL];
    
}

#pragma mark - Interface Actions

- (IBAction)backPressed:(id)sender {
    [self.webView goBack];
    [self setButtonEnabledStates];
}

- (IBAction)forwardPressed:(id)sender {
    [self.webView goForward];
}

- (IBAction)refreshPressed:(id)sender {
    [self.webView reload];
}

- (IBAction)stopPressed:(id)sender {
    [self.webView stopLoading];
}

#pragma mark Helper Methods

- (void) setButtonEnabledStates
{
    //self.buttonBack.enabled = self.webView.canGoBack;
    
    
    NSString *actualURL = self.webView.request.URL.absoluteString;
    
    actualURL = [actualURL stringByReplacingOccurrencesOfString:@"https"
                                                     withString:@"http"];
    
    if([actualURL isEqualToString:_startURL.absoluteString] || (self.webView.request.URL.absoluteString == nil))
    {
        self.backButton.enabled = NO;
    }
    else
    {
        self.backButton.enabled = self.webView.canGoBack;
    }
    
    
    self.forwardButton.enabled = self.webView.canGoForward;
    self.refreshButton.enabled = !self.webviewIsLoading;
    self.stopButton.enabled = self.webviewIsLoading;
    
}

/**
 Shows and hides the Refresh and Stop buttons based on the current state of the WebView
 */
- (void) setRefreshAndStopButtonStates
{
    NSMutableArray * ourToolbarItems = [self.bottomToolbar.items mutableCopy];
    
    if ( ourToolbarItems != nil )
    {
        // replace both of the buttons (yes, weird, but there is no better way to show/hide them while in a toolbar)
        
        [ourToolbarItems removeObject:self.refreshButton];
        [ourToolbarItems removeObject:self.stopButton];
        
        if ( self.webviewIsLoading )
        {
            [ourToolbarItems addObject:self.stopButton];
        }
        else
        {
            [ourToolbarItems addObject:self.refreshButton];
        }
        
        [self.bottomToolbar setItems:ourToolbarItems];
    }
}

#pragma mark UIWebViewDelegate impl

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {

    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
    self.webviewIsLoading = YES; // NOTE: this variable is manually updated because the UIWebView's own isLoading property is notoriously unreliable
    
    [self.activityIndicator setHidden:NO];
    [self.activityIndicator startAnimating];
    
    [self setRefreshAndStopButtonStates];
    
    [self setButtonEnabledStates];
    
    
}

- (void) webViewDidFinishLoad:(UIWebView *)webView
{
    self.webviewIsLoading = NO; // NOTE: this variable is manually updated because the UIWebView's own isLoading property is notoriously unreliable
    
    [self setButtonEnabledStates];
    
    [self.activityIndicator stopAnimating];
    
    [self setRefreshAndStopButtonStates];
}

@end
