//
//  ExfmSession+CachedSongs.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/12/13.
//
//

#import "ExfmSession+CachedSongs.h"
#import "NSObject+AssociatedValues.h"

NSString *const ExfmSessionUpdatedCachedLovedSongsNotification = @"ExfmSessionUpdatedCachedLovedSongsNotification";
NSString *const ExfmSessionUpdatedCachedLovedSongsOfFriendsNotification = @"ExfmSessionUpdatedCachedLovedSongsOfFriendsNotification";
NSString *const ExfmSessionLoadedCachedSongsNotification = @"ExfmSessionLoadedCachedSongsNotification";
NSString *const ExfmSessionUnloadedCachedSongsNotification = @"ExfmSessionUnloadedCachedSongsNotification";

static NSString *const kCachedLovedSongsUserDefaultsKey = @"Exfm_cachedLovedSongs";
static NSString *const kCachedLoveFriendActivitiesUserDefaultsKey = @"Exfm_cachedFriendLoveActivity";

@implementation ExfmSession (CachedSongs)

- (void)loadCachedSongsFromUserDefaults
{
	if([self areCachedLovedSongsLoaded])
		return;
	
	@synchronized(self) {
		NSData *cachedLovedSongs = RKGetPersistentObject(kCachedLovedSongsUserDefaultsKey);
		if(cachedLovedSongs)
            [self setAssociatedValue:[NSKeyedUnarchiver unarchiveObjectWithData:cachedLovedSongs] forKey:@"cachedLovedSongs"];
		else
            [self setAssociatedValue:@[] forKey:@"cachedLovedSongs"];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ExfmSessionLoadedCachedSongsNotification object:self];
}

- (void)unloadCachedSongs
{
	if(![self areCachedLovedSongsLoaded])
		return;
	
	[self setAssociatedValue:nil forKey:@"cachedLovedSongs"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ExfmSessionUnloadedCachedSongsNotification object:self];
}

- (BOOL)areCachedLovedSongsLoaded
{
	return ([self associatedValueForKey:@"cachedLovedSongs"] != nil);
}

#pragma mark -

- (BOOL)areLocalCachedSongs:(NSArray *)localSongs upToDateWithRemoteSongs:(NSArray *)remoteSongs
{
    if([localSongs count] == 0 || [remoteSongs count] == 0 || remoteSongs.count != localSongs.count)
        return NO;
    
    NSString *firstRemoteSongID = remoteSongs[0][@"id"];
    NSString *firstCachedSongID = localSongs[0][@"id"];
    
    return ([firstRemoteSongID isEqual:firstCachedSongID] &&
            [localSongs[remoteSongs.count - 1] isEqual:[remoteSongs lastObject]]);
}

- (void)updateCachedFriendLoveActivities
{
    RKURLRequestPromise *lovedSongsOfFriendsPromise = (RKURLRequestPromise *)[self lovedSongsOfFriendsFeedStartingAtOffset:0];
    [lovedSongsOfFriendsPromise then:^(NSDictionary *response) {
        NSArray *localSongs = [self.cachedFriendLoveActivity valueForKeyPath:@"activities.object"];
        NSArray *remoteSongs = [response valueForKeyPath:@"activities.object"];
        if([self areLocalCachedSongs:localSongs upToDateWithRemoteSongs:remoteSongs])
        {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.numberOfNewFriendLoveActivities = 0;
                
                [[NSNotificationCenter defaultCenter] postNotificationName:ExfmSessionUpdatedCachedLovedSongsOfFriendsNotification object:self];
            }];
            
            return;
        }
        
        NSUInteger numberOfNewLovedSongsOfFriends = 0;
        if(localSongs.count == 0)
        {
            numberOfNewLovedSongsOfFriends = [remoteSongs count];
        }
        else
        {
            NSUInteger indexOfLastLocalSong = [remoteSongs indexOfObject:localSongs[0]];
            if(indexOfLastLocalSong == NSNotFound)
                numberOfNewLovedSongsOfFriends = [remoteSongs count];
            else
                numberOfNewLovedSongsOfFriends = indexOfLastLocalSong;
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.numberOfNewFriendLoveActivities = numberOfNewLovedSongsOfFriends;
            
            [self willChangeValueForKey:@"cachedFriendLoveActivity"];
            RKSetPersistentObject(kCachedLoveFriendActivitiesUserDefaultsKey, [NSKeyedArchiver archivedDataWithRootObject:response]);
            [self didChangeValueForKey:@"cachedFriendLoveActivity"];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:ExfmSessionUpdatedCachedLovedSongsOfFriendsNotification object:self];
        }];
    } otherwise:^(NSError *error) {
        NSLog(@"*** Could not update loved songs of friends.");
    } onQueue:[[self class] sessionRequestQueue]];
}

