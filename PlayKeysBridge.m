//
//  MediaKeyWatcher.m
//  event-spy
//
//  Created by Peter MacWhinnie on 8/26/09.
//  Copyright 2009 Roundabout Software, LLC. All rights reserved.
//

#import "PlayKeysBridge.h"

@implementation PlayKeysBridge

#pragma mark - Object Gunk

static PlayKeysBridge *sharedMediaKeyWatcher = nil;
+ (PlayKeysBridge *)playKeysBridge
{
	static dispatch_once_t predicate = 0;
	dispatch_once(&predicate, ^{
		sharedMediaKeyWatcher = [PlayKeysBridge new];
	});
	
	return sharedMediaKeyWatcher;
}

- (id)init
{
	if((self = [super init]))
	{
		NSDistributedNotificationCenter *notificationCenter = [NSDistributedNotificationCenter defaultCenter];
		[notificationCenter addObserver:self 
							   selector:@selector(playKeysDetectedMediaKeyWasPressed:) 
								   name:@"com.roundabout.Pinna:mediaKeyWasPressed" 
								 object:nil 
					 suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
		[notificationCenter addObserver:self 
							   selector:@selector(playKeysDetectedMediaKeyWasReleased:) 
								   name:@"com.roundabout.Pinna:mediaKeyWasReleased" 
								 object:nil 
					 suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
		[notificationCenter addObserver:self 
							   selector:@selector(playKeysDetectedMediaKeyIsBeingHeld:) 
								   name:@"com.roundabout.Pinna:mediaKeyIsBeingHeld" 
								 object:nil 
					 suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
		
		[notificationCenter addObserver:self 
							   selector:@selector(playKeysDidBecomeReady:) 
								   name:@"com.roundabout.Pinna:playKeysReady" 
								 object:nil 
					 suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
		
		mEnabled = YES;
		
		return self;
	}
	return nil;
}

#pragma mark - Properties

@synthesize delegate = mDelegate;
@synthesize enabled = mEnabled;

#pragma mark - Controlling PlayKeys.app

- (BOOL)isPlayKeysAppRunning
{
	NSArray *runningApplications = [[NSWorkspace sharedWorkspace] runningApplications];
	return RKCollectionDoesAnyValueMatch(runningApplications, ^BOOL(NSRunningApplication *application) {
		return [application.bundleIdentifier isEqualToString:@"com.roundabout.PlayKeys"];
	});
}

- (NSURL *)playKeysAppLocation
{
	//We assume that PlayKeys is in the applications folder.
	NSString *applicationFolderPath = [NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSLocalDomainMask, YES) lastObject];
	
	NSURL *playKeysAppLocation = [NSURL fileURLWithPath:[applicationFolderPath stringByAppendingPathComponent:@"PlayKeys.app"]];
	
	//If it's not, we ask the system. We make this assumption due to issues
	//with LaunchServices choosing the most recently built PlayKeys application
	//on a Pinna development computer
	if(![playKeysAppLocation checkResourceIsReachableAndReturnError:nil])
		return [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:@"com.roundabout.PlayKeys"];
	
	return playKeysAppLocation;
}

- (BOOL)isPlayKeysAppInstalled
{
	return (self.playKeysAppLocation != nil);
}

#pragma mark -

- (void)launchPlayKeysApp
{
	NSURL *playKeysAppLocation = self.playKeysAppLocation;
	if(playKeysAppLocation)
	{
		NSError *error = nil;
		
		NSArray *arguments = @[[@"app=" stringByAppendingString:[[NSBundle mainBundle] bundleIdentifier]]];
		
		if(![[NSWorkspace sharedWorkspace] launchApplicationAtURL:playKeysAppLocation 
														  options:NSWorkspaceLaunchWithoutActivation | NSWorkspaceLaunchAsync 
													configuration:@{NSWorkspaceLaunchConfigurationArguments: arguments}
															error:&error])
		{
			NSLog(@"Couldn't launch PlayKeys (%@), error {%@}", [playKeysAppLocation path], [error localizedDescription]);
		}
	}
}

- (void)terminatePlayKeysApp
{
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.roundabout.PlayKeys:terminate" 
																   object:[[NSBundle mainBundle] bundleIdentifier]];
}

#pragma mark - PlayKeys Support

- (void)playKeysDidBecomeReady:(NSNotification *)notification
{
	[self willChangeValueForKey:@"isPlayKeysAppInstalled"];
	[self didChangeValueForKey:@"isPlayKeysAppInstalled"];
}

#pragma mark -

- (void)playKeysDetectedMediaKeyWasPressed:(NSNotification *)notification
{
	if(self.enabled)
	{
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			MediaKeyCode keyCode = [[notification object] intValue];
			
			[self.delegate playKeysBridge:self mediaKeyWasPressed:keyCode];
		}];
	}
}

- (void)playKeysDetectedMediaKeyWasReleased:(NSNotification *)notification
{
	if(self.enabled)
	{
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			MediaKeyCode keyCode = [[notification object] intValue];
			
			[self.delegate playKeysBridge:self mediaKeyWasReleased:keyCode];
		}];
	}
}

- (void)playKeysDetectedMediaKeyIsBeingHeld:(NSNotification *)notification
{
	if(self.enabled)
	{
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			MediaKeyCode keyCode = [[notification object] intValue];
			
			if([self.delegate respondsToSelector:@selector(playKeysBridge:mediaKeyIsBeingHeld:)])
			{
				[self.delegate playKeysBridge:self mediaKeyIsBeingHeld:keyCode];
			}
		}];
	}
}

@end
