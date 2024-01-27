

#import "Pager.h"
#import "APICommunication.h"


@interface ProfileMediaPager : Pager

+ (ProfileMediaPager *)ProfileMediaPagerForUser:(User *)user;

@property (weak, nonatomic) User *user;

@end
