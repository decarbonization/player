//
//  RKPossibilityTests.m
//  RoundaboutKitTests
//
//  Created by Kevin MacWhinnie on 4/12/13.
//
//

#import "RKPossibilityTests.h"

@implementation RKPossibilityTests {
    NSString *_testObject;
    NSError *_testError;
}

- (void)setUp
{
    [super setUp];
    
    _testObject = @"This is test, only a test";
    _testError = [NSError errorWithDomain:NSPOSIXErrorDomain code:'fail' userInfo:@{NSLocalizedDescriptionKey: @"everything is broken!"}];
}

#pragma mark - States

- (void)testValue
{
    RKPossibility *possibility = [[RKPossibility alloc] initWithValue:_testObject];
    STAssertEquals(possibility.state, kRKPossibilityStateValue, @"RKPossibility is in unexpected state");
    STAssertEqualObjects(possibility.value, _testObject, @"RKPossibility has unexpected value");
    STAssertNil(possibility.error, @"RKPossibility has unexpected error");
}

- (void)testError
{
    RKPossibility *possibility = [[RKPossibility alloc] initWithError:_testError];
    STAssertEquals(possibility.state, kRKPossibilityStateError, @"RKPossibility is in unexpected state");
    STAssertEqualObjects(possibility.error, _testError, @"RKPossibility has unexpected value");
    STAssertNil(possibility.value, @"RKPossibility has unexpected value");
}

- (void)testEmpty
{
    RKPossibility *possibility = [[RKPossibility alloc] initEmpty];
    STAssertEquals(possibility.state, kRKPossibilityStateEmpty, @"RKPossibility is in unexpected state");
    STAssertNil(possibility.value, @"RKPossibility has unexpected value");
    STAssertNil(possibility.error, @"RKPossibility has unexpected error");
}

#pragma mark - Utility Functions

- (void)testRefinement
{
    RKPossibility *possibility = [[RKPossibility alloc] initWithValue:_testObject];
    RKPossibility *refinedPossibility = [possibility refineValue:^RKPossibility *(NSString *value) {
        return [[RKPossibility alloc] initWithValue:[value stringByAppendingString:@" foo"]];
    }];
    STAssertEqualObjects(refinedPossibility.value, @"This is test, only a test foo", @"RKRefinePossibility returned wrong result");
}

- (void)testMatching
{
    RKPossibility *possibility = [[RKPossibility alloc] initWithValue:_testObject];
    [possibility whenValue:^(id value) {
        STAssertTrue(YES, @"RKMatchPossibility failed to match value");
    }];
    [possibility whenEmpty:^{
        STAssertTrue(NO, @"RKMatchPossibility failed to match value");
    }];
    [possibility whenError:^(NSError *error) {
        STAssertTrue(NO, @"RKMatchPossibility failed to match value");
    }];
}

@end
