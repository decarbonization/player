//
//  ServiceAuthorizationPresenter.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 4/21/13.
//
//

#ifndef ServiceAuthorizationPresenter_h
#define ServiceAuthorizationPresenter_h 1

#import <Foundation/Foundation.h>

@class ServiceDescriptor;

///A block called when a service authorization view controller has completed.
///
/// \param  succeeded   Whether or not the authorization was successful.
typedef void(^ServiceAuthorizationPresenterCompletionHandler)(BOOL succeeded);

///The ServiceAuthorizationPresenter protocol describes the methods required
///for a controller to be used as an account service presenter.
///
///A presenter is an object which provides an interface to either create
///a new account on a service, or to log into an existing account.
///
///It is expected that an account presenter will take care of creating,
///or updating any relevant accounts. The account editing interface
///expects to simply pass control to the presenter.
///
///Under OS X, it is expected that presenters will be RKViewControllers;
///under iOS, it is expected that presenters will be UIViewControllers.
@protocol ServiceAuthorizationPresenter <NSObject>

//Shut up the compiler.
+ (instancetype)alloc;


///Initialize the receiver with a given service descriptor.
///
/// \param  serviceDescriptor   The service descriptor. Required.
/// \param  completionHandler   The block to invoke when the service is signed up/into. Optional.
///
/// \result A fully initialized account service view controller.
///
///This is the primitive initializer.
- (id)initWithServiceDescriptor:(ServiceDescriptor *)serviceDescriptor completionHandler:(ServiceAuthorizationPresenterCompletionHandler)completionHandler;

@end

#endif /* ServiceAuthorizationPresenter_h */
