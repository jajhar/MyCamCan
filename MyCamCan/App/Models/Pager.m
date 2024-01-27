

#import "Pager.h"
#import "Pager_Inherit.h"
#import "Pager_ModelInternal.h"


const NSInteger kPager_DefaultLimitPerPage = 10;
const NSInteger kpager_WatchDogCounterLimit = 5;


@interface Pager()
{
    //--data
    NSInteger  _totalElementsCount;
    
    //--state
    BOOL        _isFetching;
    NSLock      *_fetchLock;
    NSInteger   _watchDogCounter;
}

// time mark of the last request
@property (nonatomic, assign) CFTimeInterval requestTimeMark;

@end


@implementation Pager


#pragma mark - Initialization


- (instancetype)init {
    self = [super init];
    if (self) {
        _fetchLock = [[NSLock alloc] init];
        _elements = [NSMutableArray array];
        _isEndOfPages = NO;
        _isFetching = NO;
        _limitPerPage = kPager_DefaultLimitPerPage;
        _totalElementsCount = 0;
        _watchDogCounter = 0;
    }
    return self;
}


#pragma mark - Getters


- (NSUInteger)elementsCount {
    return _elements.count;
}


- (id)elementAtIndex:(NSUInteger)index {
    return _elements[index];
}


- (NSArray *)elementsFromIndex:(NSUInteger)index count:(NSUInteger)count {
    NSRange range;
    if (index >= [_elements count]) {
        return nil;
    }
    range.location = index;
    range.length = MIN([_elements count] - index, count);
    return [_elements subarrayWithRange:range];
}


- (BOOL)isEndOfPages {
    return _isEndOfPages;
}


- (BOOL)isFetching {
    return _isFetching;
}


- (NSUInteger)totalElementsCount {
    return _totalElementsCount;
}

- (BOOL)containsObject:(id)element {
    return [_elements containsObject:element];
}

#pragma mark - Actions


- (void)clearStateAndElements {
    [self clear];
}


- (void)reloadWithCompletion:(PagerCompletionBlock)completionBlock {
    [self requestNextPageWithClearState:YES clearElements:YES completion:completionBlock];
}


- (void)getNextPageWithCompletion:(PagerCompletionBlock)completionBlock {
    [self requestNextPageWithClearState:NO clearElements:NO completion:completionBlock];
}

- (void)setNextPageOffset:(id)offSet {
    // nothing - it is abstract class
    // must be overriden by subclass
}


- (void)refreshTotalElementsCount {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       // [_fetchLock lock];
        _isFetching = YES;
        CFTimeInterval requestTime = CACurrentMediaTime();
        self.requestTimeMark = requestTime;
        [self makeRefreshTotalCountRequestWithCompletionBlock:^(NSInteger newTotalCount, NSError *error) {
           //[self->_fetchLock lock];
            if (self.requestTimeMark == requestTime) {
                // error
                if (error != nil) {
                    // process error
                    NSLog(@"pager error: %@", error);
                    [self markEndOfPages];
                    [self sendNotificationChangedWithTotalFlag:NO];
                } else {
                    // update count
                    if (newTotalCount > 0) {
                        _totalElementsCount = newTotalCount;
                    }
                    if (_totalElementsCount < [_elements count]) {
                        _totalElementsCount = [_elements count];
                    }
                    [self updateTotalCountWith:_totalElementsCount];
                    [self sendNotificationChangedWithTotalFlag:NO];
                }
                self->_isFetching = NO;
            }
           // [self->_fetchLock unlock];
        }];
       // [_fetchLock unlock];
    });
}

- (void)setPageLimit:(NSUInteger)limit {
    _limitPerPage = limit;
}

#pragma mark - Model Internal


- (NSUInteger)deleteElement:(id)element {
    NSUInteger index = [_elements indexOfObject:element];
    if (index != NSNotFound) {
        [_elements removeObjectAtIndex:index];
        _totalElementsCount--;
    }
    return index;
}


- (NSUInteger)deleteElementAtIndex:(NSUInteger)index {
    [_elements removeObjectAtIndex:index];
    _totalElementsCount--;
    return index;
}


- (void)insertElement:(id)element atIndex:(NSUInteger)index {
    
    if(element == nil) {
        NSLog(@"%s : Attempted to insert nil element", __PRETTY_FUNCTION__);
        return;
    }
    
    NSUInteger objIndex = [_elements indexOfObject:element];
    
    if(objIndex == NSNotFound) {
        [_elements insertObject:element atIndex:index];
        _totalElementsCount++;
    }
}


