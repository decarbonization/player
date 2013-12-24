//
//  LastfmAccountServiceViewController.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/8/13.
//
//

#import "LastfmAccountServiceViewController.h"
#import "RoundaboutKitMac.h"

#import "LastFMSession.h"
#import "LastFMDefines.h"

#import "ServiceDescriptor.h"
#import "AccountManager.h"

@interface LastfmAccountServiceViewController ()

@end

@implementation LastfmAccountServiceViewController

- (id)initWithServiceDescriptor:(ServiceDescriptor *)serviceDescriptor completionHandler:(ServiceAuthorizationPresenterCompletionHandler)completionHandler
{
    NSParameterAssert(serviceDescriptor);
    
    if((self = [super init])) {
        self.serviceDescriptor = serviceDescriptor;
        self.completionHandler = completionHandler;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Last.fm";
}

#pragma mark - Actions

- (void)applicationDidBecomeActiveFromAuthorizationProcess:(NSNotification *)notification
{
    LastFMSession *session = [LastFMSession defaultSession];
    
    [[session finishAuthorization] then:^(NSDictionary *response) {
        Account *lastfmAccount = [self.serviceDescriptor emptyAccount];
        lastfmAccount.token = session.sessionKey;
        [[AccountManager sharedAccountManager] saveAccount:lastfmAccount];
		
        [[session userInfo] then:^(id response) {
            RKSetPersistentObject(kLastFMCachedUserInfoDefaultsKey, RKFilterOutNSNull(response[@"user"]));
            
            if(_completionHandler)
                _completionHandler(YES);
        } otherwise:^(NSError *error) {
            NSLog(@"Could not update cached user info. Error {%@}", [error localizedDescription]);
        }];
    } otherwise:^(NSError *error) {
        [[NSAlert alertWithMessageText:@"Could Not Sign In"
                         defaultButton:@"OK"
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:@"%@", [error localizedDescription]] runModal];
        
        if(_completionHandler)
            _completionHandler(NO);
    }];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSApplicationDidBecomeActiveNotification
                                                  object:NSApp];
}

- (IBAction)authorize:(id)sender
{
    LastFMSession *session = [LastFMSession defaultSession];
    if(session.isAuthorizing)
		[session cancelAuthorization];
    
    RK_CAST(RKBarButton, self.navigationItem.leftView).enabled = NO;
    [self.authorizeButton setHidden:YES];
    [self.loadingActivityIndicator startAnimation:nil];
    
    [[session startAuthorization] then:^(NSURL *authorizationURL) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActiveFromAuthorizationProcess:)
                                                     name:NSApplicationDidBecomeActiveNotification
                                                   object:NSApp];
        
        [[NSWorkspace sharedWorkspace] openURL:authorizationURL];
    } otherwise:^(NSError *error) {
        [[NSAlert alertWithMessageText:@"Could Not Sign In"
                         defaultButton:@"OK"
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:@"%@", [error localizedDescription]] runModal];
        
        if(_completionHandler)
            _completionHandler(NO);
    }];
}

@end
