//
//  PreferencesWindow.h
//  Pinna
//
//  Created by Peter MacWhinnie on 1/21/11.
//  Copyright 2011 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PreferencesPane.h"

///The window controller responsible for providing a preferences window for Player.
@interface PreferencesWindow : NSWindowController <NSOpenSavePanelDelegate>
{
	///The content box used to display preferences.
	IBOutlet NSBox *oContentBox;
	
	///The preference panes.
	NSDictionary *mPreferencesPanes;
	
	///The selected pane
	PreferencesPane *mSelectedPane;
}

#pragma mark - Showing Specific Panes

- (void)showGeneralPane;

- (void)showArtModePane;

- (void)showPlayKeysPane;

- (void)showSocialPane;

@end
