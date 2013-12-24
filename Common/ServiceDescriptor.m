//
//  AccountService.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 4/21/13.
//
//

#import "ServiceDescriptor.h"

#import "ExfmSession.h"
#import "ExfmAccountServiceViewController.h"

#if !TARGET_OS_IPHONE

#import "LastfmAccountServiceViewController.h"
#import "LastFMSession.h"

NSString *const kAccountServiceIdentifierLastfm = @"Last.fm";

#endif /* !TARGET_OS_IPHONE */

NSString *const kAccountServiceIdentifierExfm = @"Ex.fm"; //This identifier is historical. Do not change.

#if TARGET_OS_MAC && !TARGET_OS_IPHONE
#   define  ImageNamed(name)    [NSImage imageNamed:(@"" name @"")]
#else
#   define  ImageNamed(name)    [UIImage imageNamed:(@"" name @"")]
#endif /* TARGET_OS_MAC */

@implementation ServiceDescriptor

+ (NSMutableDictionary *)registeredServiceTable
{
    static NSMutableDictionary *registeredServices = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registeredServices = [NSMutableDictionary dictionary];
        
        
        
        ServiceDescriptor *exfmService = [ServiceDescriptor new];
        exfmService.accountType = kAccountTypeUsernamePassword;
        exfmService.identifier = kAccountServiceIdentifierExfm;
        exfmService.name = @"Exfm";
        exfmService.localizedDescription = NSLocalizedString(@"Discover, love, and share new music with exfm", @"");
        exfmService.logo = ImageNamed(@"EXFMLogo");
        exfmService.authorizationPresenterClass = [ExfmAccountServiceViewController class];
        exfmService.service = [ExfmSession defaultSession];
        registeredServices[kAccountServiceIdentifierExfm] = exfmService;
        
        
        
#if TARGET_OS_MAC && !TARGET_OS_IPHONE
        ServiceDescriptor *lastfmService = [ServiceDescriptor new];
        lastfmService.accountType = kAccountTypeToken;
        lastfmService.identifier = kAccountServiceIdentifierLastfm;
        lastfmService.name = @"Last.fm";
        lastfmService.localizedDescription = NSLocalizedString(@"Scrobble your songs and now playing status to Last.fm", @"");
        lastfmService.logo = ImageNamed(@"LastFMLogo");
        lastfmService.authorizationPresenterClass = [LastfmAccountServiceViewController class];
        lastfmService.service = [LastFMSession defaultSession];
        
        registeredServices[kAccountServiceIdentifierLastfm] = lastfmService;
#endif /* TARGET_OS_MAC && !TARGET_OS_IPHONE */
    });
    
    return registeredServices;
}

+ (void)registerDescriptor:(ServiceDescriptor *)service
{
    NSParameterAssert(service);
    NSParameterAssert(service.identifier);
    
    RK_SYNCHRONIZED_MACONLY(self) {
        self.registeredServiceTable[service.identifier] = service;
    }
}

+ (void)unregisterDescriptor:(ServiceDescriptor *)service
{
    NSParameterAssert(service);
    NSParameterAssert(service.identifier);
    
    RK_SYNCHRONIZED_MACONLY(self) {
        [self.registeredServiceTable removeObjectForKey:service.identifier];
    }
}

#pragma mark -

+ (NSArray *)registeredServices
{
    RK_SYNCHRONIZED_MACONLY(self) {
        return [self.registeredServiceTable.allValues sortedArrayUsingComparator:^(ServiceDescriptor *left, ServiceDescriptor *right) {
            return [left.name compare:right.name];
        }];
    }
}

+ (ServiceDescriptor *)descriptorWithIdentifier:(NSString *)identifier
{
    if(!identifier)
        return nil;
    
    RK_SYNCHRONIZED_MACONLY(self) {
        return self.registeredServiceTable[identifier];
    }
}

#pragma mark - Vending Accounts

- (Account *)emptyAccount
{
    return [[Account alloc] initWithServiceIdentifier:self.identifier type:self.accountType];
}

@end
