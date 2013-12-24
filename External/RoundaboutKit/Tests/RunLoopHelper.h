//
//  RunLoopHelper.h
//  RoundaboutKitTests
//
//  Created by Kevin MacWhinnie on 5/6/13.
//
//

#import <Foundation/Foundation.h>

///The RunLoopHelper class contains methods to assist in tests
///which require the main runloop to be running to complete.
@interface RunLoopHelper : NSObject

///Runs the main run loop for n seconds.
///
/// \param  seconds The number of seconds to run the run loop for.
///
+ (void)runFor:(NSTimeInterval)seconds;

///Runs the main run loop until the given predicate yields NO.
///
/// \param  predicate   A block which returns a BOOL indicating whether or not the run loop should continue. Required.
/// \param  seconds     The timeout for the run loop cycle. Must be greater than 0.0.
///
/// \result YES if the run cycle ended naturally; NO if it timed out.
+ (BOOL)runUntil:(BOOL(^)())predicate orSecondsHasElapsed:(NSTimeInterval)seconds;

@end
