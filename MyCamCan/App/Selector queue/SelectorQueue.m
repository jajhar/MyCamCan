#import "SelectorQueue.h"
#include "libkern/OSAtomic.h"
#include <pthread.h>

@interface InvocationInfo : NSObject

+ (InvocationInfo *)invocationInfoWithSelector:(SEL)selector hasArgument:(BOOL)hasArgument argument:(id)argument;

@property (assign, nonatomic) SEL selector;
@property (assign, nonatomic) BOOL hasArgument;
@property (strong, nonatomic) id argument;

@end

@implementation InvocationInfo

+ (InvocationInfo *)invocationInfoWithSelector:(SEL)selector hasArgument:(BOOL)hasArgument argument:(id)argument {
    InvocationInfo *newInfo = [InvocationInfo new];
    newInfo.selector = selector;
    newInfo.hasArgument = hasArgument;
    if (hasArgument) {
        newInfo.argument = argument;
    }
    return newInfo;
}

@end

@interface SelectorQueue ()

//L0

- (void)pause;
- (void)resume;
- (void)perform:(SEL)selector;
- (void)perform:(SEL)selector withObject:(id)object;

//L1

@property (assign, atomic) NSUInteger paused;

- (void)enqueueSelector:(SEL)selector withObject:(id)object noArgument:(BOOL)noArgument;
- (void)runQueue;

//L2

@property (assign, nonatomic) pthread_mutex_t *queueMutex;
@property (strong, nonatomic) NSMutableArray *queue;

- (void)targetPerformSelector:(SEL)selector;
- (void)targetPerformSelector:(SEL)selector withObject:(id)object;

@end

@implementation SelectorQueue

#pragma mark L0

- (void)pause {
#if __LP64__ || (TARGET_OS_EMBEDDED && !TARGET_OS_IPHONE) || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64
    OSAtomicIncrement64Barrier((int64_t *)&_paused);
#else
    OSAtomicIncrement32Barrier((int32_t *)&_paused);
#endif
}

- (void)resume {
#if defined(DEBUG)
    NSAssert(_paused > 0, @"_paused == 0");
#endif
#if __LP64__ || (TARGET_OS_EMBEDDED && !TARGET_OS_IPHONE) || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64
    OSAtomicDecrement64Barrier((int64_t *)&_paused);
#else
    OSAtomicDecrement32Barrier((int32_t *)&_paused);
#endif
    if (_paused == 0) {
        [self performSelector:@selector(runQueue) onThread:[NSThread currentThread] withObject:nil waitUntilDone:NO];
    }
}

- (void)perform:(SEL)selector {
    if (_paused == 0) {
        [self targetPerformSelector:selector];
    } else {
        [self enqueueSelector:selector withObject:nil noArgument:YES];
    }
}

- (void)perform:(SEL)selector withObject:(id)object {
    if (_paused == 0) {
        [self targetPerformSelector:selector withObject:object];
    } else {
        [self enqueueSelector:selector withObject:object noArgument:NO];
    }
}

#pragma mark L1

- (void)commonInit {
    _queueMutex = malloc(sizeof(pthread_mutex_t));
    pthread_mutex_init(_queueMutex,NULL);
    _queue = [NSMutableArray new];
}

- (void)enqueueSelector:(SEL)selector withObject:(id)object noArgument:(BOOL)noArgument {
    pthread_mutex_lock(_queueMutex);
    [self.queue addObject:[InvocationInfo invocationInfoWithSelector:selector hasArgument:!noArgument argument:object]];
    pthread_mutex_unlock(_queueMutex);
}

- (void)runQueue {
    pthread_mutex_lock(_queueMutex);
    while ((_paused == 0) && (self.queue.count != 0)) {
        InvocationInfo *info;
        info = [self.queue objectAtIndex:0];
        [self.queue removeObjectAtIndex:0];
        pthread_mutex_unlock(_queueMutex);
        if (info.hasArgument) {
            [self targetPerformSelector:info.selector withObject:info.argument];
        } else {
            [self targetPerformSelector:info.selector];
        }
        pthread_mutex_lock(_queueMutex);
    }
    pthread_mutex_unlock(_queueMutex);
}

#pragma mark L2

- (void)targetPerformSelector:(SEL)selector {
    IMP imp = [self.target methodForSelector:selector];
    void (*func)(id, SEL) = (void *)imp;
    func(self.target, selector);
}

- (void)targetPerformSelector:(SEL)selector withObject:(id)object {
    IMP imp = [self.target methodForSelector:selector];
    void (*func)(id, SEL, id) = (void *)imp;
    if([self.target respondsToSelector:selector]){
        func(self.target, selector, object);
    }
}

#pragma mark - Inherited

#pragma mark NSObject

- (id)init {
    if ((self = [super init]) != nil) {
        [self commonInit];
    }
    return self;
}

- (void)dealloc {
    pthread_mutex_lock(_queueMutex);
    pthread_mutex_t *mutex = _queueMutex;
    _queueMutex = NULL;
    pthread_mutex_unlock(mutex);
    pthread_mutex_destroy(mutex);
    free(mutex);
}

@end