- (void)updateCachedSongs
{
	if(!self.username) {
		@synchronized(self) {
			[self willChangeValueForKey:@"lovedSongs"];
			[self setAssociatedValue:@[] forKey:@"cachedLovedSongs"];
			[self didChangeValueForKey:@"lovedSongs"];
			
			RKSetPersistentObject(kCachedLovedSongsUserDefaultsKey, nil);
			
			[[NSNotificationCenter defaultCenter] postNotificationName:ExfmSessionUpdatedCachedLovedSongsNotification object:self];
		}
		
		return;
	}
    
    //We just don't refresh if the internet connection is offline.
    if(![RKConnectivityManager defaultInternetConnectivityManager].isConnected) {
        return;
    }
	
	if(![self areCachedLovedSongsLoaded])
		[self loadCachedSongsFromUserDefaults];
	
    [self updateCachedFriendLoveActivities];
    
	RKURLRequestPromise *initialLovedSongsPromise = (RKURLRequestPromise *)[self lovedSongsStartingAtOffset:0];
	[initialLovedSongsPromise then:^(id response) {
		NSInteger totalSongs = [RKFilterOutNSNull(response[@"total"]) integerValue];
		NSArray *remoteSongs = response[@"songs"];
		NSArray *localSongs = [self.cachedLovedSongs copy];
		
		if([localSongs count] == totalSongs &&
           [self areLocalCachedSongs:localSongs upToDateWithRemoteSongs:remoteSongs])
        {
			return;
		}
		
		NSMutableArray *newLovedSongs = [NSMutableArray array];
		[newLovedSongs addObjectsFromArray:remoteSongs];
		
        NSUInteger offset = 50;
        for (;;)
        {
            NSError *error = nil;
            NSDictionary *response = [[self lovedSongsStartingAtOffset:offset] await:&error];
            if(!response)
            {
                NSLog(@"Could not fetch loved songs. Error: %@", error);
                break;
            }
            
            remoteSongs = response[@"songs"];
            if([remoteSongs count] > 0) {
				[newLovedSongs addObjectsFromArray:remoteSongs];
				
				offset += 50;
			} else {
				RKSetPersistentObject(kCachedLovedSongsUserDefaultsKey, [NSKeyedArchiver archivedDataWithRootObject:newLovedSongs]);
				
				[[NSOperationQueue mainQueue] addOperationWithBlock:^{
					@synchronized(self) {
						[self willChangeValueForKey:@"lovedSongs"];
						[self setAssociatedValue:newLovedSongs forKey:@"cachedLovedSongs"];
						[self didChangeValueForKey:@"lovedSongs"];
						
						[[NSNotificationCenter defaultCenter] postNotificationName:ExfmSessionUpdatedCachedLovedSongsNotification object:self];
					}
				}];
                
                break;
			}
        }
	} otherwise:^(NSError *error) {
		NSLog(@"Could not fetch loved songs. Error: %@", error);
	} onQueue:[[self class] sessionRequestQueue]];
}

#pragma mark -

- (void)addSongResultToCache:(NSDictionary *)songResult
{
	NSParameterAssert(songResult);
	
	if(![self areCachedLovedSongsLoaded])
		[self loadCachedSongsFromUserDefaults];
	
	[[[self class] sessionRequestQueue] addOperationWithBlock:^{
		NSMutableArray *newLovedSongs = [self.cachedLovedSongs mutableCopy];
		[newLovedSongs insertObject:songResult atIndex:0];
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			@synchronized(self) {
				[self willChangeValueForKey:@"lovedSongs"];
				[self setAssociatedValue:newLovedSongs forKey:@"cachedLovedSongs"];
				[self didChangeValueForKey:@"lovedSongs"];
				
				[[NSNotificationCenter defaultCenter] postNotificationName:ExfmSessionUpdatedCachedLovedSongsNotification object:self];
			}
		}];
	}];
}

- (void)removeSongWithIDFromCache:(NSString *)identifier
{
	NSParameterAssert(identifier);
	
	if(![self areCachedLovedSongsLoaded])
		[self loadCachedSongsFromUserDefaults];
	
	[[[self class] sessionRequestQueue] addOperationWithBlock:^{
		NSArray *newLovedSongs = RKCollectionFilterToArray(self.cachedLovedSongs, ^BOOL(NSDictionary *songResult) {
			return ![RKFilterOutNSNull([songResult objectForKey:@"id"]) isEqualToString:identifier];
		});
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			@synchronized(self) {
				[self willChangeValueForKey:@"lovedSongs"];
				[self setAssociatedValue:newLovedSongs forKey:@"cachedLovedSongs"];
				[self didChangeValueForKey:@"lovedSongs"];
				
				[[NSNotificationCenter defaultCenter] postNotificationName:ExfmSessionUpdatedCachedLovedSongsNotification object:self];
			}
		}];
	}];
}

#pragma mark -

- (NSArray *)cachedLovedSongs
{
	@synchronized(self) {
		if(![self areCachedLovedSongsLoaded])
			[self loadCachedSongsFromUserDefaults];
		
		return [self associatedValueForKey:@"cachedLovedSongs"];
	}
}

- (void)setNumberOfNewFriendLoveActivities:(NSUInteger)numberOfNewLovedSongsOfFriends
{
    RKSetPersistentInteger(@"ExfmSession_numberOfNewLovedSongsOfFriends", numberOfNewLovedSongsOfFriends);
}

- (NSUInteger)numberOfNewFriendLoveActivities
{
    return RKGetPersistentInteger(@"ExfmSession_numberOfNewLovedSongsOfFriends");
}

- (NSArray *)cachedFriendLoveActivity
{
    NSData *archivedCachedLovedSongsOfFriends = RKGetPersistentObject(kCachedLoveFriendActivitiesUserDefaultsKey);
    return (archivedCachedLovedSongsOfFriends? [NSKeyedUnarchiver unarchiveObjectWithData:archivedCachedLovedSongsOfFriends] : @[]);
}

@end
