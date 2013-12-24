//
//  ArtModePane.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 6/6/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "ArtModePane.h"
#import "AudioPlayer.h"
#import "BackgroundArtworkDisplayView.h"

@implementation ArtModePane

- (void)dealloc
{
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"MainWindow_artModeSquareSize"];
}

- (void)loadView
{
	[super loadView];
	
	[[NSUserDefaults standardUserDefaults] addObserver:self 
											forKeyPath:@"MainWindow_artModeSquareSize"
											   options:0 
											   context:NULL];
	
	[oArtModeModelView bind:@"image" 
				   toObject:Player 
				withKeyPath:@"artwork" 
					options:@{NSNullPlaceholderBindingOption: [NSImage imageNamed:@"NoArtwork"]}];
	
	[self displayArtModeModel];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if((object == [NSUserDefaults standardUserDefaults]) && [keyPath isEqualToString:@"MainWindow_artModeSquareSize"])
	{
		[self displayArtModeModel];
	}
}

- (void)paneWillBeRemovedFromWindow:(NSWindow *)window
{
	[[oArtModeModelView superview] setWantsLayer:NO];
}

- (void)paneWasAddedToWindow:(NSWindow *)window
{
	[[oArtModeModelView superview] setWantsLayer:YES];
}

- (void)displayArtModeModel
{
	double artModeSquareSize = round([[NSUserDefaults standardUserDefaults] doubleForKey:@"MainWindow_artModeSquareSize"]);
	
	NSRect artModelParentViewFrame = [[oArtModeModelView superview] frame];
	NSRect artModelFrame = [oArtModeModelView frame];
	artModelFrame.size = NSMakeSize(artModeSquareSize, artModeSquareSize);
	artModelFrame.origin.x = round(NSMidX(artModelParentViewFrame) - (NSWidth(artModelFrame) / 2.0));
	artModelFrame.origin.y = round(NSMidY(artModelParentViewFrame) - (NSHeight(artModelFrame) / 2.0));
	
	[oArtModeModelView setFrame:artModelFrame];
}

#pragma mark - Properties

- (NSString *)name
{
	return @"Art Mode";
}

- (NSImage *)icon
{
	return [NSImage imageNamed:@"ArtModeIcon"];
}

#pragma mark - Actions

- (IBAction)restoreDefaultArtModeSize:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setDouble:250.0 forKey:@"MainWindow_artModeSquareSize"];
}

@end
