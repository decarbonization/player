//
//  RKMockURLRequestPromiseCacheManager.h
//  RoundaboutKitTests
//
//  Created by Kevin MacWhinnie on 5/6/13.
//
//

#import <Foundation/Foundation.h>

///The key that corresponds to a mock cache manager item's revision.
///
///Ignored if `kRKMockURLRequestPromiseCacheManagerItemErrorKey` is provided.
RK_EXTERN NSString *const kRKMockURLRequestPromiseCacheManagerItemRevisionKey;

///The key that corresponds to a mock cache manager item's data.
///
///Ignored if `kRKMockURLRequestPromiseCacheManagerItemErrorKey` is provided.
RK_EXTERN NSString *const kRKMockURLRequestPromiseCacheManagerItemDataKey;

///The key that corresponds to a mock cache manager item's associated error.
///
///If this item-key is provided, reading and writing the item's identifier
///will yield the error value provided by the item-key.
///
/// \seealso(-[RKMockURLRequestPromiseCacheManager setError:forIdentifier:])
RK_EXTERN NSString *const kRKMockURLRequestPromiseCacheManagerItemErrorKey;


///The RKMockURLRequestPromiseCacheManager class encapsulates an in-memory cache manager
///that includes a mechanism to allow for deterministic cache failure for testing.
///
///The RKMockURLRequestPromiseCacheManager class uses a single lock around all operations
///unlike the built in default `RKURLRequestPromiseCacheManager` implementation, which uses
///complex synchronization around all of its operations for the best possible performance.
@interface RKMockURLRequestPromiseCacheManager : NSObject <RKURLRequestPromiseCacheManager>

///Initialize the receiver with a given dictionary of items.
///
/// \param  items   A dictionary of items whose keys correspond to cache identifiers,
///                 and whose values correspond to dictionaries with item keys specified.
///                 This parameter is optional.
///
/// \result A fully initialized mock cache manager.
///
///This method must be used to prepopulate a cache manager without changing its
///`.wasCalledFromMainThread` property and giving a false positive about threading.
///
/// \seealso(kRKMockURLRequestPromiseCacheManagerItemRevisionKey,
///          kRKMockURLRequestPromiseCacheManagerItemDataKey,
///          kRKMockURLRequestPromiseCacheManagerItemErrorKey)
- (id)initWithItems:(NSDictionary *)items;

#pragma mark - Deterministic Failure

///Set an error to be reported when a given identifier is read or written to.
///
/// \param  error       The error to report. Required.
/// \param  identifier  The identifier to associate the error with. Required.
///
///The same error will be reported on both reads and writes.
- (void)setError:(NSError *)error forIdentifier:(NSString *)identifier;

#pragma mark - Properties

///Indicates whether or not the cache manager was called from the main thread.
///
///This property will set to YES if any of the methods in
///`<RKURLRequestPromiseCacheManager>` were called on the main thread.
///
///This property is to test the assumption that `RKURLRequestPromise` never
///invokes the cache manager from anything other than its worker queue.
///
///This property *is not* affected by `-[self setError:forIdentifier:]`.
@property (readonly) BOOL wasCalledFromMainThread;

///Whether or not the method was called.
@property (readonly) BOOL revisionForIdentifierWasCalled;

///Whether or not the method was called.
@property (readonly) BOOL cacheDataForIdentifierWithRevisionErrorWasCalled;

///Whether or not the method was called.
@property (readonly) BOOL cachedDataForIdentifierErrorWasCalled;

///Whether or not the method was called.
@property (readonly) BOOL removeCacheForIdentifierErrorWasCalled;

@end
