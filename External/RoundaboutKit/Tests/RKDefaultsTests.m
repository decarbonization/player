//
//  RKDefaultsTests.m
//  RoundaboutKitTests
//
//  Created by Kevin MacWhinnie on 4/12/13.
//
//

#import "RKDefaultsTests.h"

//Change the affectedKeys array below if anything is added or removed.
static NSString *const PersistentObjectKey = @"com.roundabout.roundaboutkitests/PersistentObject";
static NSString *const PersistentIntegerKey = @"com.roundabout.roundaboutkitests/PersistentInteger";
static NSString *const PersistentFloatKey = @"com.roundabout.roundaboutkitests/PersistentFloat";
static NSString *const PersistentBoolKey = @"com.roundabout.roundaboutkitests/PersistentBool";
static NSString *const TestDefault1Key = @"com.roundabout.roundaboutkitests/TestDefault1";

@interface RKDefaultsTests ()

@property (copy) NSArray *affectedKeys;

@end

@implementation RKDefaultsTests

- (void)setUp
{
    [super setUp];
    
    self.affectedKeys = @[
        PersistentObjectKey,
        PersistentIntegerKey,
        PersistentFloatKey,
        PersistentBoolKey,
        TestDefault1Key
    ];
}

- (void)tearDown
{
    [super tearDown];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (NSString *affectedKey in self.affectedKeys)
        [defaults removeObjectForKey:affectedKey];
}

#pragma mark Defaults Short-hand

- (void)testPersistentObject
{
    RKSetPersistentObject(PersistentObjectKey, @"potatoes");
    STAssertEqualObjects(RKGetPersistentObject(PersistentObjectKey), @"potatoes", @"RK*PersistentObject is broken");
}

- (void)testPersistentInteger
{
    RKSetPersistentInteger(PersistentIntegerKey, 42);
    STAssertEquals(RKGetPersistentInteger(PersistentIntegerKey), 42L, @"RK*PersistentInteger is broken");
}

- (void)testPersistentFloat
{
    RKSetPersistentFloat(PersistentFloatKey, 42.f);
    STAssertEquals(RKGetPersistentFloat(PersistentFloatKey), 42.f, @"RK*PersistentFloat is broken");
}

- (void)testPersistentBool
{
    RKSetPersistentBool(PersistentBoolKey, YES);
    STAssertEquals(RKGetPersistentBool(PersistentBoolKey), YES, @"RK*PersistentBOOL is broken");
}

#pragma mark -

- (void)testPersistentValueExists
{
    STAssertFalse(RKPersistentValueExists(TestDefault1Key), @"RKPersistentValueExists returned wrong result");
    
    RKSetPersistentObject(TestDefault1Key, @"potatoes");
    
    STAssertTrue(RKPersistentValueExists(TestDefault1Key), @"RKPersistentValueExists returned wrong result");
}

@end
