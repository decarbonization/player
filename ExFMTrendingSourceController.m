//
//  ExFMTrendingSourceController.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 6/17/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "ExFMTrendingSourceController.h"
#import "RKAnimator.h"
#import "RKBorderlessWindow.h"

static NSString *const kTrendingTagUserDefaultsKey = @"ExFM_trendingTag";

@interface ExFMTrendingSourceController () <NSWindowDelegate>

@end

@implementation ExFMTrendingSourceController

- (id)init
{
	if((self = [super initWithWindowNibName:@"ExFMTrendingSource"]))
	{
		
	}
	return self;
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	
	RKBorderlessWindow *window = (RKBorderlessWindow *)([self window]);
	[window setExcludedFromWindowsMenu:YES];
	[window setCollectionBehavior:NSWindowCollectionBehaviorTransient | NSWindowCollectionBehaviorIgnoresCycle];
	[window setLevel:NSSubmenuWindowLevel];
	
	NSURL *genresLocation = [[NSBundle mainBundle] URLForResource:@"Genres" withExtension:@"plist"];
	NSArray *genres = [NSArray arrayWithContentsOfURL:genresLocation];
	[oContentController setContent:genres];
	
	NSString *selectedTrendingTag = RKGetPersistentObject(kTrendingTagUserDefaultsKey);
	if(selectedTrendingTag)
	{
		NSUInteger indexOfSelectedTag = [[oContentController arrangedObjects] indexOfObjectPassingTest:^BOOL(NSDictionary *genre, NSUInteger index, BOOL *stop) {
			return [[genre objectForKey:@"tag"] isEqualToString:selectedTrendingTag];
		}];
		[oContentController setSelectionIndex:indexOfSelectedTag];
	}
	else
	{
		[oContentController setSelectionIndex:0];
	}
	
	[oContentController addObserver:self forKeyPath:@"selectedObjects" options:0 context:NULL];
}

#pragma mark - Callbacks

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(object == oContentController && [keyPath isEqualToString:@"selectedObjects"])
	{
		NSDictionary *selectedGenre = [[oContentController selectedObjects] lastObject];
		RKSetPersistentObject(kTrendingTagUserDefaultsKey, [selectedGenre objectForKey:@"tag"]);
		
		[self hide];
	}
}

- (void)windowDidResignKey:(NSNotification *)notification
{
	[self hide];
}

#pragma mark - Showing/Hiding

- (void)showBelowView:(NSView *)view
{
	if([[self window] isVisible])
		return;
	
	NSPoint headerLocation = [view convertPoint:NSMakePoint(NSMidX([view frame]), 0.0) toView:nil];
	
	NSRect popUpFrame = [[self window] frame];
	popUpFrame.origin.y = headerLocation.y - NSHeight(popUpFrame);
	popUpFrame.origin.x = headerLocation.x - (NSWidth(popUpFrame) / 2.0);
	
	NSRect popUpFrameOnScreen = [[view window] convertRectToScreen:popUpFrame];
	
	[[self window] setAlphaValue:1.0];
	[[self window] setFrame:popUpFrameOnScreen display:NO];
	[[self window] makeKeyAndOrderFront:nil];
}

- (void)hide
{
    [[RKAnimator animator] transaction:^(RKAnimatorTransaction *transaction) {
        [transaction fadeOutTarget:[self window]];
    } completionHandler:^(BOOL didFinish) {
        [[self window] close];
    }];
}

@end
