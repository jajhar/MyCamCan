#import "VX_Requests.h"

@protocol VX_HasOwner <NSObject>
@required

//Element's owner to send requests to
@property (weak, nonatomic) id<VX_Requests> owner;

@end
