//
//  RKConnectivityManager.h
//  RoundaboutKit
//
//  Created by Kevin MacWhinnie on 12/31/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#ifndef RKConnectivityManager_h
#define RKConnectivityManager_h 1

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

@class RKConnectivityManager;

///A connectivity manager status changed block.
typedef void(^RKConnectivityManagerStatusChangedBlock)(RKConnectivityManager *sender);

///The name of the notification posted when RKConnectivityManager detects a change in connection status.
///
///The object of the notification is the RKConnectivityManager that posted the notificiation.
///There is no associated userInfo dictionary.
RK_EXTERN NSString *const RKConnectivityManagerStatusChangedNotification;

///The RKConnectivityManager class encapsulates querying and monitoring changes to connectivity status.
///
///This object requires there be an active run loop to function.
@interface RKConnectivityManager : NSObject

///Returns the default internet connectivity manager object, creating it if it does not exist.
///
///The returned object is suitable for querying and observing changes to the device's internet connection.
+ (RKConnectivityManager *)defaultInternetConnectivityManager;

#pragma mark -

///Initialize the receiver with a given socket address.
///
/// \param  hostName    The host name. Required.
///
/// \result A fully initialized connectivity manager object.
///
- (id)initWithAddress:(const struct sockaddr *)address;

///Initialize the receiver with a given host name.
///
/// \param  hostName    The host name. Required.
///
/// \result A fully initialized connectivity manager object.
///
- (id)initWithHostName:(NSString *)hostName;

///Initialize the receiver with a given network reachability object.
///
/// \param  reachability    The reachability object to observe. Retained by the receiver. Required.
///
/// \result A fully initialized connectivity manager object.
///
///This is the primitive initializer of RKConnectivityManager.
- (id)initWithNetworkReachability:(SCNetworkReachabilityRef)reachability;

#pragma mark - Properties

///Whether or not we're connected.
@property (readonly, RK_NONATOMIC_IOSONLY) BOOL isConnected;

#pragma mark - Registering Callbacks

///Register a status changed block.
///
/// \seealso(RKConnectivityManagerStatusChangedNotification)
- (void)registerStatusChangedBlock:(RKConnectivityManagerStatusChangedBlock)statusChangedBlock;

///Unregister a status changed block.
///
/// \seealso(RKConnectivityManagerStatusChangedNotification)
- (void)unregisterStatusChangedBlock:(RKConnectivityManagerStatusChangedBlock)statusChangedBlock;

@end

#endif /* RKConnectivityManager_h */