- (void)addElement:(id)element {
    NSUInteger index = [_elements indexOfObject:element];

    if(index == NSNotFound) {
        [self insertElement:element atIndex:[_elements count]];
    }
}


- (void)setupElements:(NSArray *)newElements {
    [self clearStateAndElements];
    [_elements addObjectsFromArray:newElements];
    if (_totalElementsCount < [_elements count]) {
        _totalElementsCount = [_elements count];
    }
    [self markEndOfPages];
}


- (NSUInteger)indexOfElement:(id)element {
    return [_elements indexOfObject:element];
}


#pragma mark - Inherited


- (void)makeGetRequestWithLimit:(NSUInteger)limit completion:(void(^)(NSArray *elements, NSInteger newTotalCount, NSString *nextPage, NSError *error, NSDictionary *info))completionBlock {
#pragma unused(limit)
    // make request with proper API call
    // must be overriden
    
    if (completionBlock) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            completionBlock(nil, -1, @"", nil, nil);
        });
    }
}


- (NSUInteger)parseGetServerResponseWithElements:(NSArray *)newElements nextPage:(NSString *)nextPage info:(NSDictionary *)info {
#pragma unused(newElements)
    // parse response
    // store data in _elements
    // if server has no more data - call [self markEndOfPages]
    // return number of elements that was added to the lsit
    
    // must be overriden
    return 0;
}


- (void)markEndOfPages {
    _isEndOfPages = YES;
}


- (void)updateTotalCountWith:(NSInteger)newValue {
#pragma unused(newValue)
    // do nothing
    // only in subclasses
}


- (void)makeRefreshTotalCountRequestWithCompletionBlock:(void (^)(NSInteger, NSError *))completionBlock {
    // in most cases we need same API call
    // request single element - total elements count is in the meta-data
    [self makeGetRequestWithLimit:1 completion:^(NSArray *elements, NSInteger newTotalCount, NSString *nextPage, NSError *error, NSDictionary *info) {
        completionBlock(newTotalCount, error);
    }];
}


- (void)clearInherited {
    // must be overriden by subclass
    // clears state, not elements
    
    _nextPageDateOffset = @"";
    _nextPageNumber = 1;
}


- (void)sendNotificationChangedWithTotalFlag:(BOOL)total {
    // nothing - it is abstract class
    // must be overriden by subclass
}


#pragma mark - Internal


- (void)requestNextPageWithClearState:(BOOL)clearState
                        clearElements:(BOOL)clearElements
                           completion:(PagerCompletionBlock)completionBlock {
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       // [_fetchLock lock];
        _isFetching = YES;
        if (clearState) {
            [self clearInherited];
        }
        CFTimeInterval requestTime = CACurrentMediaTime();
        self.requestTimeMark = requestTime;
        [self makeGetRequestWithLimit:_limitPerPage
                           completion:^(NSArray *elements, NSInteger newTotalCount, NSString *nextPage, NSError *error, NSDictionary *info) {
                               //[self->_fetchLock lock];
                               if (self.requestTimeMark == requestTime) {
                                   // error
                                   if (error != nil) {
                                       // process error
                                       NSLog(@"Pager error: %@", error);

                                       [self markEndOfPages];
                                       [self sendNotificationChangedWithTotalFlag:YES];
                                   } else {
                                       // reset watchdog
                                       _watchDogCounter = 0;
                                       // pre process
                                       if (clearElements) {
                                           [self clearStateAndElements];
                                       }
                                       // process elements list:
                                       //   here we do not know elements types and means of getting next page offset
                                       //   only subclass can do this correctly
                                       [self parseGetServerResponseWithElements:elements nextPage:nextPage info:info];
                                       // update elements total count
                                       if (newTotalCount > 0) {
                                           _totalElementsCount = newTotalCount;
                                       }
                                       if (_totalElementsCount < [_elements count]) {
                                           // in case server response contains no such data, or other nonstandart case
                                           _totalElementsCount = [_elements count];
                                       }
                                       [self updateTotalCountWith:_totalElementsCount];
                                   }
                                   self->_isFetching = NO;
                                   // finish
                                   if (completionBlock != NULL) {
                                       completionBlock(error);
                                   }
                               }
                               //[self->_fetchLock unlock];
                           }];
        //[_fetchLock unlock];
//    });
}


- (void)clear {
    //[_fetchLock lock];
    // clear data
    [_elements removeAllObjects];
    _isEndOfPages = NO;
    _isFetching = NO;
    self.requestTimeMark = -1;
    [self clearInherited];
    //[_fetchLock unlock];
}


@end
