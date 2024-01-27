#import "BGViewBase.h"
#import "BGView_Inherit.h"
#import "BGViewNavigation.h"
#import "BGViewTouchless.h"
#import "BGViewBanner.h"

@interface BGViewBase ()

//L0

- (id)initWithHeaderView:(BGViewNavigation *)headerView
              bannerView:(BGViewBanner *)bannerView
          navigationView:(UIView *)navigationView;


- (void)fullscreenNavigation:(BOOL)fullscreen animated:(BOOL)aniamted;

//L1

@property (strong, nonatomic) BGViewNavigation *headerView;
@property (strong, nonatomic) BGViewBanner *bannerView;
@property (strong, nonatomic) UIView *navigationView;
@property (strong, nonatomic) UIView *clipOverlay;

@property (assign, nonatomic) BOOL fullscreenNavigation;

@end

@implementation BGViewBase

#pragma mark L0

- (id)initWithHeaderView:(BGViewNavigation *)headerView bannerView:(BGViewBanner *)bannerView navigationView:(UIView *)navigationView
{
    if ((self = [super initWithFrame:CGRectZero]) != nil) {
        [self commonInit];

        //clip menus which may slide off this view so they won't overlap anything else
        self.headerView = headerView;
        self.bannerView = bannerView;
        
        [self.clipOverlay addSubview:self.headerView];
        [self.clipOverlay addSubview:self.bannerView];
        
        self.navigationView = navigationView;
        [self insertSubview:self.navigationView belowSubview:self.clipOverlay];
        [self bringSubviewToFront:self.clipOverlay];

    }
    return self;
}

- (void)fullscreenNavigation:(BOOL)fullscreen animated:(BOOL)aniamted {
    if (self.fullscreenNavigation != fullscreen) {
        self.fullscreenNavigation = fullscreen;

        void (^actionBlock)(void) = ^{
            [self setNeedsLayout];
            [self layoutIfNeeded];
        };

        void (^completionBlock)(BOOL finished) = ^(BOOL finished){

        };

        if (aniamted) {
            [UIView animateWithDuration:0.25
                             animations:actionBlock
                             completion:completionBlock];
        } else {
            actionBlock();
            completionBlock(YES);
        }
    }
}

#pragma mark L1

@synthesize fullscreenNavigation = _fullscreenNavigation;

#pragma mark - Inherited

#pragma mark UIView

- (void)layoutSubviews {
    CGRect frame = self.bounds;
    
    // Clip overlay
    self.clipOverlay.frame = frame;
    
    // Header
    CGRect headerFrame = frame;
    if (self.fullscreenNavigation) {
        headerFrame.origin.y = CGRectGetMaxY(frame);
    } else {
        headerFrame.origin.y = CGRectGetMaxY(frame) - kBGViewHeaderHeight;
    }
    headerFrame.size.height = kBGViewHeaderHeight;
    self.headerView.frame = headerFrame;
    
    // Banner
    CGRect bannerFrame = frame;
    if (self.fullscreenNavigation) {
        bannerFrame.origin.y = -kBGViewBannerHeight;
    } else {
        bannerFrame.origin.y = 0;
    }
    bannerFrame.size.height = kBGViewBannerHeight;
    self.bannerView.frame = bannerFrame;
    
    // Navigation
    CGRect navigationFrame = frame;
    if (self.fullscreenNavigation) {
        //that's it, navigation will take all parent's frame
        [self hideHeaderView];
    } else {
        [self showHeaderView];
        navigationFrame.origin.y = 0.0;//CGRectGetMaxY(bannerFrame);
        navigationFrame.size.height = CGRectGetMinY(headerFrame) - CGRectGetMaxY(bannerFrame);
//        navigationFrame.size.height = CGRectGetMaxY(self.frame) - kBGViewHeaderHeight;
        
        NSLog(@"here: %f", CGRectGetMinY(headerFrame));
    }
    self.navigationView.frame = navigationFrame;

}

- (void)hideHeaderView {
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.headerView.alpha = 0.0;
                     }];
}

- (void)showHeaderView {
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.headerView.alpha = 1.0;
                     }];
}

#pragma mark BGView

- (void)setOwner:(id<BG_Requests>)owner {
    [super setOwner:owner];
    //self.headerView.owner = self.owner;
}

#pragma mark - Protocol

#pragma mark BGView_Inherit

- (void)commonInit {
    [super commonInit];

    BGViewTouchless *clipOverlay = [BGViewTouchless new];
    clipOverlay.opaque = NO;
    clipOverlay.backgroundColor = [UIColor clearColor];
    clipOverlay.clipsToBounds = YES;
    clipOverlay.frame = self.bounds;
    self.clipOverlay = clipOverlay;
    [self addSubview:self.clipOverlay];
    _fullscreenNavigation = NO; // as of now - slider is visible (has nonzero alpha)
}

@end
