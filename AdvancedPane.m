//
//  LibraryPane.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 2/7/13.
//
//

#import "AdvancedPane.h"
#import "Library.h"

@interface AdvancedPane () <NSOpenSavePanelDelegate>

@end

@implementation AdvancedPane

- (id)init
{
    if((self = [super init])) {
        mLibrary = [Library sharedLibrary];
    }
    
    return self;
}

- (void)loadView
{
	[super loadView];
	
}

#pragma mark - Properties

- (NSString *)name
{
	return @"Advanced";
}

- (NSImage *)icon
{
	return [NSImage imageNamed:NSImageNameAdvanced];
}

#pragma mark - Interface Hooks

+ (NSSet *)keyPathsForValuesAffectingIcon
{
    return [NSSet setWithObjects:@"mLibrary.iTunesFolderLocation", nil];
}

- (NSImage *)folderIcon
{
    return [[NSWorkspace sharedWorkspace] iconForFile:[mLibrary.iTunesFolderLocation path]];
}

+ (NSSet *)keyPathsForValuesAffectingFolderName
{
    return [NSSet setWithObjects:@"mLibrary.iTunesFolderLocation", nil];
}

- (NSString *)folderName
{
    return [[mLibrary.iTunesFolderLocation lastPathComponent] stringByDeletingPathExtension];
}

+ (NSSet *)keyPathsForValuesAffectingFolderLocation
{
    return [NSSet setWithObjects:@"mLibrary.iTunesFolderLocation", nil];
}

- (NSString *)folderLocation
{
    return [mLibrary.iTunesFolderLocation path];
}

#pragma mark - Verifying Folders

- (BOOL)isFolderAtLocationAnITunesLibrary:(NSURL *)location
{
    NSString *locationType = nil;
    NSError *error = nil;
    NSAssert([location getResourceValue:&locationType forKey:NSURLFileResourceTypeKey error:&error],
             @"Could not get NSURLFileResourceTypeKey for %@. %@", location, error);
    
    if(![locationType isEqualToString:NSURLFileResourceTypeDirectory])
    {
        return NO;
    }
    
	NSArray *folderContents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:location
                                                            includingPropertiesForKeys:nil
                                                                               options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                                 error:&error];
	if(!folderContents)
	{
        NSLog(@"Could not list folder");
		return NO;
	}
	
	for (NSURL *libraryLocation in folderContents)
    {
		if([[libraryLocation lastPathComponent] isLike:@"*iTunes*.xml"])
            return YES;
	}
    
    return NO;
}

#pragma mark - Actions

- (IBAction)useDefaultLibraryLocation:(id)sender
{
    //We set iTunesFolderLocation to have library takeover
    //in determining the location of the iTunes library.
    mLibrary.iTunesFolderLocation = nil;
}

- (IBAction)changeLibraryLocation:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setResolvesAliases:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setTitle:@"Choose Library Folder"];
    [openPanel setPrompt:@"Choose"];
    [openPanel setDelegate:self];
    
    [openPanel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result) {
        if(result != NSOKButton)
            return;
        
        NSURL *libraryLocation = [[openPanel URLs] lastObject];
        if([self isFolderAtLocationAnITunesLibrary:libraryLocation])
        {
            mLibrary.iTunesFolderLocation = libraryLocation;
        }
        else
        {
            [[NSAlert alertWithMessageText:@"Folder Selected Was Not an iTunes Library"
                             defaultButton:@"OK"
                           alternateButton:nil
                               otherButton:nil
                 informativeTextWithFormat:@"The folder selected was not a valid iTunes library and cannot be used by Pinna."] runModal];
        }
    }];
}

@end
