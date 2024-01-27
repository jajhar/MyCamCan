#import "Keychain.h"

@implementation Keychain

static NSString const *ServiceName = @"ZUM2.0";

+(NSDictionary *)credentialsWithId:(NSString *)keyId
{
	const char *keychainId=[keyId cStringUsingEncoding:NSUTF8StringEncoding];
	NSData *keychainIdData=[NSData dataWithBytes:keychainId
										  length:strlen(keychainId)];
	NSDictionary *result=nil;
	OSStatus status=SecItemCopyMatching((CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
														  keychainIdData,			kSecAttrGeneric,
														  kSecClassGenericPassword,	kSecClass,
														  ServiceName,              kSecAttrService,
														  kSecMatchLimitOne,		kSecMatchLimit,
														  kCFBooleanTrue,			kSecReturnData,
														  kCFBooleanTrue,			kSecReturnAttributes,
														  nil],
										(CFTypeRef *)&result);
	NSData *passwordData=[result objectForKey:kSecValueData];
	NSDictionary *returnDictionary=nil;
	if (result != nil) {
		returnDictionary=[NSDictionary dictionaryWithObjectsAndKeys:
						  [result objectForKey:kSecAttrAccount],													@"username",
						  [[[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding] autorelease],	@"password",
						  nil];
	}
	[result release];
	if (status!=noErr&&status!=errSecItemNotFound)
	{
		NSLog(@"Keychain::credentialsWithId");
		NSLog(@"error : %ld",status);
		return nil;
	}
	else
		return returnDictionary;
}

+(void)setUsername:(NSString *)username password:(NSString *)password forId:(NSString *)keyId
{
	const char *keychainId=[keyId cStringUsingEncoding:NSUTF8StringEncoding];
	NSData *keychainIdData=[NSData dataWithBytes:keychainId
										  length:strlen(keychainId)];
	OSStatus status=SecItemCopyMatching((CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
														  keychainIdData,			kSecAttrGeneric,
														  kSecClassGenericPassword,	kSecClass,
														  ServiceName,				kSecAttrService,
														  kSecMatchLimitOne,		kSecMatchLimit,
														  nil],
										NULL);
	OSStatus status2;
	switch(status)
	{
		case errSecItemNotFound:
			status2=SecItemAdd((CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
												 keychainIdData,									kSecAttrGeneric,
												 kSecClassGenericPassword,							kSecClass,
												 ServiceName,										kSecAttrService,
												 username,											kSecAttrAccount,
												 [password dataUsingEncoding:NSUTF8StringEncoding],	kSecValueData,
												 nil],
							   NULL);
			if (status2!=noErr)
			{
				NSLog(@"Keychain::setUsername:password:forId");
				NSLog(@"Cannot add item");
				NSLog(@"error : %ld",status2);
			}
			break;
		case noErr:
			status2=SecItemUpdate((CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
													keychainIdData,				kSecAttrGeneric,
													kSecClassGenericPassword,	kSecClass,
													ServiceName,				kSecAttrService,
													nil],
								  (CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
													username,											kSecAttrAccount,
													[password dataUsingEncoding:NSUTF8StringEncoding],	kSecValueData,
													nil]);
			if (status2!=noErr)
			{
				NSLog(@"Keychain::setUsername:password:forId");
				NSLog(@"Cannot update item");
				NSLog(@"error : %ld",status2);
			}
			break;
		default:
			NSLog(@"Keychain::setUsername:password:forId");
			NSLog(@"Search failed");
			NSLog(@"error : %ld",status);
	}
}

+(void)clearCredentialsForId:(NSString *)keyId;
{
	const char *keychainId=[keyId cStringUsingEncoding:NSUTF8StringEncoding];
	NSData *keychainIdData=[NSData dataWithBytes:keychainId
										  length:strlen(keychainId)];
	OSStatus status=SecItemDelete((CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
													keychainIdData,				kSecAttrGeneric,
													kSecClassGenericPassword,	kSecClass,
													ServiceName,				kSecAttrService,
													nil]);
	if (status!=noErr)
	{
		NSLog(@"Keychain::clearCredentialsForId");
		NSLog(@"Deletion failed");
		NSLog(@"error : %ld",status);
	}
}

@end
