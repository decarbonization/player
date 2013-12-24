//
//  Pinna.m
//  PlayKeys
//
//  Created by Kevin MacWhinnie on 5/27/13.
//
//

#import "Pinna.h"

@implementation Pinna

+ (instancetype)sharedPinna
{
    static Pinna *sharedPinna = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPinna = [Pinna new];
    });
    
    return sharedPinna;
}

- (id)init
{
    if((self = [super init])) {
        
    }
    
    return self;
}

#pragma mark - Properties

- (BOOL)isRunning
{
    return RKCollectionDoesAnyValueMatch([[NSWorkspace sharedWorkspace] runningApplications], ^BOOL(NSRunningApplication *app) {
        return [app.bundleIdentifier isEqualToString:@"com.roundabout.pinna"];
    });
}

- (id <PinnaScriptingController>)scriptingController
{
    if(!self.isRunning)
        return nil;
    
    NSConnection *proxyConnection = [NSConnection connectionWithRegisteredName:@"com.roundabout.pinna.JSTalk" host:nil];
    return (id <PinnaScriptingController>)[proxyConnection rootProxy];
}

@end
