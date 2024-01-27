

#import "FeedPager.h"
#import "Pager_Inherit.h"
#import "AppData.h"
#import "AppData_ModelInternal.h"
#import "Media.h"


@interface FeedPager ()
{
    NSInteger _offset;
}

@property (strong, nonatomic) NSMutableDictionary *elementsDict;
@property (strong, nonatomic) NSMutableDictionary *nextPageDateOffsets;
@property (strong, nonatomic) NSMutableDictionary *endOfPagesDict;

@end


@implementation FeedPager

@synthesize filter = _filter;
@synthesize tag = _tag;


#pragma mark - Initialization


+ (FeedPager *)feedPager {
    return [[FeedPager alloc] init];
}


- (instancetype)init {
    self = [super init];
    if (self) {
        _nextPageDateOffset = @"";
        _filter = kBGFeedFilterDefault;
        
        _offset = 0;
        
        _elementsDict = [NSMutableDictionary dictionary];
        _nextPageDateOffsets = [NSMutableDictionary dictionary];
        _endOfPagesDict = [NSMutableDictionary dictionary];
        
        [_elementsDict setObject:[NSMutableArray new] forKey:[NSNumber numberWithUnsignedInteger:kBGFeedFilterDefault]];
        [_elementsDict setObject:[NSMutableArray new] forKey:[NSNumber numberWithUnsignedInteger:kBGFeedFilterGlobal]];
        [_elementsDict setObject:[NSMutableArray new] forKey:[NSNumber numberWithUnsignedInteger:kBGFeedFilterProfile]];
        
        [_endOfPagesDict setObject:[NSNumber numberWithBool:NO] forKey:[NSNumber numberWithUnsignedInteger:kBGFeedFilterDefault]];
        [_endOfPagesDict setObject:[NSNumber numberWithBool:NO] forKey:[NSNumber numberWithUnsignedInteger:kBGFeedFilterGlobal]];
        [_endOfPagesDict setObject:[NSNumber numberWithBool:NO] forKey:[NSNumber numberWithUnsignedInteger:kBGFeedFilterProfile]];
        
    }
    return self;
}

#pragma mark - Accessors


- (Media *)mediaElementAtIndex:(NSUInteger)index forFilter:(BGFeedFilterType)filter {
    return (Media *)[[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:filter]] objectAtIndex:index];
}


#pragma mark - Inherit


- (void)makeGetRequestWithLimit:(NSUInteger)limit completion:(void (^)(NSArray *, NSInteger, NSString *, NSError *, NSDictionary *))completionBlock {
    __block BGFeedFilterType feedFilter = self.filter;
    
    if(_filter == kBGFeedFilterDefault) {
        [[AppData sharedInstance] getFeedForUser:self.user
                                     withOffset:_offset
                                     withFilterType:_filter
                                           callback:^(NSArray *newElements, NSInteger newTotalCount, NSString *nextPage, NSError *error) {
                                               completionBlock(newElements, newTotalCount, nextPage, error, @{@"feedFilter": [NSNumber numberWithInteger:feedFilter]});
                                           }];
    } else {
        [[AppData sharedInstance] getGlobalFeedForUser:self.user
                                      withOffset:[_nextPageDateOffsets objectForKey:[NSNumber numberWithInteger:kBGFeedFilterGlobal]]
                                  withFilterType:_filter
                                        callback:^(NSArray *newElements, NSInteger newTotalCount, NSString *nextPage, NSError *error) {
                                            completionBlock(newElements, newTotalCount, nextPage, error, @{@"feedFilter": [NSNumber numberWithInteger:feedFilter]});
                                        }];
    }
}


- (NSUInteger)parseGetServerResponseWithElements:(NSArray *)newElements nextPage:(NSString *)nextPage info:(NSDictionary *)info{
    
    BGFeedFilterType filter = [info objectForKey:@"feedFilter"] ? [[info objectForKey:@"feedFilter"] integerValue] : _filter;
    
    if (newElements.count == 0) {
        // server has no more data
        [self markEndOfPagesForFilter:filter];
        [self sendNotificationChangedWithTotalFlag:YES forFilter:filter];

    } else {
        // add parsed elements to list
        
        NSMutableArray *curElements = [_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:filter]];
        NSInteger oldCount = curElements.count;
        
        if(filter == kBGFeedFilterDefault) {
            _offset += 10;
        }
        
        for(Media *media in newElements) {
            if(![curElements containsObject:media]) {
                [curElements addObject:media];
            }
        }
        
        [_elementsDict setObject:curElements
                          forKey:[NSNumber numberWithUnsignedInteger:filter]];
        
        // save next page offset
        [_nextPageDateOffsets setObject:[[curElements lastObject] createdAt]
                                 forKey:[NSNumber numberWithUnsignedInteger:filter]];
        
        if(oldCount == 0 || !_isEndOfPages) {
            [self sendNotificationChangedWithTotalFlag:YES forFilter:filter];
        } else {
            [self sendNotificationChangedWithTotalFlag:NO forFilter:filter];
        }
    }
    
    return newElements.count;
}


