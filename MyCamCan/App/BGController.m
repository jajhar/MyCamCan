#import "BGController.h"
#import "BGControllerRegister.h"
#import "BGControllerSplash.h"
#import "BGControllerLogin.h"
#import "BGControllerContacts.h"
#import "BGControllerUpdatePassword.h"
#import "BGControllerRecoverPassword.h"
#import "BGControllerWebBrowser.h"

NSString *kVXKeyMedia = @"BGKeyMedia";
NSString *kVXKeyUser = @"BGKeyUser";

@interface BGController ()

@end

@implementation BGController

#pragma mark - Inherited

#pragma mark NSObject(UINibLoading)


#pragma mark UIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) != nil) {

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
 
    if(self.navigationController != [AppData sharedInstance].LoginNavigationController)
    {
        UIBarButtonItem *myBackButton = [[UIBarButtonItem alloc] initWithImage:nil
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:nil
                                                                        action:nil];
        [self navigationItem].backBarButtonItem = myBackButton;
        
        [self setCustomNavigationBackButton];

    }
}

- (void)setCustomNavigationBackButton
{
    UIImage *backBtn = [UIImage imageNamed:@"back-wht"];
    backBtn = [backBtn imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    self.navigationItem.backBarButtonItem.title=@"";
    self.navigationController.navigationBar.backIndicatorImage = backBtn;
    self.navigationController.navigationBar.backIndicatorTransitionMaskImage = backBtn;
}

#pragma mark - Protocols

#pragma mark BGController

- (void)setInfo:(NSDictionary *)info animated:(BOOL)animated {
    _info = info;
}

- (BOOL)hasInfoLike:(NSDictionary *)info {

    if(!_info && !info) {
        return YES;
    }
    
    return [_info isEqualToDictionary:info];
}

@end
