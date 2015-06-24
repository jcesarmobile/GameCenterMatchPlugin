Game Center Match Plugin
========================

This plugin makes possible to play real time matches using Game Center

Two years ago I created the Game Center Online plugin (https://github.com/jcesarmobile/GameCenterOnlinePlugin) because I wanted to add online game to my phonegap game, Othello Classic (http://goo.gl/hCJjC) 
If you want to see the plugin in action or want to support the game and/or the plugin please download the game.

Some days ago I started updating that plugin because it was very limited and was built to fit my needs, but it was very hard to use in other games other than board games. Furthermore, cordova and Game Center changed a lot in this 2 years too, the first version was built for iOS 6 and cordova 2, so there were a lot of changes to be made, so in the end, I've created this new plugin installable with the cordova CLI

Why? Because with this plugin you can add real time online game without a server, so it has 0 cost to you and no server programming involved.

Installation:
============

From npm
cordova plugin add game-center-match-plugin

From github
cordova plugin add https://github.com/jcesarmobile/GameCenterMatchPlugin.git


Usage:
=====


Available functions:
=====
Authenticate player:
```
window.GameCenterMatchPlugin.authenticate( success, error );
```


Start game:

```
window.GameCenterMatchPlugin.startGame( success, error, minPlayers, maxPlayers);
```
minPlayers: int for the minimum number of players, it can't be smaller than 2
maxPlayers: int for the maximun number of players, it can't be greater than 4

End game:

```
window.GameCenterMatchPlugin.endGame(success);
```

Get players:

```
window.GameCenterMatchPlugin.getPlayers(success);
```
on the success callback you get a JSON object with the players

Send data:
```
window.GameCenterMatchPlugin.sendGameData( success, error, dataToSend );
```
dataToSend: is a JSON object

Events you have to listen:
=========================

onSearchCancelled: Called when you cancel the game search
```
window.GameCenterMatchPlugin.onSearchCancelled = function() {}
```

onSearchFailed: Called when the search don't find other players
```
 window.GameCenterMatchPlugin.onSearchFailed = function() {}
```

receivedData: Called when you receive data from other players
```
 window.GameCenterMatchPlugin.receivedData = function(data) {}
```
data contains the data sent and the id of the player who sent the data

matchEnded: Called when the match end
```
window.GameCenterMatchPlugin.matchEnded = function () {}
```

playerDisconnected: Called when another player is disconnected
```
window.GameCenterMatchPlugin.playerDisconnected = function (player) {}  
```
player is the id of the player that disconnected 
   
playerConnected: Called when a player is connected   
```
window.GameCenterMatchPlugin.playerConnected = function (player) {}
```   
player is the id of the player that connected    
    
   

See the example folder for a simple example of use that sends words from an input
    





