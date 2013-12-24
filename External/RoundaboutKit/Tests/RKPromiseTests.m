//
//  RKPromiseTests.m
//  RoundaboutKitTests
//
//  Created by Kevin MacWhinnie on 5/6/13.
//
//

#import "RKPromiseTests.h"
#import "RKMockPromise.h"

#define DEFAULT_DURATION            0.3
#define DEFAULT_TIMEOUT             0.8

#pragma mark -

@interface RKPromiseTests ()

@property RKPossibility *successPossibility;
@property RKPossibility *errorPossibility;

@end

@implementation RKPromiseTests

/*
 *  Very bad things will happen if any of these tests unintentionally fail after changes.
 */

- (void)setUp
{
    [super setUp];
    
    self.successPossibility = [[RKPossibility alloc] initWithValue:@"What lovely weather we're having."];
    self.errorPossibility = [[RKPossibility alloc] initWithError:[NSError errorWithDomain:@"RKFictitiousErrorDomain"
                                                                                     code:'fail'
                                                                                 userInfo:@{NSLocalizedDescriptionKey: @"An unknown fictitious error occurred."}]];
}

#pragma mark -

- (void)testSuccessfulRealize
{
    RKMockPromise *testPromise = [[RKMockPromise alloc] initWithResult:self.successPossibility
                                                              duration:DEFAULT_DURATION];
    
    __block BOOL finished = NO;
    __block BOOL succeeded = NO;
    __block id outValue = nil;
    [testPromise then:^(id data) {
        finished = YES;
        
        outValue = data;
        succeeded = YES;
    } otherwise:^(NSError *error) {
        finished = YES;
        
        succeeded = NO;
    }];
    
    [RunLoopHelper runFor:DEFAULT_TIMEOUT];
    
    STAssertTrue(finished, @"RKRealize timed out generating value.");
    STAssertTrue(succeeded, @"RKRealize failed to generate value.");
    STAssertNotNil(outValue, @"RKRealize yielded nil value.");
}

- (void)testFailedRealize
{
    RKMockPromise *testPromise = [[RKMockPromise alloc] initWithResult:self.errorPossibility
                                                              duration:DEFAULT_DURATION];
    
    __block BOOL finished = NO;
    __block BOOL failed = NO;
    __block NSError *outError = nil;
    [testPromise then:^(id data) {
        finished = YES;
        failed = NO;
    } otherwise:^(NSError *error) {
        finished = YES;
        failed = YES;
        
        outError = error;
    }];
    
    [RunLoopHelper runFor:DEFAULT_TIMEOUT];
    
    STAssertTrue(finished, @"RKRealize timed out generating error.");
    STAssertTrue(failed, @"RKRealize failed to generate error.");
    STAssertNotNil(outError, @"RKRealize yielded nil error.");
}

#pragma mark -

- (void)testRealizeMultiple
{
    NSUInteger const kNumberOfPromises = 5;
    NSArray *promises = RKCollectionGenerateArray(kNumberOfPromises, ^(NSUInteger promiseNumber) {
        return [RKPromise acceptedPromiseWithValue:@(promiseNumber)];
    });
    
    __block BOOL finished = NO;
    __block NSArray *results = nil;
    [[RKPromise when:promises] then:^(NSArray *possibilities) {
        finished = YES;
        results = RKCollectionMapToArray(possibilities, ^id(RKPossibility *probablyValue) {
            STAssertEquals(probablyValue.state, kRKPossibilityStateValue, @"A promise unexpectedly failed");
            
            return probablyValue.value;
        });
    } otherwise:^(NSError *error) {
        //Do nothing
    }];
    
    BOOL finishedNaturally = [RunLoopHelper runUntil:^BOOL{ return (results != nil); } orSecondsHasElapsed:1.0];
    
    STAssertTrue(finishedNaturally, @"realize timed out");
    STAssertTrue(finished, @"RKRealizePromises timed out");
    STAssertEqualObjects(results, (@[ @0, @1, @2, @3, @4 ]), @"RKRealizePromises yielded wrong value");
}

#pragma mark - Test Await

- (void)testSuccessAwait
{
    RKMockPromise *testPromise = [[RKMockPromise alloc] initWithResult:self.successPossibility
                                                              duration:0.05];
    
    NSError *error = nil;
    id result = [testPromise await:&error];
    STAssertNotNil(result, @"RKAwait failed to yield value");
    STAssertNil(error, @"RKAwait unexpectedly yielded error");
}

- (void)testErrorAwait
{
    RKMockPromise *testPromise = [[RKMockPromise alloc] initWithResult:self.errorPossibility
                                                              duration:0.05];
    
    NSError *error = nil;
    id result = [testPromise await:&error];
    STAssertNil(result, @"RKAwait unexpectedly yielded error");
    STAssertNotNil(error, @"RKAwait failed to yield error");
}

@end
