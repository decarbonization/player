//
//  RKPromise.h
//  RoundaboutKit
//
//  Created by Kevin MacWhinnie on 6/13/13.
//  Copyright (c) 2013 Roundabout Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

///The different states a promise can be in.
typedef NS_ENUM(NSUInteger, RKPromiseState) {
    ///The promise is not yet realized.
    RKPromiseStateNotRealized = 0,
    
    ///The promise has been realized with a value.
    RKPromiseStateValue,
    
    ///The promise has been realized with an error.
    RKPromiseStateError,
};

///A then continuation block.
typedef void(^RKPromiseThenBlock)(id);

///An error continuation block.
typedef void(^RKPromiseErrorBlock)(NSError *error);

#pragma mark -

///The RKPromise class encapsulates the common promise pattern.
@interface RKPromise : NSObject

#pragma mark - Convenience

///Returns a new promise object that has an accepted value.
+ (instancetype)acceptedPromiseWithValue:(id)value;

///Returns a new promise object that has a rejected error.
+ (instancetype)rejectedPromiseWithError:(NSError *)error;

#pragma mark - Plural

///Realizes an array of promises, placing the results into the returned promise.
///
/// \param  promises    The promises to realize. Required.
///
/// \result A promise that will contain an array of RKPossibility
///         objects in the same order as the promises passed in.
///
+ (RKPromise *)when:(NSArray *)promises;

#pragma mark - State

///The name of the promise. Defaults to <anonymous>
@property (copy) NSString *promiseName;

///The cache identifier to use.
///
///Default value is nil.
@property (copy) NSString *cacheIdentifier;

///The state of the promise.
///
/// \seealso(RKPromiseState)
@property (readonly) RKPromiseState state;

#pragma mark - Propagating Values

///Mark the promise as successful and associate a value with it,
///invoking any `then` block currently associated with it.
///
/// \param  value   The success value to propagate. May be nil.
///
///This method or `-[self reject:]` may only be called once.
- (void)accept:(id)value;

///Mark the promise as failed and associate an error with it,
///invoking any `otherwise` block currently associated with it.
///
/// \param  error   The failure value to propagate. May be nil.
///
///This method or `-[self accept:]` may only be called once.
- (void)reject:(NSError *)error;

#pragma mark - Realizing

///Overriden by subclasses that wish to perform work based on the promise being realized.
///
///The default implementation of this method does nothing.
///
///This method is only called if the promise has not already been realized.
- (void)fire;

#pragma mark -

///Associate a success block and a failure block with the promise.
///
/// \param  then        The block to invoke upon success. Required.
/// \param  otherwise   The block to invoke upon failure. Required.
///
///The blocks passed in will be invoked on the caller's operation queue.
///
/// \seealso(-[self then:otherwise:onQueue:])
- (void)then:(RKPromiseThenBlock)then otherwise:(RKPromiseErrorBlock)otherwise;

///Associate a success block and a failure block with the promise.
///
/// \param  then        The block to invoke upon success. Required.
/// \param  otherwise   The block to invoke upon failure. Required.
/// \param  queue       The queue to invoke the blocks on. Required.
///
/// \seealso(-[self then:otherwise:onQueue:])
- (void)then:(RKPromiseThenBlock)then otherwise:(RKPromiseErrorBlock)otherwise onQueue:(NSOperationQueue *)queue;

#pragma mark -

///Update a given key path on a given object when the receiver is accepted or rejected.
///
/// \param  keyPath     The key path to update on the object. Required.
/// \param  object      The object to update. Required.
/// \param  placeholder The placeholder object to use while waiting for realization.
///                     If nil is specified for this parameter, the key path on object
///                     will consequentially be set to nil.
///
///This is the preferred method for quick updates on an object. This method will
///manage multiple promises being realized on a single view at the same time.
- (void)updateKeyPath:(NSString *)keyPath forObject:(id)object withPlaceholder:(id)placeholder;

#pragma mark -

///Synchronously waits for the receiver to contain a value.
///
/// \param  outError    On return, pointer that contains an error object
///                     describing any issues. Parameter may be ommitted.
///
/// \result The result of realizing the promise.
///
- (id)await:(NSError **)outError;

@end

#if RoundaboutKit_EnableLegacyRealization

#pragma mark - Singular Realization

///Realize a promise.
///
///	\param	promise			The promise to realize. Optional.
///	\param	success			The block to invoke if the promise is successfully realized. Optional.
///	\param	failure			The block to invoke if the promise cannot be realized. Optional.
///	\param	callbackQueue	The queue to invoke the callback blocks on. This parameter may be ommitted.
///
///This function will asynchronously invoke the `promise`, and subsequently
///invoke either the `success`, or `failure` on the queue that invoked this
///function initially.
///
///If promise is nil, then this function does nothing.
RK_INLINE RK_OVERLOADABLE void RKRealize(RKPromise *promise,
							   RKPromiseThenBlock success,
							   RKPromiseErrorBlock failure,
							   NSOperationQueue *callbackQueue)
{
	if(!promise)
		return;
	
	[promise then:success otherwise:failure onQueue:callbackQueue];
}

RK_INLINE RK_OVERLOADABLE void RKRealize(RKPromise *promise,
                                         RKPromiseThenBlock success,
                                         RKPromiseErrorBlock failure)
{
	RKRealize(promise, success, failure, [NSOperationQueue currentQueue]);
}

#endif /* RoundaboutKit_EnableLegacyRealization */
