//
//  Created by @jcesarmobile.
//

#import <Cordova/CDV.h>
#import "GCHelper.h"


@interface GameCenterMatchPlugin : CDVPlugin <GCHelperDelegate>

@property (nonatomic) NSInteger maxPlayers;
@property (strong, nonatomic) CDVPluginResult * pluginResult;
@property (strong, nonatomic) CDVInvokedUrlCommand * command;

- (void)authenticateLocalPlayer:(CDVInvokedUrlCommand*)command;
- (void)startGame:(CDVInvokedUrlCommand*)command;
- (void)endGame:(CDVInvokedUrlCommand*)command;
- (void)getPlayers:(CDVInvokedUrlCommand*)command;
- (void)getLocalPlayerId:(CDVInvokedUrlCommand*)command;
- (void)sendGameData:(CDVInvokedUrlCommand*)command;


@end
