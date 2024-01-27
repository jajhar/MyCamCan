#import <Foundation/Foundation.h>

@interface Keychain : NSObject

+(NSDictionary *)credentialsWithId:(NSString *)keyId;
+(void)setUsername:(NSString *)username password:(NSString *)password forId:(NSString *)keyId;
+(void)clearCredentialsForId:(NSString *)keyId;

@end
