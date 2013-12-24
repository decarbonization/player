//
//  BackgroundArtworkDisplayView.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 12/27/11.
//  Copyright (c) 2011 Roundabout Software, LLC. All rights reserved.
//

#import "BackgroundArtworkDisplayView.h"
#import <Quartz/Quartz.h>
#import "AudioPlayer.h"
#import "Library.h"
#import "Song.h"

#import "FileEnumerator.h"

@implementation BackgroundArtworkDisplayView

- (id)initWithFrame:(NSRect)frame
{
	if((self = [super initWithFrame:frame]))
	{
		[self registerForDraggedTypes:@[kSongUTI, (__bridge NSString *)kUTTypeFileURL]];
	}
	
	return self;
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
	NSRect drawingRect = [self bounds];
	
	[[NSColor blackColor] set];
	[NSBezierPath fillRect:drawingRect];
	
	if(mImage)
	{
		NSRect imageRect = NSZeroRect;
		imageRect.size = [mImage size];
		
		CGFloat delta = drawingRect.size.width / imageRect.size.width;
		imageRect.size.width *= delta;
		imageRect.size.height *= delta;
		imageRect.origin.x = NSMidX(drawingRect) - (NSWidth(imageRect) / 2.0);
		imageRect.origin.y = NSMidY(drawingRect) - (NSHeight(imageRect) / 2.0);
		
		[mImage setFlipped:NO];
		[mImage drawInRect:imageRect 
				  fromRect:NSZeroRect 
				 operation:NSCompositeSourceOver 
				  fraction:1.0 
			respectFlipped:YES 
					 hints:nil];
		
		[[NSColor colorWithDeviceWhite:0.0 alpha:0.5] set];
		[[NSBezierPath bezierPathWithRect:drawingRect] strokeInside];
		
        NSRect topLineRect = NSMakeRect(1.0, NSHeight(drawingRect) - 2.0, 
										NSWidth(drawingRect) - 2.0, 1.0);
		[[NSColor colorWithDeviceWhite:1.0 alpha:0.45] set];
		[NSBezierPath fillRect:topLineRect];
	}
}

#pragma mark - Properties

@synthesize image = mImage;
- (void)setImage:(NSImage *)image
{
	mImage = [image copy];
	[self setNeedsDisplay:YES];
}

#pragma mark - Drop Destination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	return NSDragOperationCopy;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	return NSDragOperationCopy;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pasteboard = [sender draggingPasteboard];
	
	NSArray *songs = nil;
	if([pasteboard canReadObjectForClasses:@[[Song class]] options:nil])
	{
		songs = [pasteboard readObjectsForClasses:@[[Song class]] options:nil];
	}
	else if([pasteboard canReadObjectForClasses:@[[NSURL class]] options:nil])
	{
		NSArray *fileURLs = [pasteboard readObjectsForClasses:@[[NSURL class]] options:nil];
		NSMutableArray *songsFromFiles = [NSMutableArray array];
		for (NSURL *fileURL in fileURLs)
		{
			EnumerateFilesInLocation(fileURL, ^(NSURL *songLocation) {
				Song *song = [[Song alloc] initWithLocation:songLocation];
				if(song)
					[songsFromFiles addObject:song];
			});
		}
		songs = songsFromFiles;
	}
	
	if(songs)
	{
		if(Player.shuffleMode && [songs count] == 1)
		{
			NSDate *lastDropTime = [self associatedValueForKey:@"previousDropTimeInshuffleMode"];
			
			if(lastDropTime && ([[NSDate date] timeIntervalSinceDate:lastDropTime] <= 1.0))
			{
				Player.shuffleMode = NO;
				[Player addSongsToPlayQueue:songs];
			}
			else
			{
				Player.nextShuffleSong = RKCollectionGetFirstObject(songs);
			}
			
			
			[self setAssociatedValue:[NSDate date] forKey:@"previousDropTimeInshuffleMode"];
		}
		else
		{
			[Player addSongsToPlayQueue:songs];
		}
		
		
		return YES;
	}
	
	return NO;
}

#pragma mark - Events

@synthesize isMouseInView = mIsMouseInView;

- (void)mouseUp:(NSEvent *)event
{
	mIsMouseInView = NO;
	[super mouseUp:event];
}

- (void)mouseDown:(NSEvent *)event
{
	mIsMouseInView = YES;
	[super mouseDown:event];
}

@end
