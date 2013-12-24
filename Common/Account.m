//
//  Account.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 4/21/13.
//
//

#import "Account.h"
#import "ServiceDescriptor.h"

#if Account_StorePasswordsInKeychain
#   import "SSKeychain.h"
#endif /* Account_StorePasswordsInKeychain */

///The versions of the Account object.
enum AccountArchiveVersion {
    ///The first version of the account object.
    kAccountArchiveVersionInitial = 1,
};

@implementation Account {
    NSMutableDictionary *_settings;
}

- (id)initWithServiceIdentifier:(NSString *)serviceIdentifier type:(AccountType)type
{
    NSParameterAssert(serviceIdentifier);
    
    if((self = [super init])) {
        self.serviceIdentifier = serviceIdentifier;
        self.type = type;
    }
    
    return self;
}

#pragma mark - Identity

- (BOOL)isEqual:(id)object
{
    Account *otherAccount = RK_TRY_CAST(Account, object);
    if(otherAccount != nil) {
        return (self.type == otherAccount.type &&
                [self.serviceIdentifier ?: @"" isEqualToString:otherAccount.serviceIdentifier ?: @""] &&
                [self.username ?: @"" isEqualToString:otherAccount.username ?: @""] &&
                [self.password ?: @"" isEqualToString:otherAccount.password ?: @""] &&
                [self.email ?: @"" isEqualToString:otherAccount.email ?: @""] &&
                [self.token ?: @"" isEqualToString:otherAccount.token ?: @""]);
    }
    
    return NO;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p serviceIdentifier => %@, username => %@, token = %@>", NSStringFromClass([self class]), self, self.serviceIdentifier, self.username, self.token];
}

- (NSUInteger)hash
{
    return ((self.type +
            [self.serviceIdentifier hash]) >> (1 +
            [self.username hash]) >> (1 +
            [self.password hash]) >> (1 +
            [self.token hash]) >> 1);
}

#pragma mark - Properties

- (ServiceDescriptor *)descriptor
{
    return [ServiceDescriptor descriptorWithIdentifier:self.serviceIdentifier];
}

#if Account_StorePasswordsInKeychain

- (NSString *)keychainServiceName
{
    //We are locked into this service format because of
    //Pinna 2.0 launching with this format for Exfm passwords.
    return [NSString stringWithFormat:@"%@ in Pinna", self.serviceIdentifier];
}

- (void)setPassword:(NSString *)password
{
    if(!self.username || !self.serviceIdentifier)
        [NSException raise:NSInternalInconsistencyException format:@"Attempting to set Account password before required properties are set."];
    
    [SSKeychain setPassword:password forService:[self keychainServiceName] account:self.username];
}

- (NSString *)password
{
    if(!self.username || !self.serviceIdentifier)
        return nil;
    
    return [SSKeychain passwordForService:[self keychainServiceName] account:self.username];
}

#endif /* Account_StorePasswordsInKeychain */

#pragma mark -

+ (NSSet *)keyPathsForValuesAffectingIsAuthorized
{
    return [NSSet setWithObjects:@"username", @"password", @"token", nil];
}

- (BOOL)isAuthorized
{
    return ((self.username && self.password) || self.token);
}

#pragma mark -

- (NSMutableDictionary *)settings
{
    if(!_settings) {
        _settings = [NSMutableDictionary dictionary];
    }
    
    return _settings;
}

#pragma mark - <NSCoding>

- (id)initWithCoder:(NSCoder *)decoder
{
    if([decoder decodeIntegerForKey:@"ArchiveVersion"] != kAccountArchiveVersionInitial) {
        NSLog(@"*** Warning, version mismatch for Account. Ignoring");
        
        return nil;
    }
    
    if((self = [super init])) {
        self.type = [decoder decodeIntegerForKey:@"type"];
        self.serviceIdentifier = [decoder decodeObjectForKey:@"serviceIdentifier"];
        self.disabled = [decoder decodeBoolForKey:@"disabled"];
        
        self.username = [decoder decodeObjectForKey:@"username"];
#if !Account_StorePasswordsInKeychain
        self.password = [decoder decodeObjectForKey:@"password"];
#endif /* !Account_StorePasswordsInKeychain */
        self.email = [decoder decodeObjectForKey:@"email"];
        self.token = [decoder decodeObjectForKey:@"token"];
        
        _settings = [decoder decodeObjectForKey:@"settings"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeInteger:kAccountArchiveVersionInitial forKey:@"ArchiveVersion"];
    
    [encoder encodeInteger:self.type forKey:@"type"];
    [encoder encodeObject:self.serviceIdentifier forKey:@"serviceIdentifier"];
    [encoder encodeBool:self.disabled forKey:@"disabled"];
    
    [encoder encodeObject:self.username forKey:@"username"];
#if !Account_StorePasswordsInKeychain
    [encoder encodeObject:self.password forKey:@"password"];
#endif /* !Account_StorePasswordsInKeychain */
    [encoder encodeObject:self.email forKey:@"email"];
    [encoder encodeObject:self.token forKey:@"token"];
    
    [encoder encodeObject:_settings forKey:@"settings"];
}

@end
