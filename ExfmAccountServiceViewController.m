//
//  ExfmServiceViewController.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/8/13.
//
//

#import "ExfmAccountServiceViewController.h"

#import "ExfmSession.h"

@interface ExfmAccountServiceViewController ()

@end

@implementation ExfmAccountServiceViewController

- (RKPromise *)loginPromiseForUsername:(NSString *)username password:(NSString *)password
{
    RKPromise *promise = [RKPromise new];
    [[RKQueueManager commonQueue] addOperationWithBlock:^{
        ExfmSession *session = [ExfmSession defaultSession];
        
        NSError *error = nil;
        id userIsValid = [[session verifyUsername:username password:password] await:&error];
        if(userIsValid) {
            session.username = username;
            session.password = password;
            
            [promise accept:userIsValid];
        } else {
            [promise reject:error];
        }
    }];
    
    return promise;
}

- (RKPromise *)signUpPromiseForEmail:(NSString *)email username:(NSString *)username password:(NSString *)password
{
    RKPromise *promise = [RKPromise new];
    [[RKQueueManager commonQueue] addOperationWithBlock:^{
        ExfmSession *session = [ExfmSession defaultSession];
        
        NSError *error = nil;
        id userIsValid = [[session createUserWithName:username password:password email:email] await:&error];
        if(userIsValid) {
            session.username = username;
            session.password = password;
            
            [promise accept:userIsValid];
        } else {
            [promise reject:error];
        }
    }];
    
    return promise;
}

#pragma mark -

- (IBAction)forgotPassword:(id)sender
{
    
}

@end
