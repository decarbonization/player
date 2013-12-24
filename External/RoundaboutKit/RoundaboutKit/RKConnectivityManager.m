//
//  RKConnectivityManager.m
//  RoundaboutKit
//
//  Created by Kevin MacWhinnie on 12/31/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "RKConnectivityManager.h"
#import <netinet/in.h>

NSString *SCNetworkReachabilityFlagsGetDescription(SCNetworkReachabilityFlags status)
{
    NSMutableString *description = [NSMutableString string];
    if(RK_FLAG_IS_SET(status, kSCNetworkReachabilityFlagsTransientConnection))
        [description appendString:@"kSCNetworkReachabilityFlagsTransientConnection | "];
    if(RK_FLAG_IS_SET(status, kSCNetworkReachabilityFlagsReachable))
        [description appendString:@"kSCNetworkReachabilityFlagsReachable | "];
    if(RK_FLAG_IS_SET(status, kSCNetworkReachabilityFlagsConnectionRequired))
        [description appendString:@"kSCNetworkReachabilityFlagsConnectionRequired | "];
    if(RK_FLAG_IS_SET(status, kSCNetworkReachabilityFlagsConnectionOnTraffic))
        [description appendString:@"kSCNetworkReachabilityFlagsConnectionOnTraffic | "];
    if(RK_FLAG_IS_SET(status, kSCNetworkReachabilityFlagsInterventionRequired))
        [description appendString:@"kSCNetworkReachabilityFlagsInterventionRequired | "];
    if(RK_FLAG_IS_SET(status, kSCNetworkReachabilityFlagsConnectionOnDemand))
        [description appendString:@"kSCNetworkReachabilityFlagsConnectionOnDemand | "];
    if(RK_FLAG_IS_SET(status, kSCNetworkReachabilityFlagsIsLocalAddress))
        [description appendString:@"kSCNetworkReachabilityFlagsIsLocalAddress | "];
    if(RK_FLAG_IS_SET(status, kSCNetworkReachabilityFlagsIsDirect))
        [description appendString:@"kSCNetworkReachabilityFlagsIsDirect | "];
    if(RK_FLAG_IS_SET(status, kSCNetworkReachabilityFlagsConnectionAutomatic))
        [description appendString:@"kSCNetworkReachabilityFlagsConnectionAutomatic | "];
    
    if([description hasSuffix:@" | "]) {
        [description deleteCharactersInRange:NSMakeRange([description length] - 3, 3)];
    }
    
    return [description copy];
}

NSString *const RKConnectivityManagerStatusChangedNotification = @"RKConnectivityManagerStatusChangedNotification";

@implementation RKConnectivityManager {
    NSMutableArray *_callbackBlocks;
    SCNetworkReachabilityRef _networkReachability;
}

#pragma mark - Callbacks

static void NetworkReachabilityChanged(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
    RKConnectivityManager *self = (__bridge RKConnectivityManager *)(info);
    
    [self willChangeValueForKey:@"connectionStatus"];
    [self didChangeValueForKey:@"connectionStatus"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RKConnectivityManagerStatusChangedNotification object:self];
    
    RK_SYNCHRONIZED_MACONLY(self->_callbackBlocks) {
        for (RKConnectivityManagerStatusChangedBlock statusChangedBlock in self->_callbackBlocks) {
            statusChangedBlock(self);
        }
    }
}

#pragma mark - Lifecycle

- (void)dealloc
{
    if(_networkReachability) {
        SCNetworkReachabilityUnscheduleFromRunLoop(_networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
        
        CFRelease(_networkReachability);
        _networkReachability = NULL;
    }
}

+ (RKConnectivityManager *)defaultInternetConnectivityManager
{
    static RKConnectivityManager *defaultInternetConnectivityManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        const struct sockaddr_in zeroAddress = {
            .sin_len = sizeof(zeroAddress),
            .sin_family = AF_INET,
        };
        defaultInternetConnectivityManager = [[RKConnectivityManager alloc] initWithAddress:(const struct sockaddr *)&zeroAddress];
    });
    
    return defaultInternetConnectivityManager;
}

