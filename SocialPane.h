//
//  SocialPane.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 6/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PreferencesPane.h"

@class LastFMSession, ExfmSession;
@class RKChromeView;
@interface SocialPane : PreferencesPane
{
	///The ex.fm user icon view.
	IBOutlet RKChromeView *oExFMUserIcon;
    
    ///The indicator to show the exfm user icon is loading.
    IBOutlet NSProgressIndicator *oExFMUserIconLoadingIndicator;
	
	///The button used to deauthorize ex.fm
	IBOutlet NSButton *oExFMDeauthorizeButton;
	
	
	///The button used to authorize last.fm
	IBOutlet NSButton *oLastFMAuthorizeButton;
	
	///The button used to deauthorize last.fm
	IBOutlet NSButton *oLastFMDeauthorizeButton;
	
	///The last.fm user icon view.
	IBOutlet RKChromeView *oLastFMUserIcon;
	
    ///The indicator to show the last.fm user icon is loading.
    IBOutlet NSProgressIndicator *oLastFMUserIconLoadingIndicator;
    
	/** Internal State **/
	
	///The Ex.fm session.
	ExfmSession *mExfmSession;
	
	///The cached ex.fm user icon.
	NSImage *mCachedExFMUserIcon;
	
	
	///The scrobbler of Player.
	LastFMSession *mScrobbler;
	
	///The cached last.fm user icon.
	NSImage *mCachedLastFMUserIcon;
	
	///The cached user info.
	NSMutableDictionary *mCachedUserInfo;
}

#pragma mark - Interface Hooks

#pragma mark • Bindings

///Whether or not Ex.fm is authorized.
@property (nonatomic, readonly) BOOL isExFMAuthorized;

///The title of the Ex.fm logout button.
@property (nonatomic, readonly) NSString *exFMLogoutButtonTitle;

///The user icon if logged into Ex.fm.
@property (nonatomic, readonly) NSImage *exFMUserIcon;

#pragma mark -

///Whether or not Last.fm is authorized.
@property (nonatomic, readonly) BOOL isLastFMAuthorized;

///The user info of the logged in Last.fm user, if applicable.
@property (nonatomic, readonly) NSDictionary *lastFMUserInfo;

///The title of the last.fm logout button.
@property (nonatomic, readonly) NSString *lastFMLogoutButtonTitle;

///The user icon if logged into Last.fm.
@property (nonatomic, readonly) NSImage *lastFMUserIcon;

#pragma mark - • Actions

///Causes the receiver to show the login sheet for Ex.fm.
- (IBAction)connectToExfm:(id)sender;

///Causes the receiver to log out of Ex.fm.
- (IBAction)disconnectFromExfm:(id)sender;

#pragma mark -

///Authorize Pinna for Last.fm use.
- (IBAction)connectToLastFM:(id)sender;

///Deauthorize Pinna for Last.fm use.
- (IBAction)disconnectFromLastFM:(id)sender;

@end
