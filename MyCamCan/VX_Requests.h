#import <Foundation/Foundation.h>

@class VXController;

//Requests' purpose constants
typedef NS_ENUM(NSUInteger, VXPurpose) {
    kVXPurposeAppStart,
    kVXPurposeLogin,
    kVXPurposeTutorial,
    kVXPurposeFeed,
    kVXPurposeCapsules,
    kVXPurposeNotifications,
    kVXPurposeProfile,
    kVXPurposeProfileDetails,
    kVXPurposeProfileEdit,
    kVXPurposePeople,
    kVXPurposeSearch,
    kVXPurposeAccount,
    kVXPurposeWebBrowser,
    kVXPurposeRegister,
    kVXPurposeRecoverPassword,
    kVXPurposeCreateCapsule,
    kVXPurposeMedia,
    kVXPurposeMediaEdit,
    kVXPurposeMediaCreate,
    kVXPurposeMediaPick,
    kVXPurposeCapsule,
    kVXPurposeCapsuleEdit,
    kVXPurposeShareVixlet,
    kVXPurposeUploads,
    kVXPurposeImageEdit,
    kVXPurposeChooseUsername,
    kVXPurposeCamera
};

//Keys to use in info dictionary with kVXPurposeAppStart
//Use this key to supply window you want Vixlet to show on
extern NSString *kVXKeyContainerWindow;
//Use this key to supply view you want Vixlet to show on
extern NSString *kVXKeyContainerView;
//If both keys are supplied, kVXKeyContainerView will be used
//If no info supplied, Vixlet will create its own window and use it do display itself over app content

//Protocol for requesting VXControllers and VXVixlet
//If VXController cannot perform request it is expected to pass it to owner
@protocol VX_Requests <NSObject>
@required

- (NSString *)controllerIdForPurpose:(VXPurpose)purpose;

- (VXController *)controllerForId:(NSString *)controllerId;

- (VXController *)presentControllerForPurpose:(VXPurpose)purpose animated:(BOOL)animated fromRight:(BOOL)animationFromRight info:(NSDictionary *)info;
- (void)dismissController:(VXController *)controller animated:(BOOL)animated info:(NSDictionary *)info;

@end