- (void)sendNotificationChangedWithTotalFlag:(BOOL)total forFilter:(BGFeedFilterType)filter {
    
    NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];
    [infoDict setObject:[NSNumber numberWithBool:total]
                 forKey:kAppData_NotificationKey_TotalFlag];
    
    if(self.user) {
        [infoDict setObject:self.user
                     forKey:kAppData_NotificationKey_User];
    }
    
    [infoDict setObject:[NSNumber numberWithInteger:filter]
                 forKey:@"FeedFilter"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAppData_Notification_FeedChanged
                                                        object:nil
                                                      userInfo:infoDict];
}


#pragma mark - Overloading

- (void)markEndOfPagesForFilter:(BGFeedFilterType)filter {
    [_endOfPagesDict setObject:[NSNumber numberWithBool:YES] forKey:[NSNumber numberWithUnsignedInteger:filter]];
}

- (void)markEndOfPages {
    [_endOfPagesDict setObject:[NSNumber numberWithBool:YES] forKey:[NSNumber numberWithUnsignedInteger:_filter]];
    //[super markEndOfPages];
}

- (BOOL)isEndOfPages {
    return [[_endOfPagesDict objectForKey:[NSNumber numberWithUnsignedInteger:_filter]] boolValue];
}

- (BOOL)isEndOfPagesForFilter:(BGFeedFilterType)filterType {
    return [[_endOfPagesDict objectForKey:[NSNumber numberWithUnsignedInteger:filterType]] boolValue];
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

- (id)elementAtIndex:(NSUInteger)index forFilter:(BGFeedFilterType)filterType {
    return [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:filterType]] objectAtIndex:index];
}

- (void)addElement:(id)element {
    [self insertElement:element atIndex:[[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:_filter]] count]];
}

- (NSUInteger)deleteElement:(id)element {
    NSUInteger curIndex = [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:_filter]] indexOfObject:element];
    
    NSUInteger tagIndex = [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:kBGFeedFilterGlobal]] indexOfObject:element];
    NSUInteger defaultIndex = [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:kBGFeedFilterDefault]] indexOfObject:element];
    NSUInteger profileIndex = [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:kBGFeedFilterProfile]] indexOfObject:element];
    
    if (tagIndex != NSNotFound) {
        [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:kBGFeedFilterGlobal]] removeObjectAtIndex:tagIndex];
    }
    
    if (defaultIndex != NSNotFound) {
        [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:kBGFeedFilterDefault]] removeObjectAtIndex:defaultIndex];
    }
    
    if (profileIndex != NSNotFound) {
        [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:kBGFeedFilterProfile]] removeObjectAtIndex:profileIndex];
    }
    
    return curIndex;
}


- (NSUInteger)deleteElementAtIndex:(NSUInteger)index {
    NSUInteger curIndex = [self deleteElement:[[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:_filter]] objectAtIndex:index]];
    return curIndex;
}

- (void)setFilter:(BGFeedFilterType)filter {
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

- (NSUInteger)elementsCountForFilter:(BGFeedFilterType)filterType {
    return [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:filterType]] count];
}

- (NSUInteger)indexOfElement:(id)element {
    return [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:_filter]] indexOfObject:element];
}

- (NSUInteger)indexOfElement:(id)element inFilter:(BGFeedFilterType)filterType {
    return [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:filterType]] indexOfObject:element];
}

- (void)addElement:(Media *)media toFilter:(BGFeedFilterType)filterType atIndex:(NSUInteger)index {
    [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:filterType]] insertObject:media atIndex:index];
}

- (void)clearStateAndElements {
    [_nextPageDateOffsets setObject:@"" forKey:[NSNumber numberWithUnsignedInteger:_filter]];
    [_endOfPagesDict setObject:[NSNumber numberWithBool:NO] forKey:[NSNumber numberWithUnsignedInteger:_filter]];
    [[_elementsDict objectForKey:[NSNumber numberWithUnsignedInteger:_filter]] removeAllObjects];
    [_endOfPagesDict setObject:[NSNumber numberWithBool:NO] forKey:[NSNumber numberWithUnsignedInteger:_filter]];
    
    if(_filter == kBGFeedFilterDefault) {
        _offset = 0;
    }
    
    [super clearStateAndElements];
}

- (void)clearInherited {
    [_nextPageDateOffsets setObject:@"" forKey:[NSNumber numberWithUnsignedInteger:_filter]];
    [_endOfPagesDict setObject:[NSNumber numberWithBool:NO] forKey:[NSNumber numberWithUnsignedInteger:_filter]];
    
    if(_filter == kBGFeedFilterDefault) {
        _offset = 0;
    }
    
    [super clearInherited];
}

@end
