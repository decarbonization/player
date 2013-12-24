//
//  FileEnumerator.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 1/21/13.
//
//

#ifndef Pinna_FileEnumerator_h
#define Pinna_FileEnumerator_h

RK_INLINE void EnumerateFilesInLocation(NSURL *folderLocation, void(^callback)(NSURL *location))
{
	NSCParameterAssert(folderLocation);
	NSCAssert([folderLocation isFileURL], @"Cannot find files in the cloud, you idiot.");
    
	NSNumber *isDirectory = nil;
	if(![folderLocation getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil])
		NSCAssert(0, @"Couldn't retrieve NSURLIsDirectoryKey for %@", folderLocation);
    
	if(![isDirectory boolValue])
	{
		callback(folderLocation);
		return;
	}
    
	NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:folderLocation
															 includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLTypeIdentifierKey]
																				options:NSDirectoryEnumerationSkipsHiddenFiles
																		   errorHandler:^(NSURL *url, NSError *error) {
																			   NSLog(@"%@ for %@", [error localizedDescription], url);
																			   return NO;
																		   }];
    
	for (NSURL *item in enumerator)
	{
		if(![item getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil])
			NSCAssert(0, @"Couldn't retrieve NSURLIsDirectoryKey for %@", item);
        
		NSString *type = nil;
		if(![item getResourceValue:&type forKey:NSURLTypeIdentifierKey error:nil])
			NSCAssert(0, @"Couldn't retrieve NSURLTypeIdentifierKey for %@", item);
        
		if([isDirectory boolValue] || [type rangeOfString:@"audio"].location == NSNotFound)
			continue;
        
		callback(item);
	}
}

#endif
