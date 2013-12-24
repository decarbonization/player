//
//  AccountManager.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 4/21/13.
//
//

#import "AccountManager.h"
#import "SSKeychain.h"
#import "Account.h"
#import "ServiceDescriptor.h"

NSString *const AccountManagerDidSaveAccountNotification = @"AccountManagerDidSaveAccountNotification";
NSString *const AccountManagerDidDeleteAccountNotification = @"AccountManagerDidDeleteAccountNotification";
NSString *const AccountManagerAffectedAccountKey = @"AccountManagerAffectedAccountKey";

@interface AccountManager ()

@end

@implementation AccountManager {
    NSMutableDictionary *_accounts;
}

+ (instancetype)sharedAccountManager
{
    static AccountManager *sharedAccountManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAccountManager = [AccountManager new];
    });
    
    return sharedAccountManager;
}

- (id)init
{
    if((self = [super init])) {
        NSData *archivedAccounts = RKGetPersistentObject(@"AccountManager_accounts");
        if(archivedAccounts)
            _accounts = [NSKeyedUnarchiver unarchiveObjectWithData:archivedAccounts];
        else
            _accounts = [NSMutableDictionary dictionary];
    }
    
    return self;
}

#pragma mark - Managing Accounts

- (NSArray *)availableServices
{
    return RKCollectionFilterToArray([ServiceDescriptor registeredServices], ^BOOL(ServiceDescriptor *service) {
        Account *existingAccount = [self accountWithIdentifier:service.identifier];
        return (existingAccount == nil || !existingAccount.isAuthorized);
    });
}

#pragma mark -

- (Account *)accountWithIdentifier:(NSString *)identifier
{
    NSParameterAssert(identifier);
    
    Account *account = _accounts[identifier];
    if(account && !account.disabled)
        return account;
    else
        return nil;
}

#pragma mark -

- (void)saveAccount:(Account *)account
{
    NSParameterAssert(account);
    
    _accounts[account.serviceIdentifier] = account;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AccountManagerDidSaveAccountNotification
                                                        object:self
                                                      userInfo:@{AccountManagerAffectedAccountKey: account}];
    
    [self saveAccounts];
}

- (RKPromise *)deleteAccount:(Account *)account
{
    NSParameterAssert(account);
    
    RKPromise *promise = [RKPromise new];
    [[RKQueueManager commonQueue] addOperationWithBlock:^{
        NSError *error = nil;
        if([[account.descriptor.service logout] await:&error]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [_accounts removeObjectForKey:account.serviceIdentifier];
                
                if(account) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:AccountManagerDidDeleteAccountNotification
                                                                        object:self
                                                                      userInfo:@{AccountManagerAffectedAccountKey: account}];
                }
                
                [self saveAccounts];
            });
            
            [promise accept:self];
        } else {
            [promise reject:error];
        }
    }];
    return promise;
}

#pragma mark -

- (void)saveAccounts
{
    [self willChangeValueForKey:@"accounts"];
    RKSetPersistentObject(@"AccountManager_accounts", [NSKeyedArchiver archivedDataWithRootObject:_accounts]);
    [self didChangeValueForKey:@"accounts"];
}

- (NSArray *)accounts
{
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"serviceIdentifier" ascending:YES];
    return [_accounts.allValues sortedArrayUsingDescriptors:@[ sortDescriptor ]];
}

@end
