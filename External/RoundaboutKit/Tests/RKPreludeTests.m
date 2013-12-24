//
//  RKPreludeTests.m
//  RoundaboutKitTests
//
//  Created by Kevin MacWhinnie on 4/12/13.
//
//

#import "RKPreludeTests.h"

@implementation RKPreludeTests {
    NSArray *_pregeneratedArray;
    NSDictionary *_pregeneratedDictionary;
}

- (void)setUp
{
    [super setUp];
    
    _pregeneratedArray = @[ @"1", @"2", @"3", @"4", @"5" ];
    _pregeneratedDictionary = @{
        @"test1": @{@"leaf1": @[]},
        @"test2": [NSNull null],
        @"test3": @[]
    };
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark -

- (void)testTime
{
    STAssertTrue(RK_TIME_MINUTE == 60.0, @"RK_TIME_MINUTE wrong value");
    STAssertTrue(RK_TIME_HOUR == 3600.0, @"RK_TIME_HOUR wrong value");
    STAssertTrue(RK_TIME_DAY == 86400, @"RK_TIME_DAY wrong value");
    STAssertTrue(RK_TIME_WEEK == 604800.0, @"RK_TIME_WEEK wrong value");
    STAssertTrue(kRKTimeIntervalInfinite == INFINITY, @"kRKTimeIntervalInfinite is not infinite");
    STAssertEqualObjects(RKMakeStringFromTimeInterval(150.0), @"2:30", @"RKMakeStringFromTimeInterval w/value returned wrong value");
    STAssertEqualObjects(RKMakeStringFromTimeInterval(-150.0), @"-:--", @"RKMakeStringFromTimeInterval w/negative value returned wrong value");
}

#pragma mark - Collection Operations
#pragma mark - • Generation

- (void)testCollectionGeneration
{
    NSArray *generatedArray = RKCollectionGenerateArray(5, ^id(NSUInteger index) {
        return [NSString stringWithFormat:@"%ld", index + 1];
    });
    STAssertEqualObjects(generatedArray, _pregeneratedArray, @"RKCollectionGenerateArray returned incorrect value");
}

#pragma mark - • Mapping

- (void)testCollectionMapToArray
{
    NSArray *mappedArray = RKCollectionMapToArray(_pregeneratedArray, ^id(NSString *value) {
        return [value stringByAppendingString:@"0"];
    });
    NSArray *expectedArray = @[ @"10", @"20", @"30", @"40", @"50" ];
    STAssertEqualObjects(mappedArray, expectedArray, @"RKCollectionMapToArray returned incorrect value");
}

- (void)testCollectionMapToMutableArray
{
    NSMutableArray *mappedArray = RKCollectionMapToMutableArray(_pregeneratedArray, ^id(NSString *value) {
        return [value stringByAppendingString:@"0"];
    });
    NSArray *expectedArray = @[ @"10", @"20", @"30", @"40", @"50" ];
    STAssertEqualObjects(mappedArray, expectedArray, @"RKCollectionMapToMutableArray returned incorrect value");
    
    STAssertNoThrow([mappedArray addObject:@"60"], @"RKCollectionMapToMutableArray returned non-mutable array");
}

- (void)testCollectionMapToOrderedSet
{
    NSOrderedSet *mappedOrderedSet = RKCollectionMapToOrderedSet(_pregeneratedArray, ^id(NSString *value) {
        return [value stringByAppendingString:@"0"];
    });
    NSOrderedSet *expectedOrderedSet = [NSOrderedSet orderedSetWithObjects:@"10", @"20", @"30", @"40", @"50", nil];
    STAssertEqualObjects(mappedOrderedSet, expectedOrderedSet, @"RKCollectionMapToOrderedSet returned incorrect value");
}

#pragma mark - • Filtering

- (void)testFilterToArray
{
    NSArray *filteredArray = RKCollectionFilterToArray(_pregeneratedArray, ^BOOL(NSString *value) {
        return ([value integerValue] % 2 == 0);
    });
    NSArray *expectedArray = @[ @"2", @"4" ];
    STAssertEqualObjects(filteredArray, expectedArray, @"RKCollectionFilterToArray returned incorrect value");
}

#pragma mark - • Matching

- (void)testDoesAnyValueMatch
{
    BOOL doesAnyValueMatch = RKCollectionDoesAnyValueMatch(_pregeneratedArray, ^BOOL(NSString *value) {
        return [value isEqualToString:@"3"];
    });
    STAssertTrue(doesAnyValueMatch, @"RKCollectionDoesAnyValueMatch returned incorrect value");
}

- (void)testDoAllValuesMatch
{
    BOOL doAllValuesMatch = RKCollectionDoAllValuesMatch(_pregeneratedArray, ^BOOL(NSString *value) {
        return [value integerValue] != 0;
    });
    STAssertTrue(doAllValuesMatch, @"RKCollectionDoAllValuesMatch returned incorrect value");
}

- (void)testFindFirstMatch
{
    NSString *firstMatch = RKCollectionFindFirstMatch(_pregeneratedArray, ^BOOL(NSString *value) {
        return [value isEqualToString:@"3"];
    });
    
    STAssertEqualObjects(firstMatch, @"3", @"RKCollectionFindFirstMatch returned incorrect value");
}

#pragma mark - Safe Casting

- (void)testCast
{
    STAssertThrows((void)RK_CAST(NSArray, @"this should fail"), @"RK_CAST failed to catch incompatibility between NSArray and NSString");
    STAssertNoThrow((void)RK_CAST(NSString, [@"this should fail" mutableCopy]), @"RK_CAST failed to match compatibility between NSString and NSMutableString");
}

- (void)testTryCast
{
    STAssertNil(RK_TRY_CAST(NSArray, @"this should fail"), @"RK_TRY_CAST failed to catch incompatibility between NSArray and NSString");
    STAssertNotNil(RK_CAST(NSString, [@"this should fail" mutableCopy]), @"RK_TRY_CAST failed to match compatibility between NSString and NSMutableString");
}

#pragma mark - Utilities

- (void)testSanitizeStringForSorting
{
    STAssertEqualObjects(RKSanitizeStringForSorting(@"The Beatles"), @"Beatles", @"RKSanitizeStringForSorting returned incorrect value");
    STAssertEqualObjects(RKSanitizeStringForSorting(@"the beatles"), @"beatles", @"RKSanitizeStringForSorting returned incorrect value");
    STAssertEqualObjects(RKSanitizeStringForSorting(@"Eagles"), @"Eagles", @"RKSanitizeStringForSorting returned incorrect value");
}

- (void)testGenerateIdentifierForStrings
{
    STAssertEqualObjects(RKGenerateIdentifierForStrings(@[@"first", @"Second", @"()[].,", @"THIRD"]), @"firstsecondthird", @"RKGenerateIdentifierForStrings returned incorrect value");
}

- (void)testFilterOutNSNull
{
    STAssertNil(RKFilterOutNSNull([NSNull null]), @"RKFilterOutNSNull didn't filter out NSNull");
}

- (void)testJSONDictionaryGetObjectAtKeyPath
{
    STAssertEqualObjects(RKJSONDictionaryGetObjectAtKeyPath(_pregeneratedDictionary, @"test1.leaf1"), @[], @"RKJSONDictionaryGetObjectAtKeyPath not indexing correctly");
    STAssertNil(RKJSONDictionaryGetObjectAtKeyPath(_pregeneratedDictionary, @"test2.leaf2"), @"RKJSONDictionaryGetObjectAtKeyPath not indexing correctly");
    STAssertEqualObjects(RKJSONDictionaryGetObjectAtKeyPath(_pregeneratedDictionary, @"test3"), @[], @"RKJSONDictionaryGetObjectAtKeyPath not indexing correctly");
}

#pragma mark -

- (void)testStringGetMD5Hash
{
    NSString *hashedString = RKStringGetMD5Hash(@"test string");
    STAssertEqualObjects(hashedString, @"6f8db599de986fab7a21625b7916589c", @"Unexpected hash result");
}

- (void)testStringEscapeForInclusionInURL
{
    NSString *escapedString = RKStringEscapeForInclusionInURL(@"This is a lovely string :/?#[]@!$&'()*+,;=", NSUTF8StringEncoding);
    STAssertEqualObjects(escapedString, @"This%20is%20a%20lovely%20string%20:/?#[]@!$&'()*+,;=", @"Unexpected escape result");
}

- (void)testDictionaryToURLParametersString
{
    NSDictionary *test = @{@"test": @"value"};
    
    NSString *result = RKDictionaryToURLParametersString(test, kRKURLParameterStringifierDefault);
    STAssertEqualObjects(result, @"test=value", @"Unexpected result");
}

@end
