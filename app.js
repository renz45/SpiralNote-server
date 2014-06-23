require('coffee-script/register');
var http = require('http').Server(),
    io = require('socket.io')(http),
    _ = require('underscore'),
    clients = [],
    inputData = {},
    rpc = require('./app/rpc')

rpc.expose(require('./app/fsHelpers'));

var reBroadcast = function(eventName, socket, fn) {
  socket.on(eventName, function(data){
    if(data.uid){
      console.log(eventName + ":" + data.uid)
      socket.broadcast.emit(eventName + ":" + data.uid, addUserData(data, socket));
    }else{
      console.log(eventName)
      socket.broadcast.emit(eventName, addUserData(data, socket));
    }
    
    if(fn){
      fn(data)
    }
  });
}

io.on('connection', function(socket){
  socket.userInfo = {clientId: socket.id}

  // If there is no userName user the email instead
  var userData = JSON.parse(socket.handshake.query.user)
  socket.userInfo.userName = userData.userName || userData.email || "anon" + (clients.length + 1).toString()
  socket.userInfo.colorCode = '#'+Math.floor(Math.random()*16777215).toString(16);
  console.info('New client connected (id: ' + socket.id + ', userName: ' + socket.userInfo.userName + ').');

  clients.push(socket);
  socket.broadcast.emit('user:connect', {userInfo: socket.userInfo});
  
  rpc.listen(socket);
  
  socket.on('disconnect', function(){
    var index = clients.indexOf(socket);
    if (index != -1) {
      clients.splice(index, 1);
      console.info('Client disconnected (id: ' + socket.id + ', userName: ' + socket.userInfo.userName + ').');
    }
    socket.broadcast.emit('user:disconnect', {userInfo: socket.userInfo});
  });
});

http.listen(8282, function(){
  console.log('listening on *:8282');
});
