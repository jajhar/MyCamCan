#import "BGControllerNavigation.h"

@interface BGControllerNavigation () <UINavigationControllerDelegate>


@end

@implementation BGControllerNavigation

#pragma mark L1

#pragma mark - Inherited

#pragma mark NSObject(UINibLoading)

- (void)awakeFromNib {
    [super awakeFromNib];

    [self commonInit];
}

#pragma mark UIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) != nil) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.delegate = self;
}

#pragma mark UINavigationController

- (instancetype)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass {
    if ((self = [super initWithNavigationBarClass:navigationBarClass toolbarClass:toolbarClass]) != nil) {
        [self commonInit];
    }
    return self;
}

- (id)initWithRootViewController:(UIViewController *)rootViewController {
    if ((self = [super initWithRootViewController:rootViewController]) != nil) {
        [self commonInit];
    }
    return self;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if(viewController.hidesBottomBarWhenPushed) {
        // full screen view controllers
        self.tabBarController.tabBar.hidden = YES;
    } else {
        self.tabBarController.tabBar.hidden = NO;
    }
}


@end
