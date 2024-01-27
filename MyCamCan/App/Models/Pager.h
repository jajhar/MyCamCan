
#import <Foundation/Foundation.h>


typedef void(^PagerCompletionBlock)(NSError *error);


@interface Pager : NSObject {
@protected
    NSMutableArray  *_elements;
    NSString        *_nextPageDateOffset;
    NSUInteger      _nextPageNumber;
    NSUInteger      _limitPerPage;
    BOOL            _isEndOfPages;
}

//--getters
- (NSUInteger)elementsCount;
- (id)elementAtIndex:(NSUInteger)index;
- (NSArray *)elementsFromIndex:(NSUInteger)index count:(NSUInteger)count;
- (NSUInteger)indexOfElement:(id)element;
- (NSUInteger)totalElementsCount;
- (BOOL)containsObject:(id)element;

//- (void)setNextPageOffset:(id)offSet;

- (BOOL)isEndOfPages;
- (BOOL)isFetching;

//--actions
- (void)clearStateAndElements;
- (void)reloadWithCompletion:(PagerCompletionBlock)completionBlock;
- (void)getNextPageWithCompletion:(PagerCompletionBlock)completionBlock;
- (void)refreshTotalElementsCount;
- (void)setPageLimit:(NSUInteger)limit;
- (void)setNextPageOffset:(id)offSet;

@end
