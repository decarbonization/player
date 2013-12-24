//
//  RKSandboxTools.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 10/17/12.
//
//

#ifndef RKSandboxTools_h
#define RKSandboxTools_h 1

#pragma mark Paths and Sandboxing

///Returns the real world location of the user's home directory.
RK_EXTERN NSString *RKGetRealUserDirectoryPath();

///Returns the sandboxed location of the user's "home directory".
RK_EXTERN NSString *RKGetSandboxUserDirectoryPath();

#pragma mark -

///Returns a BOOL indicating whether or not a given location is within the app's sandbox.
RK_EXTERN BOOL RKIsLocationWithinSandbox(NSURL *location);

///Returns a URL resolved to point to within the app's sandbox.
RK_EXTERN NSURL *RKResolveLocationInSandbox(NSURL *location);

#endif /* RKSandboxTools_h */