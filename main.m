//
//  main.m
//  Pinna
//
//  Created by Peter MacWhinnie on 9/24/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "AccountManager.h"
#import "ServiceDescriptor.h"
#import "Account.h"

#import "LastFMDefines.h"

int main(int argc, char *argv[])
{
	@autoreleasepool {
		NSURL *defaultValuesLocation = [[NSBundle mainBundle] URLForResource:@"UserDefaults" withExtension:@"plist"];
		NSDictionary *defaultValues = [NSDictionary dictionaryWithContentsOfURL:defaultValuesLocation];
		if(defaultValues)
		{
			[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
		}
		else
		{
			NSLog(@"Could not load UserDefaults.plist");
			abort();
		}
	}
	
	return NSApplicationMain(argc, (const char **)argv);
}
