#import <Foundation/Foundation.h>

@interface SelectorQueue : NSObject

@property (weak, nonatomic) id target;

- (void)pause;
- (void)resume;
- (void)perform:(SEL)selector;
- (void)perform:(SEL)selector withObject:(id)object;

@end
