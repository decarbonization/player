//
//  RKActivityManager.h
//  RoundaboutKit
//
//  Created by Kevin MacWhinnie on 12/10/12.
//  Copyright (c) 2012 Kevin MacWhinnie. All rights reserved.
//

#import <Foundation/Foundation.h>

///The RKActivityManager class is responsible for managing the activity state of the application.
///
///The RKActivityManager class does not provide an interface, this is the responsbility of the host application.
@interface RKActivityManager : NSObject

///Returns the shared activity manager, creating it if it doesn't exist.
+ (instancetype)sharedActivityManager;

#pragma mark - Properties

///Whether or not there is activity. KVC compliant.
///
///This property should be observed by an application's main controller,
///and used to control the display of a prominent activity indicator view.
///
///This property is thread-safe for interface bindings.
@property (readonly) BOOL isActive;

///The activity count of the manager.
///
///This property can potentially be mutated from multiple threads, and as such
///is not safe to be bound to or observed for the purpose of manipulating interface
///controls. The `isActive` property should be used in stead.
@property NSUInteger activityCount;

#if TARGET_OS_IPHONE

///Whether or not the activity manager updates the network activity indicator.
@property (nonatomic) BOOL updatesNetworkActivityIndicator;

#endif /* TARGET_OS_IPHONE */

#pragma mark - Activity

///Increments the activity count of the receiver.
- (void)incrementActivityCount;

///Decrements the activity count of the receiver.
- (void)decrementActivityCount;

@end
