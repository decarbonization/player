//
//  SocialPane.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 6/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SocialPane.h"
#import "RoundaboutKitMac.h"
#import "RKSideSheetView.h"

#import "AppDelegate.h"
#import "ArtworkCache.h"
#import "AudioPlayer.h"
#import "LastFMSession.h"
#import "LastFMDefines.h"

#import "AccountManager.h"
#import "ServiceDescriptor.h"

#import "Library.h"
#import "ExfmSession.h"
#import "ExfmAccountServiceViewController.h"
#import "LastfmAccountServiceViewController.h"

@interface SocialPane ()

@property (nonatomic) RKSideSheetView *currentSheet;

@end

@implementation SocialPane

- (void)dealloc
{
	[mExfmSession removeObserver:self forKeyPath:@"username"];
	[self removeObserver:self forKeyPath:@"exFMLogoutButtonTitle"];
	[self removeObserver:self forKeyPath:@"lastFMLogoutButtonTitle"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
	if((self = [super init]))
	{
		mScrobbler = [LastFMSession defaultSession];
		mCachedUserInfo = [NSMutableDictionary new];
		
		mExfmSession = [ExfmSession defaultSession];
	}
	
	return self;
}

- (void)loadView
{
	[super loadView];
	
	[[NSUserDefaults standardUserDefaults] addObserver:self 
											forKeyPath:kLastFMCachedUserInfoDefaultsKey 
											   options:0 
											   context:NULL];
	
	[mExfmSession addObserver:self forKeyPath:@"username" options:0 context:NULL];
	
	[self addObserver:self forKeyPath:@"exFMLogoutButtonTitle" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"lastFMLogoutButtonTitle" options:0 context:NULL];
	
	NSDictionary *cachedUserInfo = RKGetPersistentObject(kLastFMCachedUserInfoDefaultsKey);
	if(cachedUserInfo)
		[mCachedUserInfo setDictionary:cachedUserInfo];
	else
		[mCachedUserInfo removeAllObjects];
	
	[self fetchLastFMUserIcon];
	[self fetchExFMUserIcon];
	
	oExFMUserIcon.innerShadow = RKShadowMake([NSColor colorWithDeviceWhite:0.0 alpha:0.49], 4.0, NSMakeSize(0.0, -1.0));
	[oExFMUserIcon bind:@"image" toObject:self withKeyPath:@"exFMUserIcon" options:nil];
	
	oLastFMUserIcon.innerShadow = RKShadowMake([NSColor colorWithDeviceWhite:0.0 alpha:0.49], 4.0, NSMakeSize(0.0, -1.0));
	[oLastFMUserIcon bind:@"image" toObject:self withKeyPath:@"lastFMUserIcon" options:nil];
	
	[oExFMDeauthorizeButton sizeToFit];
	[oLastFMDeauthorizeButton sizeToFit];
}

#pragma mark - Properties

- (NSString *)name
{
	return @"Accounts";
}

- (NSImage *)icon
{
	return [NSImage imageNamed:@"AccountsIcon"];
}

#pragma mark - Interface Hooks

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(object == [NSUserDefaults standardUserDefaults] && [keyPath isEqualToString:kLastFMCachedUserInfoDefaultsKey])
	{
		[self willChangeValueForKey:@"lastFMUserInfo"];
		
		NSDictionary *cachedUserInfo = RKGetPersistentObject(kLastFMCachedUserInfoDefaultsKey);
		if(cachedUserInfo)
			[mCachedUserInfo setDictionary:cachedUserInfo];
		else
			[mCachedUserInfo removeAllObjects];
		
		[self didChangeValueForKey:@"lastFMUserInfo"];
		
		[self fetchLastFMUserIcon];
	}
	else if(object == mExfmSession && [keyPath isEqualToString:@"username"])
	{
		if(mExfmSession.username)
		{
			[self fetchExFMUserIcon];
		}
		else
		{
			[self willChangeValueForKey:@"exFMUserIcon"];
			mCachedExFMUserIcon = nil;
			[self didChangeValueForKey:@"exFMUserIcon"];
		}
	}
	else if(object == self)
	{
		if([keyPath isEqualToString:@"exFMLogoutButtonTitle"])
			[oExFMDeauthorizeButton sizeToFit];
		else if([keyPath isEqualToString:@"lastFMLogoutButtonTitle"])
			[oLastFMDeauthorizeButton sizeToFit];
	}
}

