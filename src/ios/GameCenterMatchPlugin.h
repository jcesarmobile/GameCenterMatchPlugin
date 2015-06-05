//
//  Created by @jcesarmobile.
//

#import <Cordova/CDV.h>
#import "GCHelper.h"


@interface GameCenterMatchPlugin : CDVPlugin <GCHelperDelegate>

@property (nonatomic) int maxPlayers;
@property (nonatomic) int minPlayers;
@property (strong, nonatomic) CDVPluginResult * pluginResult;
@property (strong, nonatomic) CDVInvokedUrlCommand * command;

- (void)authenticateLocalPlayer:(CDVInvokedUrlCommand*)command;
- (void)startGame:(CDVInvokedUrlCommand*)command;
- (void)endGame:(CDVInvokedUrlCommand*)command;
- (void)getPlayers:(CDVInvokedUrlCommand*)command;
- (void)getLocalPlayerId:(CDVInvokedUrlCommand*)command;
- (void)sendGameData:(CDVInvokedUrlCommand*)command;


@end
