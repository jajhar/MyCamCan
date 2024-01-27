

#import "Pager.h"
#import "APICommunication.h"


typedef NS_ENUM(NSUInteger, BGSearchFilterType) {
    kBGSearchFilterPhotoFriends = 0,
    kBGSearchFilterTop          = 1,
    kBGSearchFilterLocal        = 2,
    kBGSearchFilterAll          = 3
};

@interface SearchPager : Pager

+ (SearchPager *)searchPager;

@property (nonatomic, assign) BGSearchFilterType filter;
@property (nonatomic, strong) NSString *keyword;
@property (nonatomic, strong) NSArray *phoneNumbers;

@end
