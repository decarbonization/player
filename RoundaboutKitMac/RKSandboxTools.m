//
//  RKSandboxTools.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 10/17/12.
//
//

#import "RKSandboxTools.h"
#import "Library.h"

#pragma mark Paths and Sandboxing

NSString *RKGetRealUserDirectoryPath()
{
	return [NSString stringWithFormat:@"/Users/%@", NSUserName()];
}

NSString *RKGetSandboxUserDirectoryPath()
{
	return [@"~/" stringByExpandingTildeInPath];
}

#pragma mark -

BOOL RKIsDirectoryWithNameWhitelisted(NSString *directoryName)
{
	NSString *pathOfDirectory = [RKGetSandboxUserDirectoryPath() stringByAppendingPathComponent:directoryName];
	return [[NSFileManager defaultManager] fileExistsAtPath:pathOfDirectory];
}

BOOL RKIsLocationWithinSandbox(NSURL *location)
{
#if RK_BUILDING_WITH_SANDBOX
	if(!location || ![location isFileURL])
		return NO;
	
	NSString *realUserDirectory = RKGetRealUserDirectoryPath();
    NSString *iTunesFolderDirectory = [[[Library sharedLibrary] iTunesFolderLocation] path];
	NSString *path = [location path];
    if([path hasPrefix:iTunesFolderDirectory])
    {
        return YES;
    }
	else if([path hasPrefix:realUserDirectory])
	{
		path = [path stringByReplacingCharactersInRange:NSMakeRange(0, [realUserDirectory length]) withString:@""];
		NSArray *pathComponents = [path pathComponents];
		if([pathComponents count] <= 1)
			return NO;
		
		return RKIsDirectoryWithNameWhitelisted([pathComponents objectAtIndex:0]);
	}
	
	return NO;
#else
	return YES;
#endif
}

NSURL *RKResolveLocationInSandbox(NSURL *location)
{
#if RK_BUILDING_WITH_SANDBOX
	if(!location)
		return nil;
	
	NSCAssert([location isFileURL], @"Cannot resolve non-file-system URL %@", location);
	
	NSString *realUserDirectory = RKGetRealUserDirectoryPath();
	NSString *sandboxUserDirectory = RKGetSandboxUserDirectoryPath();
	NSString *path = [location path];
	if([path hasPrefix:realUserDirectory])
	{
		path = [path stringByReplacingCharactersInRange:NSMakeRange(0, [realUserDirectory length]) withString:@""];
		NSArray *pathComponents = [path pathComponents];
		if([pathComponents count] <= 1)
			return nil;
		
		if(!RKIsDirectoryWithNameWhitelisted([pathComponents objectAtIndex:0]))
			return nil;
		
		return [NSURL fileURLWithPath:[sandboxUserDirectory stringByAppendingPathComponent:path]];
	}
	
	return nil;
#else
	return location;
#endif
}
