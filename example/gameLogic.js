var maxPlayers = 2;
$(document).ready(function() {

    document.addEventListener("deviceready", onDeviceReady, false);
                  $("#start_button").hide();
                  $("#send_data").hide();
                  $("#end_game").hide();
                  $("#data").hide();
                  $("#start_button").click(openGameCenter);
                  $("#send_data").click(sendData);
                  $("#end_game").click(endGame);

});
 

function onDeviceReady() {
    
    
    
    window.gameCenter.authenticate( function() {
        
        window.gameCenter.startGame( startGameSuccess, nativePluginErrorHandler,maxPlayers);
                                   
    }, nativePluginErrorHandler);
    
    window.gameCenter.onSearchCancelled = function() {
        
        $("#start_button").show();
        $("#status").text("Search was Cancelled, Press Start button");
    
    }
    
    window.gameCenter.onSearchFailed = function() {
        
        $("#start_button").show();
        $("#status").text("Search Failed, Press Start button");
        
    }
    
    window.gameCenter.receivedData = function(data) {
        console.log(JSON.stringify(data));
        
    }
    
    window.gameCenter.matchEnded = function () {
        
        console.log('match ended');
        $("#status").text("Match Ended");
        $("#start_button").show();
        
    }
    
    window.gameCenter.playerDisconnected = function (player) {
        alert('player disconnected '+player);
    }
    window.gameCenter.playerConnected = function (player) {
        alert('player connected '+player);
    }
    
}

function nativePluginErrorHandler (error) {
    alert('error: '+error);
}


function openGameCenter(){

    window.gameCenter.startGame( startGameSuccess, nativePluginErrorHandler,maxPlayers);
    
}

function startGameSuccess(data){
    if(data.status=="started") {
        alert('game started');
        startNewGame();
        window.gameCenter.getPlayers(function(players){alert(JSON.stringify(players));});
    }
}
				

function startNewGame(){

	$("#start_button").hide();
    $("#send_data").show();
    $("#data").show();
    $("#end_game").show();

}

function sendData() {
    
    var dataToSend = {"data":$("#data").val()};
    window.gameCenter.sendGameData( function(result) {
                                       
                                       alert(result);
                                       }, nativePluginErrorHandler, dataToSend );
    
}

function endGame(){
    
    window.gameCenter.endGame(function(){
                              alert("game ended");
                              $("#start_button").show();
                              $("#send_data").hide();
                              $("#data").hide();
                              $("#end_game").hide();
                              });
    
}



