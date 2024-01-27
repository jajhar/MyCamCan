#import "VXViewBase.h"
#import "VXView_Inherit.h"

#import "VXViewHeader.h"
#import "VXViewBanner.h"
#import "VXViewTouchless.h"

#import "Uploads.h"

@interface VXViewBase ()

//L0

- (id)initWithHeaderView:(VXViewHeader *)headerView
          navigationView:(UIView *)navigationView
              bannerView:(VXViewBanner *)bannerView;


- (void)fullscreenNavigation:(BOOL)fullscreen animated:(BOOL)aniamted;

//L1

@property (strong, nonatomic) VXViewHeader *headerView;
@property (strong, nonatomic) VXViewBanner *bannerView;
@property (strong, nonatomic) UIView *navigationView;
@property (strong, nonatomic) UIView *clipOverlay;

@property (assign, nonatomic) BOOL fullscreenNavigation;

@end

@implementation VXViewBase

#pragma mark L0

- (id)initWithHeaderView:(VXViewHeader *)headerView
          navigationView:(UIView *)navigationView
              bannerView:(VXViewBanner *)bannerView
            {
    if ((self = [super initWithFrame:CGRectZero]) != nil) {
        [self commonInit];

        //clip menus which may slide off this view so they won't overlap anything else
        self.bannerView = bannerView;
        [self.clipOverlay addSubview:self.bannerView ];
        self.headerView = headerView;
        [self.clipOverlay addSubview:self.headerView ];

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

@synthesize headerView = _headerView;
@synthesize navigationView = _navigationView;
@synthesize bannerView = _bannerView;
@synthesize clipOverlay = _clipOverlay;

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
        headerFrame.origin.y = CGRectGetMaxY(frame)-kVXViewHeaderHeight;
    }
    headerFrame.size.height = kVXViewHeaderHeight;
    self.headerView.frame = headerFrame;

    // Banner
    CGRect bannerFrame = frame;
    if (self.fullscreenNavigation) {
        bannerFrame.origin.y = -kVXViewBannerHeight;
    } else {
        bannerFrame.origin.y = 0;
    }
    bannerFrame.size.height = kVXViewBannerHeight;
    self.bannerView.frame = bannerFrame;

    // Navigation
    CGRect navigationFrame = frame;
    if (self.fullscreenNavigation) {
        //that's it, navigation will take all parent's frame
    } else {
        navigationFrame.origin.y = CGRectGetMaxY(bannerFrame);
        navigationFrame.size.height = CGRectGetMinY(headerFrame) - CGRectGetMaxY(bannerFrame);
    }
    self.navigationView.frame = navigationFrame;

  
}

#pragma mark VXView

- (void)setOwner:(id<VX_Requests>)owner {
    [super setOwner:owner];
    self.headerView.owner = self.owner;
   }

#pragma mark - Protocol

#pragma mark VXView_Inherit

- (void)commonInit {
    [super commonInit];

    VXViewTouchless *clipOverlay = [VXViewTouchless new];
    clipOverlay.opaque = NO;
    clipOverlay.backgroundColor = [UIColor clearColor];
    clipOverlay.clipsToBounds = YES;
    clipOverlay.frame = self.bounds;
    self.clipOverlay = clipOverlay;
    [self addSubview:self.clipOverlay];
    _fullscreenNavigation = NO; // as of now - slider is visible (has nonzero alpha)
}

@end
