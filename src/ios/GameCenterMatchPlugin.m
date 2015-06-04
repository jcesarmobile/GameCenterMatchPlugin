//
//  Created by @jcesarmobile.
//

#import "GameCenterMatchPlugin.h"

@implementation GameCenterMatchPlugin


- (void)authenticateLocalPlayer:(CDVInvokedUrlCommand*)command {
   
    [[GCHelper sharedInstance] authenticateLocalUserWithBlock:^(NSError *error) {
        if (error == nil)
        {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
        else
        {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }];
}

- (void)startGame:(CDVInvokedUrlCommand*)command {
    
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    NSInteger maxAllowed = 4;
    if ([request respondsToSelector:@selector(maxPlayersAllowedForMatchOfType:)]) {
        maxAllowed = [GKMatchRequest maxPlayersAllowedForMatchOfType:GKMatchTypePeerToPeer];
    }
    request = nil;
    
    self.maxPlayers = [[command.arguments objectAtIndex:0]integerValue];
    if(self.maxPlayers>maxAllowed) {
       [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"max players is %d",maxAllowed]] callbackId:command.callbackId];
    } else {
        self.command = command;
        [self initGameWithMaxPlayers:self.maxPlayers];
        self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"status" : @"init"}];
        [self.pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:self.pluginResult callbackId:command.callbackId];
    }
    
    
}

-(void)endGame:(CDVInvokedUrlCommand *)command {
    [[GCHelper sharedInstance].match disconnect];
    [GCHelper sharedInstance].match = nil;
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

- (void)getPlayers:(CDVInvokedUrlCommand*)command {
    
    NSMutableArray * playersArray = [[NSMutableArray alloc]init];
    NSString *aKey;
    NSEnumerator *keyEnumerator = [[[GCHelper sharedInstance] getPlayers] keyEnumerator];
    while (aKey = [keyEnumerator nextObject])
        
    {
        GKPlayer * player = [[[GCHelper sharedInstance] getPlayers] objectForKey:aKey];
        NSDictionary * playerDict = @{@"alias":player.alias,@"displayName":player.displayName,@"playerID":player.playerID};
        [playersArray addObject:playerDict];
        
    }
    
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:[playersArray copy]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

- (void)getLocalPlayerId:(CDVInvokedUrlCommand*)command {
    
    CDVPluginResult* pluginResult = nil;
    GKPlayer * localPlayer = [GKLocalPlayer localPlayer];
    if ([GKLocalPlayer localPlayer].authenticated) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:localPlayer.playerID];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

- (void)sendGameData:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    NSDictionary * dataDict = [command.arguments objectAtIndex:0];
    
    
    if (![dataDict isEqual:[NSNull null]]) {

        NSError * error;
        NSData *data =  [NSJSONSerialization dataWithJSONObject:dataDict
                                                        options:NSJSONWritingPrettyPrinted
                                                          error:&error];
        if (!data) {
            
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"Failed with error: %@", error]];
            
        } else {
            
            BOOL success = [[GCHelper sharedInstance].match sendDataToAllPlayers:data withDataMode:GKMatchSendDataReliable error:&error];
            
            if (!success) {
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"Failed with error: %@", error]];
                
            } else {
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"sent"];
                
            }
            
        }

        
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no data to send"];
    }
     
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}



-(void)initGameWithMaxPlayers:(int)players {
    
    [[GCHelper sharedInstance] findMatchWithMinPlayers:2 maxPlayers:players viewController:self.viewController delegate:self];
    
}

#pragma mark GCHelperDelegate

- (void)matchStarted {
    
    self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"status" : @"started"}];
    [self.pluginResult setKeepCallbackAsBool:NO];
    [self.commandDelegate sendPluginResult:self.pluginResult callbackId:self.command.callbackId];
    self.command = nil;
    self.pluginResult = nil;
    
}

- (void)matchEnded {
    
    [[GCHelper sharedInstance].match disconnect];
    [GCHelper sharedInstance].match = nil;
    NSString * javascriptString = @"window.GameCenterMatchPlugin._matchEnded();";
    [self.webView stringByEvaluatingJavaScriptFromString:javascriptString];
    
}

-(void)playerDisconnected:(NSString *)playerID {
    NSLog(@"player disconnected");
    NSString * javascriptString = [NSString stringWithFormat:@"window.GameCenterMatchPlugin._playerDisconnected('%@');",playerID];
    [self.webView stringByEvaluatingJavaScriptFromString:javascriptString];
}

-(void)playerConnected:(NSString *)playerID {
    NSLog(@"player connected");
    NSString * javascriptString = [NSString stringWithFormat:@"window.GameCenterMatchPlugin._playerConnected('%@');",playerID];
    [self.webView stringByEvaluatingJavaScriptFromString:javascriptString];
}

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID {
    
    NSError * error;
    NSDictionary *dictFromData = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:NSJSONReadingAllowFragments
                                                                   error:&error];
    NSMutableDictionary * receivedData = [[NSMutableDictionary alloc]initWithDictionary:dictFromData];
    [receivedData setValue:playerID forKey:@"playerID"];
    NSLog(@"received data %@",receivedData);
    NSString * javascriptString = [NSString stringWithFormat:@"window.GameCenterMatchPlugin._receivedData(%@);",[receivedData JSONString]];
    [self.webView stringByEvaluatingJavaScriptFromString:javascriptString];
    
    
}

-(void)inviteReceived {
    
    [self initGameWithMaxPlayers:self.maxPlayers];
    
}

-(void)searchCancelled {
    
    NSString * javascriptString = @"window.GameCenterMatchPlugin._searchCancelled();";
    [self.webView stringByEvaluatingJavaScriptFromString:javascriptString];

}

-(void)searchFailed {
    
    NSString * javascriptString = @"window.GameCenterMatchPlugin._searchFailed();";
    [self.webView stringByEvaluatingJavaScriptFromString:javascriptString];
    
}

-(void)connectionWithPlayerFailed:(NSString *)playerID withError:(NSError *)error {
    NSString * javascriptString = [NSString stringWithFormat:@"window.GameCenterMatchPlugin._connectionWithPlayerFailed('%@','%@');",playerID,error.localizedDescription];
    [self.webView stringByEvaluatingJavaScriptFromString:javascriptString];

}

-(void)matchDidFailWithError:(NSError *)error {
    
    NSString * javascriptString = [NSString stringWithFormat:@"window.GameCenterMatchPlugin._matchDidFailWithError('%@');",error.localizedDescription];
    [self.webView stringByEvaluatingJavaScriptFromString:javascriptString];
}

@end
