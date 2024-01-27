

#import "SearchPager.h"
#import "Pager_Inherit.h"
#import "AppData.h"
#import "AppData_ModelInternal.h"
#import "Media.h"

@interface SearchPager ()
{
    NSMutableDictionary *_elementsDict;
    NSMutableDictionary *_nextPageDateOffsets;
    NSMutableDictionary *_endOfPagesDict;
    NSInteger _currentPhoneIndex;

}

@end


@implementation SearchPager


#pragma mark - Initialization


+ (SearchPager *)searchPager {
    return [[SearchPager alloc] init];
}


- (instancetype)init {
    self = [super init];
    if (self) {
        _nextPageDateOffset = @"";
        _filter = kBGSearchFilterPhotoFriends;
        _currentPhoneIndex = 0;
        
        _elementsDict = [NSMutableDictionary dictionary];
        _nextPageDateOffsets = [NSMutableDictionary dictionary];
        _endOfPagesDict = [NSMutableDictionary dictionary];
        
        [_elementsDict setObject:[NSMutableArray new] forKey:[NSNumber numberWithUnsignedInteger:kBGSearchFilterPhotoFriends]];
        [_elementsDict setObject:[NSMutableArray new] forKey:[NSNumber numberWithUnsignedInteger:kBGSearchFilterTop]];
        [_elementsDict setObject:[NSMutableArray new] forKey:[NSNumber numberWithUnsignedInteger:kBGSearchFilterLocal]];
        [_elementsDict setObject:[NSMutableArray new] forKey:[NSNumber numberWithUnsignedInteger:kBGSearchFilterAll]];

        [_endOfPagesDict setObject:[NSNumber numberWithBool:NO] forKey:[NSNumber numberWithUnsignedInteger:kBGSearchFilterPhotoFriends]];
        [_endOfPagesDict setObject:[NSNumber numberWithBool:NO] forKey:[NSNumber numberWithUnsignedInteger:kBGSearchFilterTop]];
        [_endOfPagesDict setObject:[NSNumber numberWithBool:NO] forKey:[NSNumber numberWithUnsignedInteger:kBGSearchFilterLocal]];
        [_endOfPagesDict setObject:[NSNumber numberWithBool:NO] forKey:[NSNumber numberWithUnsignedInteger:kBGSearchFilterAll]];
        
    }
    
    return self;
}

#pragma mark - Accessors


- (Media *)mediaElementAtIndex:(NSUInteger)index {
    return (Media *)[[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:_filter]] objectAtIndex:index];
}


#pragma mark - Inherit


- (void)makeGetRequestWithLimit:(NSUInteger)limit completion:(void (^)(NSArray *, NSInteger, NSString *, NSError *, NSDictionary *))completionBlock {
    __block BGSearchFilterType searchFilter = self.filter;
    
    switch (searchFilter) {
        case kBGSearchFilterPhotoFriends:
        {
            
            NSMutableArray *numbers = [NSMutableArray new];
            
            NSInteger total = MIN(self.phoneNumbers.count, (_currentPhoneIndex+10));
            
            for (NSInteger i = _currentPhoneIndex; i < total; i++) {
                
                [numbers addObject:[self.phoneNumbers objectAtIndex:i]];
                _currentPhoneIndex++;
            }
            
        
            [[AppData sharedInstance] searchUsersWithPhoneNumbers:numbers
                                                         callback:^(NSArray *newElements, NSInteger newTotalCount, NSString *nextPage, NSError *error) {
                completionBlock(newElements,
                                newTotalCount,
                                nextPage,
                                error,
                                @{@"searchFilter": [NSNumber numberWithInteger:searchFilter]});

            }];
            
            break;
        }
            
        case kBGSearchFilterAll:
        {
            [[AppData sharedInstance] searchUsersWithKeyword:_keyword
                                                    callback:^(NSArray *newElements, NSInteger newTotalCount, NSString *nextPage, NSError *error) {
                                                        completionBlock(newElements, newTotalCount, nextPage, error, @{@"searchFilter": [NSNumber numberWithInteger:searchFilter]});
                                                    }];
            break;

        }
        default:
            break;
    }
    
}


- (NSUInteger)parseGetServerResponseWithElements:(NSArray *)newElements nextPage:(NSString *)nextPage info:(NSDictionary *)info{
    
    BGSearchFilterType filter = [info objectForKey:@"searchFilter"] ? [[info objectForKey:@"searchFilter"] integerValue] : _filter;
    
    // always mark end of pages
    [self markEndOfPagesForFilter:filter];
    [self markEndOfPages];

    if (newElements.count == 0) {
        // server has no more data
        [self markEndOfPagesForFilter:filter];
        [self sendNotificationChangedWithTotalFlag:YES];
        
    } else {
        // add parsed elements to list
        
        NSMutableArray *curElements = [_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:filter]];
        NSInteger oldCount = curElements.count;
        
        for(User *user in newElements) {
            if(![curElements containsObject:user]) {
                [curElements addObject:user];
            }
        }
        [_elementsDict setObject:curElements
                          forKey:[NSNumber numberWithUnsignedInteger:filter]];
        
        // save next page offset
        if(nextPage != nil && nextPage.length > 0) {
            [_nextPageDateOffsets setObject:nextPage
                                     forKey:[NSNumber numberWithUnsignedInteger:filter]];
        } else {
            
            [self markEndOfPagesForFilter:filter];
            
            if(oldCount != 0) {
                [self sendNotificationChangedWithTotalFlag:NO];
            }
        }
        
        if(oldCount == 0 || !self.isEndOfPages) {
            [self sendNotificationChangedWithTotalFlag:YES];
        }
    }
    
    return newElements.count;
}


