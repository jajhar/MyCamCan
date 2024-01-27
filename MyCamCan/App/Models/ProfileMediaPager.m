

#import "ProfileMediaPager.h"
#import "Pager_Inherit.h"
#import "AppData.h"
#import "AppData_ModelInternal.h"
#import "Media.h"


@interface ProfileMediaPager ()
{
    NSMutableDictionary *_elementsDict;
    NSMutableDictionary *_nextPageDateOffsets;
    NSMutableDictionary *_endOfPagesDict;
}

@end


@implementation ProfileMediaPager


#pragma mark - Initialization


+ (ProfileMediaPager *)ProfileMediaPagerForUser:(User *)user {
    return [[ProfileMediaPager alloc] initForUser:user];
}


- (id)initForUser:(User *)user {
    self = [super init];
    if (self) {
        _user = user;
        _nextPageDateOffset = @"";
    }
    return self;
}


#pragma mark - Inherit


- (void)makeGetRequestWithLimit:(NSUInteger)limit completion:(void (^)(NSArray *, NSInteger, NSString *, NSError *, NSDictionary *))completionBlock {
    
    [[AppData sharedInstance] getMediaForUser:self.user
                               withDateOffset:_nextPageDateOffset
                                       callback:^(NSArray *newElements, NSInteger newTotalCount, NSString *nextPage, NSError *error) {
                                           completionBlock(newElements, newTotalCount, nextPage, error, nil);
                                       }];
}


- (NSUInteger)parseGetServerResponseWithElements:(NSArray *)newElements nextPage:(NSString *)nextPage info:(NSDictionary *)info {
    
    NSInteger oldCount = _elements.count;
    
    if (newElements.count == 0) {
        // server has no more data
        [self markEndOfPages];
        [self sendNotificationChangedWithTotalFlag:NO];
        
    } else {
        
        _nextPageDateOffset = [[newElements lastObject] createdAt];

        // add parsed elements to list
        [_elements addObjectsFromArray:newElements];
        
        if(oldCount == 0) {
            [self sendNotificationChangedWithTotalFlag:YES];
        } else {
            [self sendNotificationChangedWithTotalFlag:NO];
        }
    }
    
    return newElements.count;
}

- (void)clearStateAndElements {
    [super clearStateAndElements];
}

- (void)sendNotificationChangedWithTotalFlag:(BOOL)total {
    [[AppData sharedInstance] sendPagerNotification:kAppData_Notification_ProfileMediaChanged
                                              total:total
                                               user:self.user
                                              media:nil];
}


@end
