//
//  PreferencesPane.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 6/6/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "PreferencesPane.h"

@implementation PreferencesPane

- (id)init
{
	return [self initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];
}

#pragma mark - Properties

- (NSString *)name
{
	return NSStringFromClass([self class]);
}

- (NSImage *)icon
{
	return [NSImage imageNamed:@"NSApplicationIcon"];
}

#pragma mark - Adding/Removing

- (void)paneWillBeRemovedFromWindow:(NSWindow *)window
{
}

- (void)paneWasAddedToWindow:(NSWindow *)window
{
}

@end
