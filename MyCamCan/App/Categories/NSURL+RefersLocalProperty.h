#import <Foundation/Foundation.h>

@interface NSURL (RefersLocalProperty)

/**
 * This method is called action to url referring the local property
 */
+ (NSURL *)urlReferringLocalProperty:(NSString *)property;
/**
 * This method is called action to refer local property
 */
- (BOOL)refersLocalProperty;
/**
 * This method is called action to refered local property
 */
- (NSString *)referedLocalProperty;

@end
