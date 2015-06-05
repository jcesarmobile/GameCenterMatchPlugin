//
//  Created by @jcesarmobile.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@protocol GCHelperDelegate
- (void)matchStarted;
- (void)matchEnded;
- (void)playerDisconnected:(NSString *)playerID;
- (void)playerConnected:(NSString *)playerID;
- (void)match:(GKMatch *)match didReceiveData:(NSData *)data
   fromPlayer:(NSString *)playerID;
- (void)inviteReceived;
-(void)searchCancelled;
-(void)searchFailed;
-(void)connectionWithPlayerFailed:(NSString *)playerID withError:(NSError *)error;
-(void)matchDidFailWithError:(NSError *)error;
@end

@interface GCHelper : NSObject <GKMatchmakerViewControllerDelegate, GKMatchDelegate> {
    
    BOOL gameCenterAvailable;
    BOOL userAuthenticated;
    UIViewController *presentingViewController;
    GKMatch *match;
    BOOL matchStarted;
    NSMutableDictionary *playersDict;
    GKInvite *pendingInvite;
    NSArray *pendingPlayersToInvite;
    NSInteger minGamePlayers;
    NSInteger maxGamePlayers;
    
}

@property (assign, readonly) BOOL gameCenterAvailable;
@property (retain) UIViewController *presentingViewController;
@property (retain) GKMatch *match;
@property (assign) id <GCHelperDelegate> delegate;
@property (retain) NSMutableDictionary *playersDict;
@property (retain) GKInvite *pendingInvite;
@property (retain) NSArray *pendingPlayersToInvite;

- (void)findMatchWithMinPlayers:(int)minPlayers maxPlayers:(int)maxPlayers
                 viewController:(UIViewController *)viewController
                       delegate:(id<GCHelperDelegate>)theDelegate;
- (NSDictionary *)getPlayers;

+ (GCHelper *)sharedInstance;
- (void)authenticateLocalUserWithBlock:(void (^)(NSError *err))block;

-(void)showInviteVC;

@end
