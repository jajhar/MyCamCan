#import "BGController_Inherit.h"
#import "BGControllerMediaPicker.h"
#import "BGViewBanner.h"
#import "Media.h"
#import "GMImagePickerController.h"
#import "MBProgressHUD.h"

NSString *kBGControllerMediaPicker = @"BGControllerMediaPicker";

NSString *kBGKeyMediaPickerDelegate = @"BGKeyMediaPickerDelegate";

NSString *kBGKeyMediaPickerMaxSelection = @"BGKeyMediaPickerMaxSelection";

@interface BGControllerMediaPicker ()

//L1

@property (assign, nonatomic) BGMediaTypes mediaTypes;

@property (strong, nonatomic) GMImagePickerController *ios8PickerController;

@property (nonatomic) NSUInteger maxSelection;

@end

@implementation BGControllerMediaPicker

#pragma mark L1

- (void)setMediaTypes:(BGMediaTypes)mediaTypes {
    if (_mediaTypes != mediaTypes) {
        _mediaTypes = mediaTypes;
        
        self.canBePresented = (_mediaTypes != 0);
        
        NSMutableArray *allowediOS8Types = [NSMutableArray new];
        
        switch(_mediaTypes)
        {
            case kVXMediaTypeAll:
                [allowediOS8Types addObject:[NSNumber numberWithInteger:PHAssetMediaTypeImage]];
                [allowediOS8Types addObject:[NSNumber numberWithInteger:PHAssetMediaTypeVideo]];
                
                break;
            case kVXMediaTypePhoto:
                [allowediOS8Types addObject:[NSNumber numberWithInteger:PHAssetMediaTypeImage]];
                
                break;
            case kVXMediaTypeVideo:
                [allowediOS8Types addObject:[NSNumber numberWithInteger:PHAssetMediaTypeVideo]];
                
                break;
            case kVXMediaTypeNone:
                // return since no allowed media types specified
                return;
                
            default:
                [allowediOS8Types addObject:[NSNumber numberWithInteger:PHAssetMediaTypeImage]];
                [allowediOS8Types addObject:[NSNumber numberWithInteger:PHAssetMediaTypeVideo]];
                
                break;
        }
        
        self.ios8PickerController.allowedTypes = allowediOS8Types;
        
    }
}


#pragma mark - Inherited

#pragma mark UIViewController
/**
 * This method is called to create a view for ELCImagePickerController.
 
 
 @since  01-28-2015
 @author Stix
 
 Modified to select the correct controller for the iOS version.  If iOS8_and_higher, use new
 GMImagePickerController; otherwise use ECL picker controller.
 
 */
- (void)loadView {
    [super loadView];
    UIView *pickerView;
    

        pickerView = self.ios8PickerController.view;
        pickerView.frame = self.view.bounds;
        pickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addChildViewController:self.ios8PickerController];
        [self.view addSubview:pickerView];
        [self.ios8PickerController didMoveToParentViewController:self];
        
        
}

-(void)dismissPickerController {
    
        [self.ios8PickerController willMoveToParentViewController:nil];
        [self.ios8PickerController.view removeFromSuperview];
        [self.ios8PickerController removeFromParentViewController];
    
}

#pragma mark BGController
/**
 * This method is called to initialize the ELCImagePickerController to pick only 5 images,dispaly & return images in order, return the fullScreenImage.
 
 @since  01-28-2015
 @author Stix
 
 Modified to instantiate the correct picker controller.
 
 Summary of modifications:
 
 - Check for iOS 8.  If isOperatingSystemAtLeastVersion: method eists, it's iOS 8
 - Allocate & intialize correct picker controller
 - Set picker configurations
 - Add picker to self.
 
 */
