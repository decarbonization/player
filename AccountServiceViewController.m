//
//  AccountServiceViewController.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/8/13.
//
//

#import "AccountServiceViewController.h"
#import "RoundaboutKitMac.h"

#import "ServiceDescriptor.h"
#import "AccountManager.h"

#import "ExfmSession.h"

@interface AccountServiceViewController ()

@property (nonatomic) BOOL inAccountCreationMode;

@end

@implementation AccountServiceViewController

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
    
    self.loadingView.backgroundColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.8];
    
    self.navigationItem.title = self.serviceDescriptor.name ?: @"Account";
    
    RKBarButton *signInButton = [[RKBarButton alloc] initWithType:kRKBarButtonTypeDefault
                                                            title:@"Sign In"
                                                           target:self
                                                           action:@selector(signIn:)];
    [signInButton setKeyEquivalent:@"\r"];
    self.navigationItem.rightView = signInButton;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.view.window makeFirstResponder:self.usernameField];
}

#pragma mark - Loading View

- (void)showLoadingView
{
    if(self.loadingView.superview != nil)
        return;
    
    self.loadingView.alphaValue = 0.0;
    self.loadingView.frame = self.view.bounds;
    [self.view addSubview:self.loadingView];
    
    [self.loadingActivityIndicator startAnimation:nil];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.25;
        
        [[self.loadingView animator] setAlphaValue:1.0];
    } completionHandler:^{
        
    }];
}

- (void)hideLoadingView
{
    if(self.loadingView.superview == nil)
        return;
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.25;
        
        [[self.loadingView animator] setAlphaValue:0.0];
    } completionHandler:^{
        [self.loadingView removeFromSuperview];
        [self.loadingActivityIndicator stopAnimation:nil];
    }];
}

#pragma mark - Changing Mode

- (void)enterAccountCreationMode
{
    if(self.inAccountCreationMode)
        return;
    
    self.emailField.nextKeyView = self.usernameField;
    self.usernameField.nextKeyView = self.passwordField;
    self.passwordField.nextKeyView = self.emailField;
    
    NSRect credentialsContainerFrame = self.credentialsContainer.frame;
    
    NSRect emailContainerFrame = self.emailContainer.frame;
    emailContainerFrame.origin.x = 0.0;
    emailContainerFrame.origin.y = NSHeight(credentialsContainerFrame);
    emailContainerFrame.size.width = NSWidth(credentialsContainerFrame);
    self.emailContainer.frame = emailContainerFrame;
    self.emailContainer.alphaValue = 0.0;
    [self.credentialsContainer addSubview:self.emailContainer];
    
    credentialsContainerFrame.size.height += NSHeight(emailContainerFrame);
    credentialsContainerFrame.origin.y -= round(NSHeight(emailContainerFrame) / 2.0);
    
    [self.view.window makeFirstResponder:nil];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [context setDuration:0.2];
        
        [[self.emailContainer animator] setAlphaValue:1.0];
        [[self.credentialsContainer animator] setFrame:credentialsContainerFrame];
    } completionHandler:^{
        [self.view.window makeFirstResponder:self.emailField];
    }];
    
    self.modeToggleButton.title = @"Already Have Account";
    self.navigationItem.rightView = [[RKBarButton alloc] initWithType:kRKBarButtonTypeDefault
                                                                title:@"Create"
                                                               target:self
                                                               action:@selector(createAccount:)];
    
    self.inAccountCreationMode = YES;
}

- (void)enterSignInMode
{
    if(!self.inAccountCreationMode)
        return;
    
    self.usernameField.nextKeyView = self.passwordField;
    self.passwordField.nextKeyView = self.usernameField;
    
    NSRect emailContainerFrame = self.emailContainer.frame;
    NSRect credentialsContainerFrame = self.credentialsContainer.frame;
    credentialsContainerFrame.size.height -= NSHeight(emailContainerFrame);
    credentialsContainerFrame.origin.y += round(NSHeight(emailContainerFrame) / 2.0);
    
    [self.view.window makeFirstResponder:nil];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [context setDuration:0.2];
        [[self.emailContainer animator] setAlphaValue:0.0];
        [[self.credentialsContainer animator] setFrame:credentialsContainerFrame];
    } completionHandler:^{
        [self.view.window makeFirstResponder:self.usernameField];
    }];
    
    self.modeToggleButton.title = @"Need Account?";
    self.navigationItem.rightView = [[RKBarButton alloc] initWithType:kRKBarButtonTypeDefault
                                                                title:@"Sign In"
                                                               target:self
                                                               action:@selector(signIn:)];
    
    self.inAccountCreationMode = NO;
}

#pragma mark - Actions

- (IBAction)toggleMode:(id)sender
{
    if(self.inAccountCreationMode)
        [self enterSignInMode];
    else
        [self enterAccountCreationMode];
}

