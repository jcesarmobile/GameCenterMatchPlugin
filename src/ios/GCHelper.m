//
//  Created by @jcesarmobile
//

#import "GCHelper.h"

@implementation GCHelper

@synthesize gameCenterAvailable;
@synthesize presentingViewController;
@synthesize match;
@synthesize delegate;
@synthesize playersDict;
@synthesize pendingInvite;
@synthesize pendingPlayersToInvite;

#pragma mark Initialization

static GCHelper *sharedHelper = nil;
+ (GCHelper *) sharedInstance {
    
    if (!sharedHelper) {
        
        sharedHelper = [[GCHelper alloc] init];
        
    }
    
    return sharedHelper;
}

- (BOOL)isGameCenterAvailable {
    
    // check for presence of GKLocalPlayer API
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
    
    // check if the device is running iOS 4.1 or later
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer
                                           options:NSNumericSearch] != NSOrderedAscending);
    
    return (gcClass && osVersionSupported);
    
}

- (id)init {
    
    if ((self = [super init])) {
        
        gameCenterAvailable = [self isGameCenterAvailable];
        
        if (gameCenterAvailable) {
            
            NSNotificationCenter *nc =
            [NSNotificationCenter defaultCenter];
            [nc addObserver:self
                   selector:@selector(authenticationChanged)
                       name:GKPlayerAuthenticationDidChangeNotificationName
                     object:nil];
            
        }
        
    }
    
    return self;
    
}

#pragma mark Internal functions

- (void)authenticationChanged {
    
    if ([GKLocalPlayer localPlayer].isAuthenticated && !userAuthenticated) {
        userAuthenticated = YES;
        
        __weak GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
        if ([localPlayer respondsToSelector:@selector(registerListener:)]) {
            
            [localPlayer registerListener:self];
            
        } else {
            
            [GKMatchmaker sharedMatchmaker].inviteHandler = ^(GKInvite *acceptedInvite, NSArray *playersToInvite) {
                
                self.pendingInvite = acceptedInvite;
                self.pendingPlayersToInvite = playersToInvite;
                [self findMatchWithInvite];
                
            };
            
        }
        
    } else if (![GKLocalPlayer localPlayer].isAuthenticated && userAuthenticated) {
        
        userAuthenticated = NO;
        __weak GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
        if ([localPlayer respondsToSelector:@selector(unregisterListener:)]) {
            
            [localPlayer unregisterListener:self];
        }
        
    }
    
}

- (void)lookupPlayers {
    
    [GKPlayer loadPlayersForIdentifiers:match.playerIDs withCompletionHandler:^(NSArray *players, NSError *error) {
        
        if (error != nil) {
            
            matchStarted = NO;
            [delegate matchEnded];
            
        } else {
            
            self.playersDict = [NSMutableDictionary dictionaryWithCapacity:players.count];
            
            for (GKPlayer *player in players) {
                
                [playersDict setObject:player forKey:player.playerID];
                
            }
            
            matchStarted = YES;
            [delegate matchStarted];
            
        }
        
    }];
    
}

- (NSMutableDictionary *)getPlayers {
    
    return playersDict;
    
}

#pragma mark User functions

- (void)authenticateLocalUserWithViewController:(UIViewController *)viewController
                                       delegate:(id<GCHelperDelegate>)theDelegate andBlock:(void (^)(NSError *err))block {
    
    if (!gameCenterAvailable) return;
    
    delegate = theDelegate;
    presentingViewController = viewController;
    
    if ([GKLocalPlayer localPlayer].authenticated == NO) {
        
        [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:block];
        
    }
    
}

- (void)findMatchWithMinPlayers:(int)minPlayers maxPlayers:(int)maxPlayers {
    
    if (!gameCenterAvailable) return;
    
    minGamePlayers = minPlayers;
    maxGamePlayers = maxPlayers;
    matchStarted = NO;
    self.match = nil;
    
    
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    
    request.minPlayers = minPlayers;
    request.maxPlayers = maxPlayers;
    
    request.playersToInvite = pendingPlayersToInvite;
    
    GKMatchmakerViewController * mmvc = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
    
    
    
    mmvc.matchmakerDelegate = self;
    
    self.pendingInvite = nil;
    self.pendingPlayersToInvite = nil;
    [presentingViewController presentViewController:mmvc animated:YES completion:nil];
    
}

