

#import "Pager.h"
#import "APICommunication.h"


typedef NS_ENUM(NSUInteger, BGFeedFilterType) {
    kBGFeedFilterDefault      = 0,
    kBGFeedFilterProfile      = 1,
    kBGFeedFilterGlobal          = 2
};

@interface FeedPager : Pager

+ (FeedPager *)feedPager;

@property (nonatomic, assign) BGFeedFilterType filter;
@property (nonatomic, strong) NSString *tag;
@property (weak, nonatomic) User *user;

- (Media *)mediaElementAtIndex:(NSUInteger)index forFilter:(BGFeedFilterType)filter;
- (NSUInteger)elementsCountForFilter:(BGFeedFilterType)filterType;
- (BOOL)isEndOfPagesForFilter:(BGFeedFilterType)filterType;
- (id)elementAtIndex:(NSUInteger)index forFilter:(BGFeedFilterType)filterType;
- (void)addElement:(Media *)media toFilter:(BGFeedFilterType)filterType atIndex:(NSUInteger)index;
- (NSUInteger)indexOfElement:(id)element inFilter:(BGFeedFilterType)filterType;

@end
