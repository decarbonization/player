//
//  AccountServiceViewController.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/8/13.
//
//

#import "RKViewController.h"
#import "ServiceAuthorizationPresenter.h"

@class ServiceDescriptor, RKView;

///The AccountServiceViewController class encapsulates a generic shell from which all
///credential-based services can descend from to provide their authentication presentation class.
///
///The AccountServiceViewController will create accounts automatically. Subclasses
///only have to concern themselves with updating their underlying objects.
///
///See methods in `Abstract Methods`
@interface AccountServiceViewController : RKViewController <ServiceAuthorizationPresenter>

///Initialize the receiver with a given service descriptor.
///
/// \param  serviceDescriptor   The service descriptor. Required.
/// \param  completionHandler   The block to invoke when the service is signed up/into. Optional.
///
/// \result A fully initialized account service view controller.
///
///This is the primitive initializer.
- (id)initWithServiceDescriptor:(ServiceDescriptor *)serviceDescriptor completionHandler:(ServiceAuthorizationPresenterCompletionHandler)completionHandler;

#pragma mark - Outlets

///The view that contains the email field. Lowered in from the top of
///the credentials container when the user presses « Need Account? »
@property (assign) IBOutlet NSView *emailContainer;

///The email text field.
@property (assign) IBOutlet NSTextField *emailField;

#pragma mark -

///The view that contains all of the credential fields. Vertically centered.
@property (assign) IBOutlet NSView *credentialsContainer;

///The username text field.
@property (assign) IBOutlet NSTextField *usernameField;

///The password text field.
@property (assign) IBOutlet NSTextField *passwordField;

#pragma mark -

///The button to toggle between sign in and sign up modes.
@property (assign) IBOutlet NSButton *modeToggleButton;

#pragma mark -

///The loading view overlay.
@property (assign) IBOutlet RKView *loadingView;

///The loading activity indicator.
@property (assign) IBOutlet NSProgressIndicator *loadingActivityIndicator;

#pragma mark - Properties

///The service being described by this controller.
@property (nonatomic) ServiceDescriptor *serviceDescriptor;

///The completion handler block.
@property (nonatomic, copy) ServiceAuthorizationPresenterCompletionHandler completionHandler;

#pragma mark - Actions

///Toggles between sign in and sign up modes.
- (IBAction)toggleMode:(id)sender;

#pragma mark - Abstract Methods

///Returns a BOOL indicating whether not a given string is a valid email.
///
///The default implementation of this method delegates to ExfmSession.
- (BOOL)isValidEmail:(NSString *)email;

///Returns a BOOL indicating whether not a given string is a valid username.
///
///The default implementation of this method delegates to ExfmSession.
- (BOOL)isValidUsername:(NSString *)username;

///Returns a BOOL indicating whether not a given string is a valid password.
///
///The default implementation of this method delegates to ExfmSession.
- (BOOL)isValidPassword:(NSString *)password;

#pragma mark -

///Returns a promise to log into the receiver's represented serivce using a username and password.
///
/// \param  username    The username to sign in with.
/// \param  password    The password to sign in with.
///
/// \result A promise that will log into the represented service, updating the service's instance upon success.
///
- (RKPromise *)loginPromiseForUsername:(NSString *)username password:(NSString *)password;

///Returns a promise to sign up for the receiver's represented service using specified credentials
///
/// \param  email       The email to sign up with.
/// \param  username    The username to sign up with.
/// \param  password    The password to sign up with.
///
/// \param  A promise that will sign up with the represented service, logging into the service's instance upon success.
///
- (RKPromise *)signUpPromiseForEmail:(NSString *)email username:(NSString *)username password:(NSString *)password;

#pragma mark -

///The generic override point for the forgot password button.
///
///Default implementation does nothing.
- (IBAction)forgotPassword:(id)sender;

@end
