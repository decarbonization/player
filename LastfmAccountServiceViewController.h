//
//  LastfmAccountServiceViewController.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/8/13.
//
//

#import "RKViewController.h"
#import "ServiceAuthorizationPresenter.h"

@class ServiceDescriptor;

///The LastfmAccountServiceViewController class encapsulates authorizing Pinna with Last.fm.
@interface LastfmAccountServiceViewController : RKViewController <ServiceAuthorizationPresenter>

#pragma mark - Outlets

///The button the user presses to begin authorizing through Last.fm.
@property (assign) IBOutlet NSButton *authorizeButton;

///The activity indicator.
@property (assign) IBOutlet NSProgressIndicator *loadingActivityIndicator;

#pragma mark - Properties

///The service being described by this controller.
@property (nonatomic) ServiceDescriptor *serviceDescriptor;

///The completion handler block.
@property (nonatomic, copy) ServiceAuthorizationPresenterCompletionHandler completionHandler;

#pragma mark - Actions

///Begin the authorization process.
- (IBAction)authorize:(id)sender;

@end