- (void)findMatchWithInvite {
    
    if (!gameCenterAvailable) return;
    
    matchStarted = NO;
    self.match = nil;
    GKMatchmakerViewController * mmvc = [[GKMatchmakerViewController alloc] initWithInvite:pendingInvite];
    
    mmvc.matchmakerDelegate = self;
    
    self.pendingInvite = nil;
    self.pendingPlayersToInvite = nil;
    [presentingViewController presentViewController:mmvc animated:YES completion:nil];
    
}



#pragma mark GKMatchmakerViewControllerDelegate

// The user has cancelled matchmaking
- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController {
    
    [delegate searchCancelled];
    [presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
}

// Matchmaking has failed with an error
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error {
    
    [delegate searchFailed];
    [presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
}

// A peer-to-peer match has been found, the game should start
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)theMatch {
    
    [presentingViewController dismissViewControllerAnimated:YES completion:nil];
    self.match = theMatch;
    match.delegate = self;
    
    if (!matchStarted && match.expectedPlayerCount == 0) {
        
        [self lookupPlayers];
        
    }
    
}

#pragma mark GKMatchDelegate

// The match received data sent from the player.
- (void)match:(GKMatch *)theMatch didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID {
    
    if (match != theMatch) return;
    
    [delegate match:theMatch didReceiveData:data fromPlayer:playerID];
    
}

-(void)match:(GKMatch *)theMatch player:(GKPlayer *)player didChangeConnectionState:(GKPlayerConnectionState)state {
    
    NSString * playerID = player.playerID;
    [self handleMatch:theMatch player:playerID didChangeState:state];
    
}

- (void)handleMatch:(GKMatch *)theMatch  player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state {
    
    if (match != theMatch) return;
    
    switch (state) {
            
        case GKPlayerStateConnected:
            
            if (!matchStarted && theMatch.expectedPlayerCount == 0) {
                
                [self lookupPlayers];
                
            }
            
            [delegate playerConnected:playerID];
            break;
            
        case GKPlayerStateDisconnected:
            [self.playersDict removeObjectForKey:playerID];
            [delegate playerDisconnected:playerID];
            break;
            
    }
    
}

// The player state changed (eg. connected or disconnected)
- (void)match:(GKMatch *)theMatch player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state {
    
    [self handleMatch:theMatch player:playerID didChangeState:state];
    
}

// The match was unable to connect with the player due to an error.
- (void)match:(GKMatch *)theMatch connectionWithPlayerFailed:(NSString *)playerID withError:(NSError *)error {
    
    if (match != theMatch) return;
    
    [delegate connectionWithPlayerFailed:playerID withError:error];
    
}

// The match was unable to be established with any players due to an error.
- (void)match:(GKMatch *)theMatch didFailWithError:(NSError *)error {
    
    if (match != theMatch) return;
    
    [delegate matchDidFailWithError:error];
    
}

-(BOOL)match:(GKMatch *)match shouldReinviteDisconnectedPlayer:(GKPlayer *)player {
    
    return YES;
    
}

-(BOOL)match:(GKMatch *)match shouldReinvitePlayer:(NSString *)playerID {
    
    return YES;
    
}

#pragma mark GKInviteEventListener

-(void)player:(GKPlayer *)player didAcceptInvite:(GKInvite *)invite {
    
    pendingInvite = invite;
    [self findMatchWithInvite];
    
}

-(void)player:(GKPlayer *)player didRequestMatchWithPlayers:(NSArray *)playerIDsToInvite {
    
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = 2;
    request.maxPlayers = [playerIDsToInvite count];
    request.playersToInvite = playerIDsToInvite;
    
    GKMatchmakerViewController *mmvc = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
    mmvc.matchmakerDelegate = self;
    [presentingViewController presentViewController:mmvc animated:YES completion:nil];
    
}

@end
