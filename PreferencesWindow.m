//
//  PreferencesWindow.m
//  Pinna
//
//  Created by Peter MacWhinnie on 1/21/11.
//  Copyright 2011 Roundabout Software, LLC. All rights reserved.
//

#import "PreferencesWindow.h"

#import "GeneralPane.h"
#import "ArtModePane.h"
#import "HotKeysPane.h"
#import "SocialPane.h"
#import "AdvancedPane.h"

@interface PreferencesWindow () <NSToolbarDelegate>

@end

@implementation PreferencesWindow

#pragma mark Goop

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
	if((self = [super initWithWindowNibName:@"PreferencesWindow"]))
	{
		mPreferencesPanes = @{
            @"GeneralPane": [GeneralPane new],
            @"ArtModePane": [ArtModePane new],
            @"HotKeysPane": [HotKeysPane new],
            @"SocialPane": [SocialPane new],
            @"AdvancedPane": [AdvancedPane new],
        };
	}
	
	return self;
}

#pragma mark -

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	PreferencesPane *pane = [mPreferencesPanes objectForKey:itemIdentifier];
	NSToolbarItem *paneItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	
	[paneItem setLabel:pane.name];
	[paneItem setImage:pane.icon];
	
	[paneItem setTarget:self];
	[paneItem setAction:@selector(showPaneFrom:)];
	
	return paneItem;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return @[
        NSToolbarFlexibleSpaceItemIdentifier,
        @"GeneralPane",
        @"SocialPane",
        @"ArtModePane",
        @"HotKeysPane",
        @"AdvancedPane",
        NSToolbarFlexibleSpaceItemIdentifier
    ];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return [self toolbarAllowedItemIdentifiers:toolbar];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return [self toolbarAllowedItemIdentifiers:toolbar];
}

- (void)setupToolbar
{
	NSToolbar *selectorToolbar = [[NSToolbar alloc] initWithIdentifier:@"PreferencesWindowToolbar"];
	[selectorToolbar setDelegate:self];
	[selectorToolbar setAllowsUserCustomization:NO];
	
	[selectorToolbar setSelectedItemIdentifier:@"GeneralPane"];
	
	[[self window] setToolbar:selectorToolbar];
}

#pragma mark -

- (void)windowDidLoad
{
	[[self window] center];
	
	[self setupToolbar];
	
	[self setSelectedPane:[mPreferencesPanes objectForKey:@"GeneralPane"]];
}

#pragma mark - Managing Panes

- (void)contentViewFrameDidChange:(NSNotification *)notification
{
	[self showPane:[oContentBox contentView]];
}

#pragma mark -

- (void)showPane:(NSView *)pane
{
	NSSize viewSize = [pane frame].size;
	NSSize contentBoxSize = [oContentBox frame].size;
	NSRect windowFrame = [[self window] frame];
	
	CGFloat topAreaHeight = (NSHeight(windowFrame) - contentBoxSize.height);
	windowFrame.size.height = viewSize.height + topAreaHeight;
	windowFrame.size.width = viewSize.width;
	windowFrame.origin.y = NSMaxY([[self window] frame]) - (viewSize.height + topAreaHeight);
	windowFrame.origin.x = round(NSMidX([[self window] frame]) - (viewSize.width / 2.0));
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:NSViewFrameDidChangeNotification 
												  object:[oContentBox contentView]];
	
	[oContentBox setContentView:nil];
	[[self window] setFrame:windowFrame display:YES animate:YES];
	
	//This eliminates the stutter on the Art Mode pane
	NSDisableScreenUpdates();
	{
		[oContentBox setContentView:pane];
		[[self window] display];
	}
	NSEnableScreenUpdates();
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(contentViewFrameDidChange:) 
												 name:NSViewFrameDidChangeNotification 
											   object:[oContentBox contentView]];
}

- (void)setSelectedPane:(PreferencesPane *)pane
{
	[mSelectedPane paneWillBeRemovedFromWindow:[self window]];
	
	[self showPane:[pane view]];
	mSelectedPane = pane;
	
	[mSelectedPane paneWasAddedToWindow:[self window]];
}

- (PreferencesPane *)selectedPane
{
	return mSelectedPane;
}

- (IBAction)showPaneFrom:(NSToolbarItem *)sender
{
	PreferencesPane *pane = [mPreferencesPanes objectForKey:[sender itemIdentifier]];
	[self setSelectedPane:pane];
}

#pragma mark - Showing Specific Panes

- (void)showGeneralPane
{
	[[[self window] toolbar] setSelectedItemIdentifier:@"GeneralPane"];
	[self setSelectedPane:[mPreferencesPanes objectForKey:@"GeneralPane"]];
}

- (void)showArtModePane
{
	[[[self window] toolbar] setSelectedItemIdentifier:@"ArtModePane"];
	[self setSelectedPane:[mPreferencesPanes objectForKey:@"ArtModePane"]];
}

- (void)showPlayKeysPane
{
	[[[self window] toolbar] setSelectedItemIdentifier:@"HotKeysPane"];
	[self setSelectedPane:[mPreferencesPanes objectForKey:@"HotKeysPane"]];
}

- (void)showSocialPane
{
	[[[self window] toolbar] setSelectedItemIdentifier:@"SocialPane"];
	[self setSelectedPane:[mPreferencesPanes objectForKey:@"SocialPane"]];
}

@end
