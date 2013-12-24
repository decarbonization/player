//
//  SimpleNumberTransformer.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 1/4/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "SimpleNumberTransformer.h"

@implementation SimpleNumberTransformer

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
	return [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:[value integerValue]] 
											numberStyle:NSNumberFormatterDecimalStyle];
}

@end