- (IBAction)signIn:(id)sender
{
    NSString *username = [[self.usernameField stringValue] lowercaseString];
	NSString *password = [self.passwordField stringValue];
	if([username length] == 0 || ![self isValidUsername:username] ||
	   [password length] == 0 || ![self isValidPassword:password])
	{
		NSBeep();
		
		if([username length] == 0 || ![self isValidUsername:username])
			[self.usernameField setTextColor:[NSColor redColor]];
		
		if([password length] == 0 || ![self isValidPassword:password])
			[self.passwordField setTextColor:[NSColor redColor]];
		
		return;
	}
	
	[self.usernameField setEnabled:NO];
	[self.passwordField setEnabled:NO];
	[self showLoadingView];
    
    RK_CAST(RKBarButton, self.navigationItem.leftView).enabled = NO;
    RK_CAST(RKBarButton, self.navigationItem.rightView).enabled = NO;
	
	void(^commonActions)() = ^{
        [self hideLoadingView];
        
		[self.usernameField setEnabled:YES];
		[self.passwordField setEnabled:YES];
		
		RK_CAST(RKBarButton, self.navigationItem.leftView).enabled = YES;
        RK_CAST(RKBarButton, self.navigationItem.rightView).enabled = YES;
	};
	
    RKPromise *loginPromise = [self loginPromiseForUsername:username password:password];
    [loginPromise then:^(id unused) {
        Account *newAccount = [self.serviceDescriptor emptyAccount];
        newAccount.username = username;
        newAccount.password = password;
        [[AccountManager sharedAccountManager] saveAccount:newAccount];
        
        commonActions();
        
        if(_completionHandler)
            _completionHandler(YES);
    } otherwise:^(NSError *error) {
        commonActions();
        
        [self.usernameField setTextColor:[NSColor redColor]];
        [self.passwordField setTextColor:[NSColor redColor]];
        
        [[NSAlert alertWithMessageText:@"Wrong Credentials"
                         defaultButton:nil
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:@"The username or password you entered is incorrect."] runModal];
    }];
}

- (IBAction)createAccount:(id)sender
{
    NSString *email = [self.emailField stringValue];
	NSString *username = [[self.usernameField stringValue] lowercaseString];
	NSString *password = [self.passwordField stringValue];
	if([email length] == 0 || ![self isValidEmail:email] ||
	   [username length] == 0 || ![self isValidUsername:username] ||
	   [password length] == 0 || ![self isValidPassword:password])
	{
		NSBeep();
		
		if([email length] == 0 || ![self isValidEmail:email])
			[self.emailField setTextColor:[NSColor redColor]];
		
		if([username length] == 0 || ![self isValidUsername:username])
			[self.usernameField setTextColor:[NSColor redColor]];
		
		if([password length] == 0 || ![self isValidPassword:password])
			[self.passwordField setTextColor:[NSColor redColor]];
		
		return;
	}
	
	[self.emailField setEnabled:NO];
	[self.usernameField setEnabled:NO];
	[self.passwordField setEnabled:NO];
	[self showLoadingView];
    
	RK_CAST(RKBarButton, self.navigationItem.leftView).enabled = NO;
    RK_CAST(RKBarButton, self.navigationItem.rightView).enabled = NO;
	
	void(^commonActions)() = ^{
        [self hideLoadingView];
        
		[self.emailField setEnabled:YES];
		[self.usernameField setEnabled:YES];
		[self.passwordField setEnabled:YES];
		
		RK_CAST(RKBarButton, self.navigationItem.leftView).enabled = YES;
        RK_CAST(RKBarButton, self.navigationItem.rightView).enabled = YES;
	};
	
    RKPromise *signUpPromise = [self signUpPromiseForEmail:email username:username password:password];
    [signUpPromise then:^(id unused) {
        Account *newAccount = [self.serviceDescriptor emptyAccount];
        newAccount.username = username;
        newAccount.password = password;
        [[AccountManager sharedAccountManager] saveAccount:newAccount];
        
        commonActions();
        
        if(_completionHandler)
            _completionHandler(YES);
    } otherwise:^(NSError *error) {
        commonActions();
        
        [self.emailField setTextColor:[NSColor redColor]];
        [self.usernameField setTextColor:[NSColor redColor]];
        [self.passwordField setTextColor:[NSColor redColor]];
        
        [[NSAlert alertWithMessageText:@"Could Not Create Account"
                         defaultButton:nil
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:@"%@", [error localizedDescription]] runModal];
    }];
}

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor
{
	[self.emailField setTextColor:[NSColor blackColor]];
	[self.usernameField setTextColor:[NSColor blackColor]];
	[self.passwordField setTextColor:[NSColor blackColor]];
	
	return YES;
}

#pragma mark - Abstract Methods

- (BOOL)isValidEmail:(NSString *)email
{
    return [ExfmSession isValidEmailAddress:email];
}

- (BOOL)isValidUsername:(NSString *)username
{
    return [ExfmSession isValidUsername:username];
}

- (BOOL)isValidPassword:(NSString *)password
{
    return [ExfmSession isValidPassword:password];
}

#pragma mark -

- (RKPromise *)loginPromiseForUsername:(NSString *)username password:(NSString *)password
{
    return nil;
}

- (RKPromise *)signUpPromiseForEmail:(NSString *)email username:(NSString *)username password:(NSString *)password
{
    return nil;
}

#pragma mark -

- (IBAction)forgotPassword:(id)sender
{
    
}

@end
