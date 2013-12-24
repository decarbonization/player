//
//  ServiceDescriptor.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 4/21/13.
//
//

#ifndef ServiceDescriptor_h
#define ServiceDescriptor_h 1

#import <Foundation/Foundation.h>
#import "Account.h"
#import "ServiceAuthorizationPresenter.h"
#import "Service.h"

///The identifier of the exfm service.
RK_EXTERN NSString *const kAccountServiceIdentifierExfm;

#if TARGET_OS_IPHONE

@class UIImage;

#else

@class NSImage;

///The identifier of the Last.fm service. OS X only.
RK_EXTERN NSString *const kAccountServiceIdentifierLastfm;

#endif /* TARGET_OS_IPHONE */


///The ServiceDescriptor class encapsulates information on services in Pinna.
///
///Services can be registered and unregistered at any time.
///They are partially tied to the lifecycle of Account objects.
///
/// \seealso(Account, AccountManager, Service, ServicePresenter)
@interface ServiceDescriptor : NSObject

#pragma mark - Available Services

///Registers a given service descriptor with the service descriptor cluster.
///
/// \param  service The service to register for inclusion in `+[ServiceDescriptor registeredServices]`. Must have an identifier. Required.
///
///This method is thread-safe on OS X, and not on iOS.
+ (void)registerDescriptor:(ServiceDescriptor *)service;

///Unregisters a given service descriptor with the service descriptor cluster.
///
/// \param  service The service to unregister from inclusion in `+[ServiceDescriptor registeredServices]`. Must have an identifier. Required.
///
///This method is thread-safe on OS X, and not on iOS.
+ (void)unregisterDescriptor:(ServiceDescriptor *)service;

#pragma mark -

///Returns all available services.
///
///This method is thread-safe on OS X, and not on iOS.
+ (NSArray *)registeredServices;

///Returns an ServiceDescriptor instance matching a given identifier.
///
/// \param  identifier  The identifier of the service class to find.
///
/// \result An ServiceDescriptor instance if one can be found for the given identifier, nil otherwise.
///
///This method is thread-safe on OS X, and not on iOS.
+ (ServiceDescriptor *)descriptorWithIdentifier:(NSString *)identifier;

#pragma mark - Properties

///The type of account this service uses.
@property (RK_NONATOMIC_IOSONLY) AccountType accountType;

///The identifier of the service.
///
///Used by the `AccountManager` class.
@property (copy, RK_NONATOMIC_IOSONLY) NSString *identifier;

#pragma mark -

///The name of the service.
@property (copy, RK_NONATOMIC_IOSONLY) NSString *name;

///The human-readable, localized description of the service.
@property (copy, RK_NONATOMIC_IOSONLY) NSString *localizedDescription;

#if TARGET_OS_IPHONE

///The logo of the service.
@property (nonatomic) UIImage *logo;

#else

///The logo of the service.
@property NSImage *logo;

#endif /* TARGET_OS_IPHONE */

#pragma mark - Vending Accounts

///Returns a new empty account for the receiver.
- (Account *)emptyAccount;

///The presenter class for the service.
@property (RK_NONATOMIC_IOSONLY) Class <ServiceAuthorizationPresenter> authorizationPresenterClass;

///The scrobbler of the service.
@property (weak, RK_NONATOMIC_IOSONLY) id <Service> service;

@end

#endif /* ServiceDescriptor_h */