- (void)sendNotificationChangedWithTotalFlag:(BOOL)total {
    [[AppData sharedInstance] sendPagerNotification:kAppData_Notification_Pager_Search
                                                 total:total
                                                  user:nil
                                                 media:nil];
}


#pragma mark - Overloading

- (void)markEndOfPagesForFilter:(BGSearchFilterType)filter {
    [_endOfPagesDict setObject:[NSNumber numberWithBool:YES] forKey:[NSNumber numberWithUnsignedInteger:filter]];
}

- (void)markEndOfPages {
    [_endOfPagesDict setObject:[NSNumber numberWithBool:YES] forKey:[NSNumber numberWithUnsignedInteger:_filter]];
    //[super markEndOfPages];
}

- (BOOL)isEndOfPages {
    return [[_endOfPagesDict objectForKey:[NSNumber numberWithUnsignedInteger:_filter]] boolValue];
}

- (void)insertElement:(id)element atIndex:(NSUInteger)index {
    
    if(element == nil) {
        NSLog(@"%s : Attempted to insert nil element", __PRETTY_FUNCTION__);
        return;
    }
    
    NSMutableArray *curElements = [_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:_filter]];
    [curElements insertObject:element atIndex:index];
    [_elementsDict setObject:curElements forKey:[NSNumber numberWithUnsignedInteger:_filter]];
    //    _totalElementsCount++;
}

- (id)elementAtIndex:(NSUInteger)index {
    return [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:_filter]] objectAtIndex:index];
}

- (void)addElement:(id)element {
    [self insertElement:element atIndex:[[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:_filter]] count]];
}

- (NSUInteger)deleteElement:(id)element {
    NSUInteger curIndex = [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:_filter]] indexOfObject:element];
    
    NSUInteger tagIndex = [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:kBGSearchFilterPhotoFriends]] indexOfObject:element];
    NSUInteger defaultIndex = [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:kBGSearchFilterTop]] indexOfObject:element];
    NSUInteger profileIndex = [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:kBGSearchFilterLocal]] indexOfObject:element];
    
    if (tagIndex != NSNotFound) {
        [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:kBGSearchFilterPhotoFriends]] removeObjectAtIndex:tagIndex];
    }
    
    if (defaultIndex != NSNotFound) {
        [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:kBGSearchFilterTop]] removeObjectAtIndex:defaultIndex];
    }
    
    if (profileIndex != NSNotFound) {
        [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:kBGSearchFilterLocal]] removeObjectAtIndex:profileIndex];
    }
    
    return curIndex;
}


- (NSUInteger)deleteElementAtIndex:(NSUInteger)index {
    NSUInteger curIndex = [self deleteElement:[[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:_filter]] objectAtIndex:index]];
    return curIndex;
}

- (void)setFilter:(BGSearchFilterType)filter {
    _filter = filter;
}

- (NSArray *)elementsFromIndex:(NSUInteger)index count:(NSUInteger)count {
    NSRange range;
    if (index >= [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:_filter]] count]) {
        return nil;
    }
    range.location = index;
    range.length = MIN([[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:_filter]] count] - index, count);
    return [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:_filter]] subarrayWithRange:range];
}

- (NSUInteger)elementsCount {
    return [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:_filter]] count];
}

- (NSUInteger)indexOfElement:(id)element {
    return [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:_filter]] indexOfObject:element];
}

- (void)clearStateAndElements {
    [_nextPageDateOffsets setObject:@"" forKey:[NSNumber numberWithUnsignedInteger:_filter]];
    [_endOfPagesDict setObject:[NSNumber numberWithBool:NO] forKey:[NSNumber numberWithUnsignedInteger:_filter]];
    [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:_filter]] removeAllObjects];
    [_endOfPagesDict setObject:[NSNumber numberWithBool:NO] forKey:[NSNumber numberWithUnsignedInteger:_filter]];
    _currentPhoneIndex = 0;
    
    [super clearStateAndElements];
}

- (void)clearInherited {
    [_nextPageDateOffsets setObject:@"" forKey:[NSNumber numberWithUnsignedInteger:_filter]];
    [_endOfPagesDict setObject:[NSNumber numberWithBool:NO] forKey:[NSNumber numberWithUnsignedInteger:_filter]];
    _currentPhoneIndex = 0;

    [super clearInherited];
}

@end