#pragma mark -

- (void)fetchExFMUserIcon
{
	if(!mExfmSession.isAuthorized)
	{
		[self willChangeValueForKey:@"exFMUserIcon"];
		mCachedExFMUserIcon = nil;
		[self didChangeValueForKey:@"exFMUserIcon"];
		
		return;
	}
	
    if(oExFMUserIcon.image == nil)
        [oExFMUserIconLoadingIndicator startAnimation:nil];
	
    RKPromise *userPromise = [mExfmSession me];
	[userPromise then:^(NSDictionary *userResult) {
		NSString *imageURLString = [userResult valueForKeyPath:@"user.image.original"];
		NSURL *imageURL = [NSURL URLWithString:imageURLString];
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			NSError *error = nil;
			NSData *iconData = [NSData dataWithContentsOfURL:imageURL options:0 error:&error];
			if(!iconData)
			{
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [oExFMUserIconLoadingIndicator stopAnimation:nil];
                }];
                
				NSLog(@"Could not load Ex.fm user icon. Error {%@}", error);
				
                return;
			}
			
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				[self willChangeValueForKey:@"exFMUserIcon"];
				mCachedExFMUserIcon = [[NSImage alloc] initWithData:iconData];
				[self didChangeValueForKey:@"exFMUserIcon"];
                
                [oExFMUserIconLoadingIndicator stopAnimation:nil];
			}];
		});
	} otherwise:^(NSError *error) {
		NSLog(@"Could not fetch user icon, bummer. Error %@", error);
        
        [oExFMUserIconLoadingIndicator stopAnimation:nil];
	}];
}

- (void)fetchLastFMUserIcon
{
	NSString *imageLocationString = [[[RKGetPersistentObject(kLastFMCachedUserInfoDefaultsKey) objectForKey:@"image"] objectAtIndex:0] objectForKey:@"#text"];
	if(imageLocationString)
	{
        if(oLastFMUserIcon.image == nil)
            [oLastFMUserIconLoadingIndicator startAnimation:nil];
        
		NSURL *imageLocation = [NSURL URLWithString:imageLocationString];
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			NSError *error = nil;
			NSData *iconData = [NSData dataWithContentsOfURL:imageLocation options:0 error:&error];
			if(!iconData)
			{
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [oLastFMUserIconLoadingIndicator stopAnimation:nil];
                }];
                
				NSLog(@"Could not load Last.fm user icon. Error {%@}", error);
				
                return;
			}
			
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				[self willChangeValueForKey:@"lastFMUserIcon"];
				mCachedLastFMUserIcon = [[NSImage alloc] initWithData:iconData];
				[self didChangeValueForKey:@"lastFMUserIcon"];
                
                [oLastFMUserIconLoadingIndicator stopAnimation:nil];
			}];
		});
	}
	else
	{
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			[self willChangeValueForKey:@"lastFMUserIcon"];
			mCachedLastFMUserIcon = nil;
			[self didChangeValueForKey:@"lastFMUserIcon"];
		}];
	}
}


#pragma mark - • Bindings

+ (NSSet *)keyPathsForValuesAffectingIsExFMAuthorized
{
	return [NSSet setWithObjects:@"mExfmSession.isAuthorized", nil];
}

- (BOOL)isExFMAuthorized
{
	return mExfmSession.isAuthorized;
}

+ (NSSet *)keyPathsForValuesAffectingExFMLogoutButtonTitle
{
	return [NSSet setWithObjects:@"mExfmSession.username", nil];
}

- (NSString *)exFMLogoutButtonTitle
{
	return [NSString stringWithFormat:@"Disconnect %@", mExfmSession.username ?: @""];
}

- (NSImage *)exFMUserIcon
{
	return mCachedExFMUserIcon;
}

#pragma mark -

+ (NSSet *)keyPathsForValuesAffectingLastFMLogoutButtonTitle
{
	return [NSSet setWithObjects:@"mScrobbler.isAuthorized", @"lastFMUserInfo", nil];
}

- (NSString *)lastFMLogoutButtonTitle
{
	NSString *username = [RKGetPersistentObject(kLastFMCachedUserInfoDefaultsKey) valueForKey:@"name"];
	return [NSString stringWithFormat:@"Disconnect %@", username ?: @""];
}

