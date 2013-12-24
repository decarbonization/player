//
//  RKActivityManagerTests.m
//  RoundaboutKitTests
//
//  Created by Kevin MacWhinnie on 4/12/13.
//
//

#import "RKActivityManagerTests.h"

@implementation RKActivityManagerTests

- (void)setUp
{
    [super setUp];
    
}

- (void)tearDown
{
    [super tearDown];
    
}

- (void)testActivityManager
{
    RKActivityManager *activityManager = [RKActivityManager sharedActivityManager];
    
    STAssertFalse(activityManager.isActive, @".isActive is wrong");
    STAssertEquals(activityManager.activityCount, 0UL, @".activityCount is wrong");
    
    [activityManager incrementActivityCount];
    [activityManager incrementActivityCount];
    
    STAssertTrue(activityManager.isActive, @".isActive is wrong");
    STAssertEquals(activityManager.activityCount, 2UL, @".activityCount is wrong");
    
    [activityManager decrementActivityCount];
    [activityManager decrementActivityCount];
    
    STAssertFalse(activityManager.isActive, @".isActive is wrong");
    STAssertEquals(activityManager.activityCount, 0UL, @".activityCount is wrong");
    
    [activityManager decrementActivityCount];
    
    STAssertEquals(activityManager.activityCount, 0UL, @".activityCount is wrong");
}

@end
