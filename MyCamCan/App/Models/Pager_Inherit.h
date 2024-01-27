

#import "Pager.h"


@interface Pager ()

/**
 @brief make request to proper API call. Must be overriden in subclass. Must call completion block on finish.
 @param completionBlock supposed to be executed on a different thread. This param is always present.
 */
- (void)makeGetRequestWithLimit:(NSUInteger)limit
                     completion:(void(^)(NSArray *elements, NSInteger newTotalCount, NSString *nextPage, NSError *error, NSDictionary *info))completionBlock;

/**
 @brief subclass must override this method to parse expected data
 @param response response from server. May be nil.
 @return number of elements, that was added to the list
 */


/**
 @brief used by subclass to signalize, that server has no more data/pages.
    Must be used in [parseGetServerResponse:]
 */
- (void)markEndOfPages;

/**
 Must be overriden by subclass if it uses nonstandart logic for total count.
 */
- (void)updateTotalCountWith:(NSInteger)newValue;

/**
 @brief make request to proper API call. Must be overriden by subclass. Must call completion block on finish.
 @param completionBlock supposed to be executed on a different thread.
 */
- (void)makeRefreshTotalCountRequestWithCompletionBlock:(void(^)(NSInteger newTotalCount, NSError *error))completionBlock;

/**
 @brief used to clear data in subclass. Must be overriden by subclass if it uses custom states.
 */
- (void)clearInherited;

/**
 @brief send proper notification through model. Must be overriden by subclass.
 @param total indicate that list was cleared before adding new elements.
 */
- (void)sendNotificationChangedWithTotalFlag:(BOOL)total;

@end
