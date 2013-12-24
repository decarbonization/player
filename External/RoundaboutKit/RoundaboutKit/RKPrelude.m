//
//  RKPrelude.m
//  NewBrowser
//
//  Created by Kevin MacWhinnie on 2/8/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "RKPrelude.h"

#import <sys/types.h>
#import <unistd.h>

#import <sys/sysctl.h>

#import <CommonCrypto/CommonCrypto.h>

#pragma mark Collection Operations

#pragma mark - • Generation

NSArray *RKCollectionGenerateArray(NSUInteger length, RKGeneratorBlock generator)
{
    NSCParameterAssert(generator);
    
    NSMutableArray *result = [NSMutableArray array];
    
    for (NSUInteger index = 0; index < length; index++) {
        id object = generator(index);
        if(object)
            [result addObject:object];
    }
    
    return result;
}

#pragma mark - • Mapping

NSArray *RKCollectionMapToArray(id input, RKMapperBlock mapper)
{
	return [RKCollectionMapToMutableArray(input, mapper) copyWithZone:[input zone]];
}

NSMutableArray *RKCollectionMapToMutableArray(id input, RKMapperBlock mapper)
{
    NSCParameterAssert(mapper);
	
	NSMutableArray *result = [NSMutableArray array];
	
	for (id object in input) {
		id mappedObject = mapper(object);
		if(mappedObject)
			[result addObject:mappedObject];
	}
	
	return result;
}

NSOrderedSet *RKCollectionMapToOrderedSet(id input, RKMapperBlock mapper)
{
	NSCParameterAssert(mapper);
	
	NSMutableOrderedSet *result = [NSMutableOrderedSet orderedSet];
	
	for (id object in input) {
		id mappedObject = mapper(object);
		if(mappedObject)
			[result addObject:mappedObject];
	}
	
	return [result copyWithZone:[input zone]];
}

#pragma mark - • Filtering

NSArray *RKCollectionFilterToArray(id input, RKPredicateBlock predicate)
{
	NSCParameterAssert(predicate);
	
	NSMutableArray *result = [NSMutableArray array];
	
	for (id object in input) {
		if(predicate(object))
			[result addObject:object];
	}
	
	return [result copyWithZone:[input zone]];
}

#pragma mark - • Matching

id RKCollectionGetFirstObject(id collection)
{
    if([collection count] > 0)
        return collection[0];
    
    return nil;
}

BOOL RKCollectionDoesAnyValueMatch(id input, RKPredicateBlock predicate)
{
	NSCParameterAssert(predicate);
	
	for (id object in input) {
		if(predicate(object))
			return YES;
	}
	
	return NO;
}

BOOL RKCollectionDoAllValuesMatch(id input, RKPredicateBlock predicate)
{
	NSCParameterAssert(predicate);
	
	for (id object in input) {
		if(!predicate(object))
			return NO;
	}
	
	return YES;
}

id RKCollectionFindFirstMatch(id input, RKPredicateBlock predicate)
{
	NSCParameterAssert(predicate);
	
	for (id object in input) {
		if(predicate(object))
			return object;
	}
	
	return nil;
}

#pragma mark - Time Intervals

NSTimeInterval const kRKTimeIntervalInfinite = INFINITY;

NSString *RKMakeStringFromTimeInterval(NSTimeInterval total)
{
	if(total < 0.0 || total == INFINITY)
		return @"-:--";
	
	long long roundedTotal = (long long)round(total);
	NSInteger hours = (roundedTotal / (60 * 60)) % 24;
	NSInteger minutes = (roundedTotal / 60) % 60;
	NSInteger seconds = roundedTotal % 60;
#if __LP64__
	if(hours > 0)
		return [NSString localizedStringWithFormat:@"%ld:%02ld:%02ld", hours, minutes, seconds];
	
	return [NSString localizedStringWithFormat:@"%ld:%02ld", minutes, seconds];
#else
	if(hours > 0)
		return [NSString localizedStringWithFormat:@"%d:%02d:%02d", hours, minutes, seconds];
	
	return [NSString localizedStringWithFormat:@"%d:%02d", minutes, seconds];
#endif
}

#pragma mark - Utilities

BOOL RKProcessIsRunningInDebugger()
{
    //From <http://lists.apple.com/archives/Cocoa-dev/2006/Jun/msg01622.html>
    static BOOL isRunningInDebugger = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct kinfo_proc info;
        size_t infoSize = sizeof(info);
        int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, getppid() };
        
        char nameBuffer[255];
        if(sysctl(mib, 4, &info, &infoSize, NULL, 0) == noErr) {
            
            strncpy(nameBuffer, info.kp_proc.p_comm, sizeof(nameBuffer));
            
            isRunningInDebugger = ((strcmp(nameBuffer, "gdb") == 0) ||
                                   (strcmp(nameBuffer, "lldb") == 0) ||
                                   (strcmp(nameBuffer, "debugserver") == 0));
        }
    });
    
    return isRunningInDebugger;
}

#pragma mark -

NSString *RKSanitizeStringForSorting(NSString *string)
{
	if([string length] <= 4)
		return string;
	
	NSRange rangeOfThe = [string rangeOfString:@"the " options:(NSAnchoredSearch | NSCaseInsensitiveSearch) range:NSMakeRange(0, 4)];
	if(rangeOfThe.location != NSNotFound)
		return [string substringFromIndex:NSMaxRange(rangeOfThe)];
	
	return string;
}

