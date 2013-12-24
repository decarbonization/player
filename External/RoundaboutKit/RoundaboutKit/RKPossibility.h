//
//  RKPossibility.h
//  RoundaboutKit
//
//  Created by Kevin MacWhinnie on 12/20/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#ifndef RKPossibility_h
#define RKPossibility_h 1

#import <Foundation/Foundation.h>
#import "RKPrelude.h"

///The different types of contents an RKPossibility can contain.
typedef enum RKPossibilityState : NSUInteger {
    
    ///The possibility contains nothing.
    kRKPossibilityStateEmpty = 0,
    
    ///The possibility contains a value.
    kRKPossibilityStateValue = 1,
    
    ///The possibility contains an error.
    kRKPossibilityStateError = 2,
    
} RKPossibilityState;

///The RKPossibility class represents the possible outcomes of a given promise.
///
///The `.state` property should always be used to determine the contents of a possibility.
@interface RKPossibility : NSObject

///Initialize the receiver with a specified value.
- (id)initWithValue:(id)value;

///Initialize the receiver with a specified error.
- (id)initWithError:(NSError *)error;

///Initialize the receiver with nothing.
- (id)initEmpty;

///Synonym of `-[RKPossibility initEmpty]`.
- (id)init;

#pragma mark - Properties

///The possible value.
@property (readonly) id value;

///The possible error.
@property (readonly) NSError *error;

///The contents of the possibility.
@property (readonly) RKPossibilityState state;

#pragma mark - Refining

///Returns a new version of receiver by passing its value through a `value` refiner block.
///
/// \param  refiner The refiner block. Required.
///
/// \result A new possibility or the receiver if it did not contain a value.
- (RKPossibility *)refineValue:(RKPossibility *(^)(id value))refiner;

///Returns a new version of receiver by passing its error through a `error` refiner block.
///
/// \param  refiner The refiner block. Required.
///
/// \result A new possibility or the receiver if it did not contain an error.
- (RKPossibility *)refineError:(RKPossibility *(^)(NSError *error))refiner;

///Returns a new version of receiver by passing it through a `empty` refiner block.
///
/// \param  refiner The refiner block. Required.
///
/// \result A new possibility or the receiver if it was not empty.
- (RKPossibility *)refineEmpty:(RKPossibility *(^)())refiner;

#pragma mark - Matching

///Invokes a given block with the value of the
///receiver if it has one, does nothing otherwise.
///
/// \param  matcher The matching block to invoke.
///
- (void)whenValue:(void(^)(id value))matcher;

///Invokes a given block with the error of the
///receiver if it has one, does nothing otherwise.
///
/// \param  matcher The matching block to invoke.
///
- (void)whenError:(void(^)(NSError *error))matcher;

///Invokes a given block if the receiver is empty,
///does nothing otherwise.
///
/// \param  matcher The matching block to invoke.
///
- (void)whenEmpty:(void(^)())matcher;

@end

#if RoundaboutKit_EnableLegacyPossibilityFunctions

#pragma mark - Default Matchers/Refiners

///The default value possibility refiner.
RK_EXTERN RKPossibility *(^kRKPossibilityDefaultValueRefiner)(id);

///The default empty possibility refiner.
RK_EXTERN RKPossibility *(^kRKPossibilityDefaultEmptyRefiner)();

///The default error possibility refiner.
RK_EXTERN RKPossibility *(^kRKPossibilityDefaultErrorRefiner)(NSError *);

#pragma mark -

///The default value possibility matcher.
RK_EXTERN void(^kRKPossibilityDefaultValueMatcher)(id);

///The default empty possibility matcher.
RK_EXTERN void(^kRKPossibilityDefaultEmptyMatcher)();

///The default error possibility matcher.
RK_EXTERN void(^kRKPossibilityDefaultErrorMatcher)(NSError *);

#pragma mark - Refining and Matching

///Refine a possibility by passing its contents through a refiner block.
///
/// \param  possibility     The possibility to refine. Optional.
/// \param  valueRefiner    The block to invoke when the possibility is a `value`. Optional.
/// \param  emptyRefiner    The block to invoke when the possibility is `empty`. Optional.
/// \param  errorRefiner    The block to invoke when the possibility is an `error`. Optional.
///
/// \result A new possibility whose contents have been passed through a refiner.
///
///function RefinePossibility(possibility) = match(possibility) {
/// id(value) -> return valueRefiner(value);
/// Empty -> return emptyRefiner();
/// NSError(value) -> return errorRefiner(error);
///}
RK_EXTERN_OVERLOADABLE RKPossibility *RKRefinePossibility(RKPossibility *possibility,
                                                          RKPossibility *(^valueRefiner)(id value),
                                                          RKPossibility *(^emptyRefiner)(),
                                                          RKPossibility *(^errorRefiner)(NSError *error));

///Match a possibility's contents against `value` and `error` blocks.
///
/// \param  possibility The possibility to match. Optional.
/// \param  value       The block to invoke when the possibility is a `value`. Optional.
/// \param  empty       The block to invoke when the possibility is `empty`. Optional.
/// \param  error       The block to invoke when the possibility is an `error`. Optional.
///
///function RefinePossibility(possibility) = match(possibility) {
/// id(value) -> value(value);
/// Empty -> empty();
/// NSError(value) -> error(error);
///}
RK_EXTERN_OVERLOADABLE void RKMatchPossibility(RKPossibility *possibility,
                                               void(^value)(id value),
                                               void(^empty)(),
                                               void(^error)(NSError *error));

#endif /* RoundaboutKit_EnableLegacyPossibilityFunctions */

#endif /* RKPossibility_h */
