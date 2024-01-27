#import "VXView.h"

@protocol VXView_Inherit <VXView>

- (void)commonInit;

@end

@interface VXView () <VXView_Inherit>

@end
