#import "BGController.h"

@class BGControllerMediaPicker;


extern NSString *kBGControllerMediaPicker;

// Keys
extern NSString *kBGKeyMediaPickerMaxSelection;
extern NSString *kBGKeyMediaPickerDelegate;


@protocol BGMediaPickerDelegate <NSObject>

@required

- (void)mediaPicker:(BGController *)picker didFinishPickingMedia:(NSArray *)media;

@end



@interface BGControllerMediaPicker : BGController

@property (nonatomic, assign) id delegate;


@end