NSString *RKGenerateIdentifierForStrings(NSArray *strings)
{
    NSCParameterAssert(strings);
    
    NSString *(^sanitize)(NSString *) = ^(NSString *string)
    {
        //An identifier cannot contain whitespace, punctuation, or symbols.
        //We create an all encompassing character set to test for these.
        static NSMutableCharacterSet *charactersToRemove = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            charactersToRemove = [NSMutableCharacterSet new];
            [charactersToRemove formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [charactersToRemove formUnionWithCharacterSet:[NSCharacterSet symbolCharacterSet]];
            [charactersToRemove formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
        });
        
        NSMutableString *resultString = [[string lowercaseString] mutableCopy];
        for (NSUInteger index = 0; index < [resultString length]; index++)
        {
            unichar character = [resultString characterAtIndex:index];
            if([charactersToRemove characterIsMember:character])
            {
                [resultString deleteCharactersInRange:NSMakeRange(index, 1)];
                index--;
            }
        }
        
        return resultString;
    };
    
    NSArray *sanitizedStrings = RKCollectionMapToArray(strings, ^(NSString *string) {
        return sanitize(string);
    });
    NSArray *sortedStrings = [sanitizedStrings sortedArrayUsingSelector:@selector(compare:)];
    return [sortedStrings componentsJoinedByString:@""];
}

#pragma mark -

id RKJSONDictionaryGetObjectAtKeyPath(NSDictionary *dictionary, NSString *keyPath)
{
    NSCParameterAssert(keyPath);
    if(!RKFilterOutNSNull(dictionary))
        return nil;
    
    NSArray *keys = [keyPath componentsSeparatedByString:@"."];
    id value = dictionary;
    for (NSString *key in keys) {
        value = RKFilterOutNSNull([value valueForKey:key]);
    }
    
    return value;
}

#pragma mark -

NSString *RKStringGetMD5Hash(NSString *string)
{
    if(!string)
        return nil;
    
    const char *identifierAsCString = [string UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(identifierAsCString, (CC_LONG)strlen(identifierAsCString), result);
    
    NSMutableString *sanitizedIdentifier = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSUInteger index = 0; index < CC_MD5_DIGEST_LENGTH; index++) {
        [sanitizedIdentifier appendFormat:@"%02x", result[index]];
    }
    
    return sanitizedIdentifier;
}

#pragma mark -

RKURLParameterStringifier kRKURLParameterStringifierDefault = ^NSString *(id value) {
    if([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
        NSError *error = nil;
        NSData *JSONData = [NSJSONSerialization dataWithJSONObject:value options:0 error:&error];
        if(!JSONData)
            [NSException raise:NSInternalInconsistencyException format:@"Invalid JSON object passed. %@", [error localizedDescription]];
        
        return [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding];
    }
    return [value description];
};

NSString *RKStringEscapeForInclusionInURL(NSString *string, NSStringEncoding encoding)
{
    if(!string)
        return nil;
    
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                 (__bridge CFStringRef)(string),
                                                                                 NULL,
                                                                                 CFSTR("!*'();:@&=+$/?%#[]"),
                                                                                 CFStringConvertNSStringEncodingToEncoding(encoding));
}

RK_OVERLOADABLE NSString *RKDictionaryToURLParametersString(NSDictionary *parameters, RKURLParameterStringifier valueStringifier)
{
    NSCParameterAssert(valueStringifier);
    
    if(parameters.count == 0)
        return @"";
    
	NSMutableString *parameterString = [NSMutableString string];
	
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
		[parameterString appendFormat:@"%@=%@&", RKStringEscapeForInclusionInURL(key, NSUTF8StringEncoding), RKStringEscapeForInclusionInURL(valueStringifier(value), NSUTF8StringEncoding)];
	}];
	
	//Remove the trailing '&' from the query string.
	[parameterString deleteCharactersInRange:NSMakeRange([parameterString length] - 1, 1)];
	
	return parameterString;
}

RK_OVERLOADABLE NSString *RKDictionaryToURLParametersString(NSDictionary *parameters)
{
    return RKDictionaryToURLParametersString(parameters, kRKURLParameterStringifierDefault);
}

#pragma mark - Mac Image Tools

#if TARGET_OS_MAC && defined(_APPKITDEFINES_H)

static NSData *NSImageRepresentationOfType(NSImage *image, NSBitmapImageFileType fileType)
{
    if(!image)
        return nil;
    
	for (id imageRep in [image representations])
	{
		if([imageRep respondsToSelector:@selector(representationUsingType:properties:)])
			return [imageRep representationUsingType:fileType properties:nil];
	}
	
	NSBitmapImageRep *temporaryImageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
	return [temporaryImageRep representationUsingType:fileType properties:nil];
}

RK_OVERLOADABLE NSData *NSImagePNGRepresentation(NSImage *image)
{
    return NSImageRepresentationOfType(image, NSPNGFileType);
}

RK_OVERLOADABLE NSData *NSImageJPGRepresentation(NSImage *image)
{
    return NSImageRepresentationOfType(image, NSJPEGFileType);
}

#endif /* TARGET_OS_MAC && defined(_APPKITDEFINES_H) */
