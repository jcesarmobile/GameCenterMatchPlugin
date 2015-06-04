(function(window) {
 
    var GameCenterMatchPlugin = function() {

        this.onSearchCancelled = null;
        this.receivedData = null;
        this.receivedTurn = null;
        this.matchEnded = null;
        this.playerDisconnected = null;
        this.playerConnected = null;
        this.connectionWithPlayerFailed = null;
        this.matchDidFailWithError = null;
 
 
    }
     
    GameCenter.prototype = {
 
        authenticate: function(success, fail) {
            cordova.exec(success, fail, "GameCenterMatchPlugin", "authenticateLocalPlayer", []);
        },
        startGame: function (success, fail, players) {
            cordova.exec( success, fail, "GameCenterMatchPlugin", "startGame", [players]);
        },
        endGame: function (success) {
            cordova.exec( success, null, "GameCenterMatchPlugin", "endGame", []);
        },
        getLocalPlayerId: function (success, fail) {
            cordova.exec( success, fail, "GameCenterMatchPlugin", "getLocalPlayerId", []);
        },
        getPlayers: function (success) {
            cordova.exec( success, null, "GameCenterMatchPlugin", "getPlayers", []);
        },
        sendGameData: function (success, fail, data) {
            cordova.exec( success, fail, "GameCenterMatchPlugin", "sendGameData", [data]);
        },
        _searchCancelled: function() {
            if (typeof this.onSearchCancelled === 'function') { this.onSearchCancelled(); }
        },
        _searchFailed: function() {
            if (typeof this.onSearchFailed === 'function') { this.onSearchFailed(); }
        },
        _receivedData: function (data) {
            if (typeof this.receivedData === 'function') { this.receivedData(data); }
        },
        _matchEnded: function () {
            if(typeof this.matchEnded === 'function') { this.matchEnded(); }
        },
        _playerDisconnected: function (player) {
            if(typeof this.playerDisconnected === 'function') { this.playerDisconnected(player); }
        },
        _playerConnected: function (player) {
            if(typeof this.playerConnected === 'function') { this.playerConnected(player); }
        },
        _connectionWithPlayerFailed: function (player,error) {
            if(typeof this.connectionWithPlayerFailed === 'function') { this.connectionWithPlayerFailed(player,error); }
        },
        _matchDidFailWithError: function (error) {
            if(typeof this.matchDidFailWithError === 'function') { this.matchDidFailWithError(error); }
        }
 
    };
 
    cordova.addConstructor(function() {
                           
        window.GameCenterMatchPlugin = new GameCenterMatchPlugin();
                           
    });
 
})(window);