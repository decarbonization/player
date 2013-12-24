//
//  PlayKeysAppDelegate.m
//  PlayKeys
//
//  Created by Kevin MacWhinnie on 11/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "PFMoveApplication.h"

#import "Pinna.h"
#import "HeadsUpWindowController.h"

@implementation AppDelegate {
	NSString *_parentProcessIdentifier;
	NSInteger _numberOfParentInstancesRunning;
	
	MediaKeyEventTap *_mediaKeyEventTap;
    
    HeadsUpWindowController *_headsUpWindowController;
    NSTimer *_showHeadsUpTimer;
}

#pragma mark - <NSApplicationDelegate>

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	_mediaKeyEventTap = [MediaKeyEventTap sharedMediaKeyEventTap];
	_mediaKeyEventTap.delegate = self;
	
	_parentProcessIdentifier = @"com.roundabout.Pinna";
	
	
	//We take note of the number of instances of our parent app
	//running so we can determine when to terminate later.
	for (NSRunningApplication *runningApplication in [[NSWorkspace sharedWorkspace] runningApplications]) {
		if([runningApplication.bundleIdentifier compare:_parentProcessIdentifier options:NSCaseInsensitiveSearch] == NSEqualToComparison)
			_numberOfParentInstancesRunning++;
	}
	
	
	//We have no state, so there's no need to go through the termination process.
	[[NSProcessInfo processInfo] enableSuddenTermination];
	
	
	//Let whatever app we're serving know of our existence after our first launch.
	if(!RKGetPersistentBool(@"HasCompletedFirstLaunch")) {
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:[_parentProcessIdentifier stringByAppendingString:@"com.roundabout.Pinna:playKeysReady"] 
																	   object:@"I do enjoy a flashy pair of shoes, especially on a dashing trumpet player like you."];
		
        RKSetPersistentBool(@"HasCompletedFirstLaunch", YES);
	}
	
	
	//We listen for application terminations we may or may not receieve
	//the 'com.roundabout.PlayKeys:terminate' (e.g. when an app crashes).
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self 
														   selector:@selector(workspaceDidTerminateApplication:) 
															   name:NSWorkspaceDidTerminateApplicationNotification 
															 object:nil];
	
	
	//We listen for notifications from our parent process that we should terminate.
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
														selector:@selector(playKeysShouldTerminate:) 
															name:@"com.roundabout.PlayKeys:terminate" 
														  object:_parentProcessIdentifier 
											  suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
	
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
														selector:@selector(playKeysAppLaunched:) 
															name:@"com.roundabout.PlayKeys:appLaunched" 
														  object:_parentProcessIdentifier 
											  suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
														selector:@selector(playKeysAppTerminated:) 
															name:@"com.roundabout.PlayKeys:appTerminated" 
														  object:_parentProcessIdentifier 
											  suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
    
    
    //We listen to presence broadcasts to capture updates from Pinna.
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(audioPlayerDidBroadcastPresence:)
                                                            name:@"com.roundabout.PKAudioPlayerDidBroadcastPresenceNotification"
                                                          object:nil];
    
#if !DEBUG
    PFMoveToApplicationsFolderIfNecessary();
#endif /* !DEBUG */
    
    _headsUpWindowController = [HeadsUpWindowController new];
    _headsUpWindowController.dismissalHandler = ^{
        [NSApp hide:nil];
    };
    
	[NSApp hide:nil];
    
    if([Pinna sharedPinna].isRunning)
        [_headsUpWindowController update];
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    [_headsUpWindowController close];
}

#pragma mark - PlayKeys Communication

- (void)playKeysAppLaunched:(NSNotification *)notification
{
	_numberOfParentInstancesRunning++;
}

- (void)playKeysAppTerminated:(NSNotification *)notification
{
	_numberOfParentInstancesRunning--;
	if(_numberOfParentInstancesRunning < 1)
		[NSApp terminate:nil];
}

- (void)workspaceDidTerminateApplication:(NSNotification *)notification
{
	if([[NSRunningApplication runningApplicationsWithBundleIdentifier:[_parentProcessIdentifier lowercaseString]] count] == 0) {
		[NSApp terminate:nil];
    }
}

- (void)playKeysShouldTerminate:(NSNotification *)notification
{
	[NSApp terminate:nil];
}

#pragma mark - Heads Up

- (void)audioPlayerDidBroadcastPresence:(NSNotification *)notification
{
    //This captures all major changes in playback state except
    //for streaming songs. That case is covered below.
    if([_headsUpWindowController.window isVisible] && [Pinna sharedPinna].isRunning) {
        [self updateHeadsUp];
    }
}

#pragma mark -

- (void)updateHeadsUp
{
    [_headsUpWindowController showWindow:nil];
    [_headsUpWindowController update];
}

- (void)showHeadsUp
{
    if(![_headsUpWindowController.window isVisible] && [Pinna sharedPinna].isRunning) {
        [NSApp activateIgnoringOtherApps:YES];
    }
    
    [self updateHeadsUp];
}

#pragma mark - Media Key Delegate

- (BOOL)mediaKeyEventTap:(MediaKeyEventTap *)watcher mediaKeyWasPressed:(MediaKeyCode)key
{
    if(key == kMediaKeyCodePlayPause) {
        _showHeadsUpTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                             target:self
                                                           selector:@selector(showHeadsUp)
                                                           userInfo:nil
                                                            repeats:NO];
    }
    
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:[_parentProcessIdentifier stringByAppendingString:@":mediaKeyWasPressed"] 
																   object:[NSString stringWithFormat:@"%d", key]];
	
	return YES;
}

- (BOOL)mediaKeyEventTap:(MediaKeyEventTap *)watcher mediaKeyWasReleased:(MediaKeyCode)key
{
    [_showHeadsUpTimer invalidate];
    _showHeadsUpTimer = nil;
    
    if([_headsUpWindowController.window isVisible] && [Pinna sharedPinna].isRunning) {
        //Give Pinna time to update everything
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            //This is semi-redundant with the playback notifications
            //broadcast. This mostly catches the edge-case of streaming
            //songs that have to buffer.
            [self updateHeadsUp];
        });
        
        if(key == kMediaKeyCodePlayPause)
            return YES;
    }
    
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:[_parentProcessIdentifier stringByAppendingString:@":mediaKeyWasReleased"] 
																   object:[NSString stringWithFormat:@"%d", key]];
	
	return YES;
}

- (BOOL)mediaKeyEventTap:(MediaKeyEventTap *)watcher mediaKeyIsBeingHeld:(MediaKeyCode)key
{
    if(key == kMediaKeyCodePlayPause && _headsUpWindowController != nil)
        return YES;
    
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:[_parentProcessIdentifier stringByAppendingString:@":mediaKeyIsBeingHeld"]
                                                                   object:[NSString stringWithFormat:@"%d", key]];
    
	return YES;
}

@end
