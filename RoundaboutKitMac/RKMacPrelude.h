/*
 *  RKMacPrelude.h
 *  BeyondKit
 *
 *  Created by Peter MacWhinnie on 2/27/11.
 *  Copyright 2011 Roundabout Software, LLC. All rights reserved.
 *
 */

#ifndef RKMacPrelude_h
#define RKMacPrelude_h 1

#pragma mark - Easy Shadow Creation

RK_INLINE NSShadow *RKShadowMake(NSColor *color, CGFloat blurRadius, NSSize offset)
{
	NSShadow *shadow = [NSShadow new];
	
	[shadow setShadowColor:color];
	[shadow setShadowBlurRadius:blurRadius];
	[shadow setShadowOffset:offset];
	
	return shadow;
}

#pragma mark - String Representations

///Format: (r, g, b, a)
RK_INLINE NSString *RKStringFromColor(NSColor *color)
{
	NSColor *rgbaColor = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	return [NSString stringWithFormat:@"(%f, %f, %f, %f)", [rgbaColor redComponent] * 255.0, [rgbaColor greenComponent] * 255.0, [rgbaColor blueComponent] * 255.0, [rgbaColor alphaComponent]];
}

RK_INLINE NSColor *RKStringToColor(NSString *string)
{
	if(![string hasPrefix:@"("] || ![string hasSuffix:@")"])
	{
		NSLog(@"Malformed color string %@", string);
		return nil;
	}
	
	NSString *justComponents = [string substringWithRange:NSMakeRange(1, [string length] - 2)];
	NSArray *components = [justComponents componentsSeparatedByString:@", "];
	if([components count] != 4)
	{
		NSLog(@"Malformed color string %@, does not have 4 numbers", string);
		return nil;
	}
	
	CGFloat red = [[components objectAtIndex:0] floatValue] / 255.0;
	CGFloat green = [[components objectAtIndex:1] floatValue] / 255.0;
	CGFloat blue = [[components objectAtIndex:2] floatValue] / 255.0;
	CGFloat alpha = [[components objectAtIndex:3] floatValue];
	
	return [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
}

///Format:[color-stop-1, 2, ...]: (r, g, b, a); (r, g, b, a); (r, g, b, a) ...
RK_INLINE NSGradient *RKStringToGradient(NSString *gradientString)
{
	if((![gradientString hasPrefix:@"["] && ![gradientString hasPrefix:@"("]) || ![gradientString hasSuffix:@")"])
	{
		NSLog(@"Malformed gradient string %@", gradientString);
		return nil;
	}
	
	CGFloat *colorStops = NULL;
	if([gradientString hasPrefix:@"["])
	{
		NSRange rangeOfEndOfStops = [gradientString rangeOfString:@"]: "];
		if(rangeOfEndOfStops.location == NSNotFound)
		{
			NSLog(@"Malformed gradient string %@, does not have ].", gradientString);
			return nil;
		}
		
		NSString *rawColorStops = [gradientString substringWithRange:NSMakeRange(1, rangeOfEndOfStops.location - 1)];
		NSArray *colorStopStrings = [rawColorStops componentsSeparatedByString:@", "];
		colorStops = malloc(sizeof(CGFloat) * [colorStopStrings count]);
		[colorStopStrings enumerateObjectsUsingBlock:^(NSString *colorStopString, NSUInteger index, BOOL *stop) {
			colorStops[index] = [colorStopString floatValue];
		}];
		
		gradientString = [gradientString substringFromIndex:NSMaxRange(rangeOfEndOfStops)];
	}
	
	NSArray *rawColors = [gradientString componentsSeparatedByString:@"; "];
	
	NSArray *colors = RKCollectionMapToArray(rawColors, ^(NSString *colorString) {
		return RKStringToColor(colorString);
	});
	
	if(colorStops)
	{
		NSGradient *gradient = [[NSGradient alloc] initWithColors:colors 
													  atLocations:colorStops 
													   colorSpace:[NSColorSpace genericRGBColorSpace]];
		
		free(colorStops);
		
		return gradient;
	}
	
	return [[NSGradient alloc] initWithColors:colors];
}

#endif /* RKMacPrelude_h */