#pragma mark -

- (id)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initWithAddress:(const struct sockaddr *)address
{
    NSParameterAssert(address);
    
    SCNetworkReachabilityRef networkReachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, address);
    NSAssert((networkReachability != NULL), @"Could not create reachability object.");
    
    self = [self initWithNetworkReachability:networkReachability];
    CFRelease(networkReachability);
    
    return self;
}

- (id)initWithHostName:(NSString *)hostName
{
    NSParameterAssert(hostName);
    
    SCNetworkReachabilityRef networkReachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [hostName UTF8String]);
    NSAssert((networkReachability != NULL), @"Could not create reachability object.");
    
    self = [self initWithNetworkReachability:networkReachability];
    CFRelease(networkReachability);
    
    return self;
}

- (id)initWithNetworkReachability:(SCNetworkReachabilityRef)reachability
{
    NSParameterAssert(reachability);
    
    if((self = [super init])) {
        _networkReachability = CFRetain(reachability);
        SCNetworkReachabilityContext context = {
            .version = 0,
            .info = (__bridge void *)(self),
            .retain = &CFRetain,
            .release = &CFRelease,
            .copyDescription = &CFCopyDescription,
        };
        if(!SCNetworkReachabilitySetCallback(_networkReachability, &NetworkReachabilityChanged, &context)) {
            [NSException raise:NSInternalInconsistencyException format:@"Could not set reachability callback."];
        }
        
        if(!SCNetworkReachabilityScheduleWithRunLoop(_networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes)) {
            [NSException raise:NSInternalInconsistencyException format:@"Could not schedule reachability into main run loop."];
        }
        
        _callbackBlocks = [NSMutableArray new];
    }
    
    return self;
}

#pragma mark - Properties

- (SCNetworkReachabilityFlags)connectionStatus
{
    RK_SYNCHRONIZED_MACONLY(self) {
        SCNetworkReachabilityFlags flags = 0;
        if(SCNetworkReachabilityGetFlags(_networkReachability, &flags)) {
            return flags;
        }
        
        return 0;
    }
}

+ (NSSet *)keyPathsForValuesAffectingIsConnected
{
    return [NSSet setWithObjects:@"connectionStatus", nil];
}

- (BOOL)isConnected
{
    SCNetworkReachabilityFlags status = self.connectionStatus;
    
    if(RK_FLAG_IS_SET(status, kSCNetworkReachabilityFlagsConnectionRequired) ||
       (RK_FLAG_IS_SET(status, kSCNetworkReachabilityFlagsTransientConnection) && !RK_FLAG_IS_SET(status, kSCNetworkReachabilityFlagsIsLocalAddress)))
        return NO;
    
    if(!RK_FLAG_IS_SET(status, kSCNetworkReachabilityFlagsConnectionOnTraffic) &&
       !RK_FLAG_IS_SET(status, kSCNetworkReachabilityFlagsReachable))
        return NO;
    
    return YES;
}

#pragma mark - Registering Callbacks

- (void)registerStatusChangedBlock:(RKConnectivityManagerStatusChangedBlock)statusChangedBlock
{
    NSParameterAssert(statusChangedBlock);
    
    RK_SYNCHRONIZED_MACONLY(_callbackBlocks) {
        NSAssert(![_callbackBlocks containsObject:statusChangedBlock],
                 @"Cannot register a status changed block more than once.");
        
        [_callbackBlocks addObject:[statusChangedBlock copy]];
    }
}

- (void)unregisterStatusChangedBlock:(RKConnectivityManagerStatusChangedBlock)statusChangedBlock
{
    NSParameterAssert(statusChangedBlock);
    
    RK_SYNCHRONIZED_MACONLY(_callbackBlocks) {
        NSAssert(![_callbackBlocks containsObject:statusChangedBlock],
                 @"Cannot unregister a status changed block that hasn't been registered.");
        
        [_callbackBlocks removeObject:statusChangedBlock];
    }
}

@end
