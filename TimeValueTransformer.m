//
//  TimeStringValueTransformer.m
//  Pinna
//
//  Created by Peter MacWhinnie on 4/2/08.
//  Copyright 2008 Roundabout Software. All rights reserved.
//

#import "TimeValueTransformer.h"

@implementation TimeValueTransformer

+ (Class)transformedValueClass
{
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
	return YES;
}

- (id)transformedValue:(id)value
{
	if(!value)
		return nil;
	
	NSInteger total = [value integerValue];
	
	NSInteger hours = (total / (60 * 60)) % 24;
	NSInteger minutes = (total / 60) % 60;
	NSInteger seconds = total % 60;
	if(hours > 0)
		return [NSString stringWithFormat:@"%ld:%02ld:%02ld", hours, minutes, seconds];
	
	return [NSString stringWithFormat:@"%ld:%02ld", minutes, seconds];
}

- (id)reverseTransformedValue:(id)value
{
	if(!value)
		return nil;
	
	NSArray *components = [value componentsSeparatedByString:@":"];
	switch ([components count])
	{
		case 3: /* hh:mm:ss */
		{
			NSInteger hours = [[components objectAtIndex:0] integerValue];
			NSInteger minutes = [[components objectAtIndex:1] integerValue];
			NSInteger seconds = [[components objectAtIndex:2] integerValue];
			
			return [NSNumber numberWithInteger:(hours * (60 * 60)) + (minutes * 60) + seconds];
		}
			
		case 2: /* mm:ss */
		{
			NSInteger minutes = [[components objectAtIndex:0] integerValue];
			NSInteger seconds = [[components objectAtIndex:1] integerValue];
			
			return [NSNumber numberWithInteger:(minutes * 60) + seconds];
		}
			
		case 1: /* ss */
		{
			NSInteger seconds = [[components objectAtIndex:0] integerValue];
			
			return [NSNumber numberWithInteger:seconds];
		}
			
		default:
			break;
	}
	
	return @"0";
}

@end