- (NSImage *)lastFMUserIcon
{
	return mCachedLastFMUserIcon;
}

#pragma mark -

+ (NSSet *)keyPathsForValuesAffectingIsLastFMAuthorized
{
	return [NSSet setWithObjects:@"mScrobbler.isAuthorizing", @"mScrobbler.isAuthorized", nil];
}

- (BOOL)isLastFMAuthorized
{
	return mScrobbler.isAuthorized;
}

@synthesize lastFMUserInfo = mCachedUserInfo;

#pragma mark - Actions

- (IBAction)cancelSheet:(id)sender
{
    [self.currentSheet dismiss:YES completionHandler:^{
        self.currentSheet = nil;
    }];
}

#pragma mark - Ex.fm

- (IBAction)connectToExfm:(id)sender
{
	if(self.currentSheet)
		return;
	
    self.currentSheet = [RKSideSheetView new];
    
    ExfmAccountServiceViewController *exfmAccountController = [[ExfmAccountServiceViewController alloc] initWithServiceDescriptor:[ServiceDescriptor descriptorWithIdentifier:kAccountServiceIdentifierExfm] completionHandler:^(BOOL succeeded) {
        [self willChangeValueForKey:@"isExFMAuthorized"];
        [self didChangeValueForKey:@"isExFMAuthorized"];
        
        [self fetchExFMUserIcon];
        
        [self.currentSheet dismiss:YES completionHandler:^{
            self.currentSheet = nil;
        }];
    }];
    exfmAccountController.navigationItem.leftView = [[RKBarButton alloc] initWithType:kRKBarButtonTypeDefault
                                                                                title:@"Cancel"
                                                                               target:self
                                                                               action:@selector(cancelSheet:)];
    [self.currentSheet.navigationController pushViewController:exfmAccountController animated:NO];
    [self.currentSheet showInView:self.view animated:YES completionHandler:nil];
}

#pragma mark -

- (IBAction)disconnectFromExfm:(id)sender
{
    AccountManager *accountManager = [AccountManager sharedAccountManager];
    Account *exfmAccount = [accountManager accountWithIdentifier:kAccountServiceIdentifierExfm];
    [[accountManager deleteAccount:exfmAccount] then:^(id data) {
        [self willChangeValueForKey:@"isExFMAuthorized"];
        [self didChangeValueForKey:@"isExFMAuthorized"];
    } otherwise:^(NSError *error) {
        NSLog(@"Could not log out of exfm. %@", error);
    }];
}

#pragma mark - Last.fm

- (IBAction)connectToLastFM:(id)sender
{
	if(self.currentSheet)
		return;
	
    self.currentSheet = [RKSideSheetView new];
    
    LastfmAccountServiceViewController *lastfmAccountController = [[LastfmAccountServiceViewController alloc] initWithServiceDescriptor:[ServiceDescriptor descriptorWithIdentifier:kAccountServiceIdentifierLastfm] completionHandler:^(BOOL succeeded) {
        [self willChangeValueForKey:@"isLastFMAuthorized"];
        [self didChangeValueForKey:@"isLastFMAuthorized"];
        
        [self fetchLastFMUserIcon];
        
        [self.currentSheet dismiss:YES completionHandler:^{
            self.currentSheet = nil;
        }];
    }];
    lastfmAccountController.navigationItem.leftView = [[RKBarButton alloc] initWithType:kRKBarButtonTypeDefault
                                                                                  title:@"Cancel"
                                                                                 target:self
                                                                                 action:@selector(cancelSheet:)];
    [self.currentSheet.navigationController pushViewController:lastfmAccountController animated:NO];
    [self.currentSheet showInView:self.view animated:YES completionHandler:nil];
}

- (IBAction)disconnectFromLastFM:(id)sender
{
	AccountManager *accountManager = [AccountManager sharedAccountManager];
    Account *lastFMAccount = [accountManager accountWithIdentifier:kAccountServiceIdentifierLastfm];
    [[accountManager deleteAccount:lastFMAccount] then:^(id data) {
        [self willChangeValueForKey:@"isLastFMAuthorized"];
        [self didChangeValueForKey:@"isLastFMAuthorized"];
    } otherwise:^(NSError *error) {
        NSLog(@"Could not log out of last.fm. %@", error);
    }];
}

@end
