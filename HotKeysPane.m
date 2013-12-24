//
//  HotKeysPane.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 7/7/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "HotKeysPane.h"
#import "PlayKeysBridge.h"
#import "SRRecorderControl.h"
#import "HotKeyDispatcher.h"

static NSString *const kPinnaPlayKeysURLString = @"http://pinnaplayer.com/playkeys";

@implementation HotKeysPane

- (void)loadView
{
	[super loadView];
	
	oPlayPauseRecorder.keyCombo = KeyComboFromDictionary(RKGetPersistentObject(@"HotKeys_playPause"));
	oNextTrackRecorder.keyCombo = KeyComboFromDictionary(RKGetPersistentObject(@"HotKeys_nextTrack"));
	oPreviousTrackRecorder.keyCombo = KeyComboFromDictionary(RKGetPersistentObject(@"HotKeys_previousTrack"));
}

#pragma mark - Properties

- (NSString *)name
{
	return @"Hotkeys";
}

- (NSImage *)icon
{
	return [NSImage imageNamed:@"HotKeysIcon"];
}

#pragma mark - Actions

- (IBAction)listensForMediaKeysChanged:(NSButton *)sender
{
	PlayKeysBridge *playKeysBridge = [PlayKeysBridge playKeysBridge];
	if(!playKeysBridge.isPlayKeysAppInstalled)
	{
		RKSetPersistentBool(@"ListenToMediaKeys", NO);
		
		NSUInteger returnCode = [[NSAlert alertWithMessageText:@"PlayKeys, Simple Playback Control" 
												 defaultButton:@"OK" 
											   alternateButton:nil 
												   otherButton:@"Download PlayKeys…" 
									 informativeTextWithFormat:(@"To support the keyboard playback keys, Pinna uses a tiny "
																@"app, PlayKeys. PlayKeys uses minimal resources and Pinna "
																@"takes care of opening and quitting it, so you won't "
																@"even notice it's around.")] runModal];
		if(returnCode == NSAlertOtherReturn)
		{
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kPinnaPlayKeysURLString]];
		}
	}
	else
	{
		if([sender state] == NSOnState && !playKeysBridge.isPlayKeysAppRunning)
			[playKeysBridge launchPlayKeysApp];
		else
			[playKeysBridge terminatePlayKeysApp];
	}
}

#pragma mark - Shortcut Recorder Delegate

- (void)shortcutRecorder:(SRRecorderControl *)recorder keyComboDidChange:(KeyCombo)newKeyCombo
{
	if(recorder == oPlayPauseRecorder)
	{
		[HotKeyDispatcher sharedHotKeyDispatcher].playPauseCombo = newKeyCombo;
		
		RKSetPersistentObject(@"HotKeys_playPause", KeyComboToDictionary(newKeyCombo));
	}
	else if(recorder == oNextTrackRecorder)
	{
		[HotKeyDispatcher sharedHotKeyDispatcher].nextTrackCombo = newKeyCombo;
		
		RKSetPersistentObject(@"HotKeys_nextTrack", KeyComboToDictionary(newKeyCombo));
	}
	else if(recorder == oPreviousTrackRecorder)
	{
		[HotKeyDispatcher sharedHotKeyDispatcher].previousTrackCombo = newKeyCombo;
		
		RKSetPersistentObject(@"HotKeys_previousTrack", KeyComboToDictionary(newKeyCombo));
	}
}

@end
