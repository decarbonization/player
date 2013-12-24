//
//  AccountManager.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 4/21/13.
//
//

#ifndef AccountManager_h
#define AccountManager_h 1

#import <Foundation/Foundation.h>

@class Account, AccountDescriptor;

///The notification posted when an AccountManager saves an account.
///
///The notification's `userInfo` contains one key, `AccountManagerAffectedAccountKey`.
RK_EXTERN NSString *const AccountManagerDidSaveAccountNotification;

///The notification posted when an AccountManager deletes an account.
///
///The notification's `userInfo` contains one key, `AccountManagerAffectedAccountKey`.
RK_EXTERN NSString *const AccountManagerDidDeleteAccountNotification;

///The key that accesses the affected account for AccountManager notifications.
RK_EXTERN NSString *const AccountManagerAffectedAccountKey;


///The AccountManager class encapsulates the management of accounts in Pinna.
///
///The AccountManager currently only supports one account per service (identifier).
///
///All methods related to add, removing, and listing active accounts are not thread-safe.
///
/// \seealso(AccountService)
@interface AccountManager : NSObject

///Returns the shared account manager, creating it if it does not already exist.
+ (instancetype)sharedAccountManager;

#pragma mark - Managing Accounts

///Returns the available services.
///
///This method should be preferred over calling `+[AccountDescriptor registeredDescriptors]` directly
///as this method filters out any services which already have active accounts.
///
///This method is thread-safe on OS X, and not on iOS.
- (NSArray *)availableServices;

///Returns an Account with a given service identifier.
///
/// \param  identifier   The identifier of the service. Required.
///
/// \result An active Account if one can be found, nil otherwise.
- (Account *)accountWithIdentifier:(NSString *)identifier;

#pragma mark -

///Saves an Account object into the AccountManager's persistent store.
///
/// \param  account The account to save. Required.
- (void)saveAccount:(Account *)account;

///Deletes an account object from the AccountManager's persistent store.
///
/// \param  account The account to delete. Required.
- (RKPromise *)deleteAccount:(Account *)account RK_REQUIRE_RESULT_USED;

#pragma mark -

///All of the accounts currently being managed.
@property (nonatomic, copy, readonly) NSArray *accounts;

@end

#endif /* AccountManager_h */
