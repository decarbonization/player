//
//  Service.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/4/13.
//
//

#import <Foundation/Foundation.h>

@class RKPromise;
@class Song;
@class Account;

///The Service protocol encapsulates the methods common to all services in the Pinna application.
///
///Services are managed through the ServiceDescriptor and AccountManager classes. Services have
///accounts associated with them. The lifecycle of an Account is user defined.
///
/// \seealso(ServiceDescriptor, AccountManager)
@protocol Service <NSObject>

#pragma mark - Session Management

///Returns a promise to re-log-into a service with a given account.
///
/// \param  account The account to relogin with. Required.
///
/// \result A promise that will yield the receiver upon success.
///
///This method is called by Pinna during its launch process to give services an
///opportunity to configure themselves and get ready for use in the current session.
- (RKPromise *)reloginWithAccount:(Account *)account;

///Returns a promise to log out of a service.
///
/// \result A promise that will yield the receiver upon success.
///
///This promise will be realized as part of the process of logging out of a service in Pinna.
- (RKPromise *)logout;

#pragma mark - Scrobbling

///Returns a promise to update the now playing status of the receiver's user.
///
///	\param	song        The song to update the now playing status to. Required.
/// \param  duration    The duration of the song. Required.
///                     This is provided as a separate parameter for the iOS app.
///
///This method will only be called on services with known valid accounts when there is an active internet connection.
- (RKPromise *)updateNowPlayingWithSong:(Song *)song duration:(NSTimeInterval)duration;

///Returns a promise to scrobble a song in the receiver's user's profile.
///
///	\param	song        The song to scrobble. Required.
/// \param  duration    The duration of the song. Required.
///                     This is provided as a separate parameter for the iOS app.
///
///This method will only be called on services with known valid accounts when there is an active internet connection.
- (RKPromise *)scrobbleSong:(Song *)song duration:(NSTimeInterval)duration;

@end