- (void)commonInit {
    [super commonInit];
    
    // initialize the iOS8 and above picker controller
    self.ios8PickerController = [[GMImagePickerController alloc] init];
    self.ios8PickerController.delegate = self;
    //Display or not the selection info Toolbar:
    self.ios8PickerController.displaySelectionInfoToolbar = NO;
    
    //Display or not the number of assets in each album:
    self.ios8PickerController.displayAlbumsNumberOfAssets = YES;
    
    //Customize the picker title and prompt (helper message over the title)
    self.ios8PickerController.title = @"Select Album";
    self.ios8PickerController.customNavigationBarPrompt = nil;
    
    //Customize the number of cols depending on orientation and the inter-item spacing
    self.ios8PickerController.colsInPortrait = 3;
    self.ios8PickerController.colsInLandscape = 5;
    self.ios8PickerController.minimumInteritemSpacing = 2.0;
    self.ios8PickerController.maxSelectionCount = 1;
    //Define the smart collections we want to show:
    NSArray *_customSmartCollections = @[@(PHAssetCollectionSubtypeSmartAlbumFavorites),
                                         //@(PHAssetCollectionSubtypeSmartAlbumRecentlyAdded),
                                         @(PHAssetCollectionSubtypeSmartAlbumVideos),
                                         @(PHAssetCollectionSubtypeSmartAlbumSlomoVideos),
                                         @(PHAssetCollectionSubtypeSmartAlbumTimelapses),
                                         @(PHAssetCollectionSubtypeSmartAlbumBursts),
                                         @(PHAssetCollectionSubtypeAlbumMyPhotoStream),
                                         @(PHAssetCollectionSubtypeAlbumImported),
                                         @(PHAssetCollectionSubtypeAlbumSyncedEvent),
                                         @(PHAssetCollectionSubtypeAlbumRegular),
                                         @(PHAssetCollectionSubtypeSmartAlbumPanoramas)];
    
    self.ios8PickerController.customSmartCollections = _customSmartCollections;
    
    [self addChildViewController:self.ios8PickerController];
}

- (void)setInfo:(NSDictionary *)info animated:(BOOL)animated {
    [super setInfo:info animated:animated];
    
    self.ios8PickerController.maxSelectionCount = 1;
    
    self.delegate = [info objectForKey:kBGKeyMediaPickerDelegate];
    
    self.mediaTypes = kVXMediaTypePhoto;
}

#pragma mark - Protocols


#pragma mark GMImagePickerControllerDelegate

/**
 
 Delegate method called by GMImagePicker when the user has finished picking images.
 
 @param  (GMImagePickerController*)picker    The controller calling this method.
 @param  (NSArray*)assetARRAY    An array of PHAsset objecs for the selected media
 
 @since  01-28-2015
 @author Stix
 
 This method iterates of the array and creates Media objects using the PHAsset and then adds
 this to an array of Media objects.  At completion, this array of media objects is passed back
 via the saved callback and the picker is dismissed.
 
 */
- (void)assetsPickerController:(GMImagePickerController *)picker didFinishPickingAssets:(NSArray *)assetArray
{
    
    __block BOOL uploadingAny = NO;
    __block NSMutableArray *medias = [NSMutableArray new];
    //    [self dismissPickerController];
    
    MBProgressHUD *loadingIndicator = [[MBProgressHUD alloc] initWithView:self.ios8PickerController.view];
    loadingIndicator.color = [UIColor blackColor];
    loadingIndicator.opacity = 1.0f;
    loadingIndicator.userInteractionEnabled = NO;
    loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.ios8PickerController.view addSubview:loadingIndicator];
    
    [loadingIndicator show:YES];
    
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        for (PHAsset *asset in assetArray) {
            
            Media *media = [Media mediaWithPHAsset:asset];
            
            if (media != nil) {
                [medias addObject:media];
                uploadingAny = YES;
            }
            
        }
        
        MBProgressHUD *loadingIndicator = [[MBProgressHUD alloc] initWithView:self.ios8PickerController.view];
        loadingIndicator.color = [UIColor blackColor];
        loadingIndicator.opacity = 1.0f;
        loadingIndicator.userInteractionEnabled = NO;
        loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.ios8PickerController.view addSubview:loadingIndicator];
        
        [loadingIndicator show:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [loadingIndicator hide:YES];
            
            if (uploadingAny) {
                
                [self.delegate mediaPicker:self didFinishPickingMedia:medias];
                
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                    message:@"Could not access selected media"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"Close"
                                                          otherButtonTitles:nil];
                [alertView show];
            }
            
            NSLog(@"GMImagePicker: User ended picking assets. Number of selected items is: %lu", (unsigned long)assetArray.count);
            
        });
        
    });
    
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"postMedia" object:self];
    
    
    //TO-DO: post notification to base controller to notify post controller
}


/**
 
 Delegate method called by GMImagePicker when the user cancels media selection.
 
 @param  (GMImagePickerController*)picker    The controller calling this method.
 
 @since  01-28-2015
 @author Stix
 
 This method simply sets the callback data parameter to nil and executes the callback.
 
 */
-(void)assetsPickerControllerDidCancel:(GMImagePickerController *)picker
{
    NSLog(@"GMImagePicker: User pressed cancel button");
    [self.delegate mediaPicker:self didFinishPickingMedia:nil];
    
}


@end
