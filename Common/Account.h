//
//  Account.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 4/21/13.
//
//

#import <Foundation/Foundation.h>

@class ServiceDescriptor;

///Set to 1 to have the Account class store passwords in the Keychain.
#define Account_StorePasswordsInKeychain    1

///The different types an `Account` can be.
typedef enum AccountType : NSUInteger {
    ///The account contains a username and password.
    kAccountTypeUsernamePassword = 0,
    
    ///The account contains an auth token.
    kAccountTypeToken = 1,
} AccountType;

///The Account class encapsulates an account in Pinna.
///
/// \seealso(AccountManager)
@interface Account : NSObject <NSCoding>

///Initialize the receiver with a given service identifier and account type.
///
/// \param  serviceIdentifier   The service identifier. Required.
/// \param  type                The type of account being represented.
///
/// \result A fully initialized account.
///
///This is the recommended initializer.
- (id)initWithServiceIdentifier:(NSString *)serviceIdentifier type:(AccountType)type;

#pragma mark - Properties

///The type of account.
@property (RK_NONATOMIC_IOSONLY) AccountType type;

///The service descriptor associated with the account.
///
///This property may be nil if an Account was created for a service which is no longer available.
@property (readonly, RK_NONATOMIC_IOSONLY) ServiceDescriptor *descriptor;

///The identifier of the service that this account belongs to.
///
///Must be non-nil before `.password` can be set.
@property (copy, RK_NONATOMIC_IOSONLY) NSString *serviceIdentifier;

///Whether or not the account is disabled.
///
///Defaults to NO.
@property (RK_NONATOMIC_IOSONLY) BOOL disabled;

#pragma mark -

///The username of the account.
///
///Must be non-nil before `.password` can be set.
@property (copy, RK_NONATOMIC_IOSONLY) NSString *username;

///The password of the account.
///
///If `Account_StorePasswordsInKeychain` is set to `1`, this property
///is stored in the user's keychain and not in the Account object.
///
///The `.username` and `.serviceIdentifier` properties
///must be set before this property can be set.
@property (copy, RK_NONATOMIC_IOSONLY) NSString *password;

///The email of the account.
@property (copy, RK_NONATOMIC_IOSONLY) NSString *email;

#pragma mark -

///The OAuth token of the account.
@property (copy, RK_NONATOMIC_IOSONLY) NSString *token;

#pragma mark -

///Whether or not the account is authorized.
@property (readonly, RK_NONATOMIC_IOSONLY) BOOL isAuthorized;

#pragma mark -

///Any custom settings associated with an account.
///
///This property is lazily initialized and will only be stored if values are present.
@property (readonly, nonatomic) NSMutableDictionary *settings;

@end
