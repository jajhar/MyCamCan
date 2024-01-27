#import "NSURL+RefersLocalProperty.h"

@implementation NSURL (RefersLocalProperty)

+ (NSURL *)urlReferringLocalProperty:(NSString *)property {
    return [NSURL URLWithString:[NSString stringWithFormat:@"localproperty://%@", property]];
}

- (BOOL)refersLocalProperty {
    return [[self scheme] isEqualToString:@"localproperty"];
}

- (NSString *)referedLocalProperty {
    return [self host];
}

@end
