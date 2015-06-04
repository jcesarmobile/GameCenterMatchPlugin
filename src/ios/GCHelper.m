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
        
        [GKMatchmaker sharedMatchmaker].inviteHandler = ^(GKInvite *acceptedInvite, NSArray *playersToInvite) {
            
            NSLog(@"Received invite");
            self.pendingInvite = acceptedInvite;
            self.pendingPlayersToInvite = playersToInvite;
            [delegate inviteReceived];
            
        };
        
    } else if (![GKLocalPlayer localPlayer].isAuthenticated && userAuthenticated) {
        userAuthenticated = NO;
    }
    
}

- (void)lookupPlayers {
    
    NSLog(@"Looking up %d players...", match.playerIDs.count);
    [GKPlayer loadPlayersForIdentifiers:match.playerIDs withCompletionHandler:^(NSArray *players, NSError *error) {
        
        if (error != nil) {
            NSLog(@"Error retrieving player info: %@", error.localizedDescription);
            matchStarted = NO;
            [delegate matchEnded];
        } else {
            
            // Populate players dict
            self.playersDict = [NSMutableDictionary dictionaryWithCapacity:players.count];
            for (GKPlayer *player in players) {
                NSLog(@"Found player: %@", player.alias);
                [playersDict setObject:player forKey:player.playerID];
            }
            
            // Notify delegate match can begin
            matchStarted = YES;
            [delegate matchStarted];
            
        }
    }];
    
}

- (NSMutableDictionary *)getPlayers {
    return playersDict;
}

#pragma mark User functions

- (void)authenticateLocalUserWithBlock:(void (^)(NSError *err))block {
    
    if (!gameCenterAvailable) return;
    
    NSLog(@"Authenticating local user...");
    if ([GKLocalPlayer localPlayer].authenticated == NO) {
        [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:block];
    } else {
        NSLog(@"Already authenticated!");
    }
}


- (void)findMatchWithMinPlayers:(int)minPlayers maxPlayers:(int)maxPlayers viewController:(UIViewController *)viewController delegate:(id<GCHelperDelegate>)theDelegate {
    
    if (!gameCenterAvailable) return;

    minGamePlayers = minPlayers;
    maxGamePlayers = maxPlayers;
    
    matchStarted = NO;
    self.match = nil;
    delegate = theDelegate;
    self.presentingViewController = viewController;
    if (pendingInvite != nil) {
        
        
        
        
        GKMatchmakerViewController *mmvc = [[[GKMatchmakerViewController alloc] initWithInvite:pendingInvite] autorelease];
        
        mmvc.matchmakerDelegate = self;
        [presentingViewController presentModalViewController:mmvc animated:YES];
        
        self.pendingInvite = nil;
        self.pendingPlayersToInvite = nil;
        
    } else {
        
        
        GKMatchRequest *request = [[GKMatchRequest alloc] init];

        request.minPlayers = minPlayers;
        request.maxPlayers = maxPlayers;
        
        request.playersToInvite = pendingPlayersToInvite;
        
        GKMatchmakerViewController *mmvc = [[[GKMatchmakerViewController alloc] initWithMatchRequest:request] autorelease];
        mmvc.matchmakerDelegate = self;
        
        [presentingViewController presentModalViewController:mmvc animated:YES];
        
        self.pendingInvite = nil;
        self.pendingPlayersToInvite = nil;
        
    }
    
}
-(void)showInviteVC {
    
    if (!gameCenterAvailable) return;
    matchStarted = NO;
    self.match = nil;
  
    if (pendingInvite != nil) { 
        
        GKMatchmakerViewController *mmvc = [[[GKMatchmakerViewController alloc] initWithInvite:pendingInvite] autorelease];
        mmvc.matchmakerDelegate = self;
        [presentingViewController presentModalViewController:mmvc animated:YES];
        
        self.pendingInvite = nil;
        self.pendingPlayersToInvite = nil;
        
    }
    
}

#pragma mark GKMatchmakerViewControllerDelegate

// The user has cancelled matchmaking
- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController {
    [delegate searchCancelled];
    [presentingViewController dismissModalViewControllerAnimated:YES];
}

// Matchmaking has failed with an error
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error {
    [delegate searchFailed];
    [presentingViewController dismissModalViewControllerAnimated:YES];
    
}

// A peer-to-peer match has been found, the game should start
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)theMatch {
    [presentingViewController dismissModalViewControllerAnimated:YES];
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

@end
