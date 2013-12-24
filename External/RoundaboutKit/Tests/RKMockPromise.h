//
//  RKMockPromise.h
//  RoundaboutKitTests
//
//  Created by Kevin MacWhinnie on 5/6/13.
//
//

#import "RKPromise.h"

///The RKMockPromise class encapsulates a determinate asynchronous
///process that will yield a predetermined success or failure value.
@interface RKMockPromise : RKPromise

///Initialize the receiver with an expected result, duration, whether or not
///it can cancel, and the number of times the success callback should be run.
///
/// \param  result              The value to yield for the promise. The possibility *cannot* be empty. Required.
/// \param  duration            The amount of time to elapse before the promise is run. May be 0.0.
///
///This is the designated initializer of RKMockPromise.
- (id)initWithResult:(RKPossibility *)result
            duration:(NSTimeInterval)duration RK_REQUIRE_RESULT_USED;

@end
