//
//  UppercaseStringTransformer.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 9/15/12.
//
//

#import "UppercaseStringTransformer.h"

@implementation UppercaseStringTransformer

+ (Class)transformedValueClass
{
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(id)value
{
	//For 10.8+
	if([value respondsToSelector:@selector(uppercaseStringWithLocale:)])
		return [value uppercaseStringWithLocale:nil];
	
	return [value uppercaseString];
}

@end
