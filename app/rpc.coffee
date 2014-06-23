# A simple remote procedures implmentation used for calling functions on the server
# over a socket connection using socket.io. Function must be exposed to the rpc
# before they can be called remotely. Example usage:
# 
# // SERVER
# var http = require('http').Server(),
#     io = require('socket.io')(http),
#     rpc = require('./app/rpc') 
# 
# rpc.expose({
#   function1: function(){
#     //...
#   },
#   function2: function(){
#     //...
#   }
# });
# 
# io.on('connection', function(socket){
#   rpc.listen(socket);
# });
# 
# http.listen(8282, function(){
#   console.log('listening on *:8282');
# });
# 
# //CLIENT
# # socket is a normal socket.io connection object. the object sent with the `function:call`
# # event must be structured with:
# #   function - function name
# #   functionArgs - arguments to pass to the function
# #   id - a unique id used in the return event so we don't get a bunch of listeners
# #   firing for function returns
# var funcId = 0
# var callRemoteFunction = function (socket, fName, args) {
#   // $q is a promise library, any promise library should work
#   var deferred = $q.defer();
#   socket.emit("rpc:function:call", {function: fName, functionArgs: args, id: funcId});
# 
#   // socket.once is required, so that the listener is cleared after the function return
#   socket.once("rpc:" + fName + ":result:" + funcId, function(result) {
#     deferred.resolve(result);
#   });
# 
#   return deferred.promise;
# }
# 
# // Then you would use the callRemoteFunction:
# callRemoteFunction(socket, 'function1', 'some args').then(function(data){
#   var result = data.result;
# });

_ = require('underscore')
exposedFunctions = {}

module.exports =
  expose: (funcObj)->
    exposedFunctions = _.extend(exposedFunctions, funcObj)
    
  listen: (socket)->
    socket.on 'rpc:function:call', (data)->
      funcId = data.id
      args = data.functionArgs
      functionName = data.function
      resultObj = 
        functionName: functionName
        functionArgs: args
        id: funcId

      if exposedFunctions[functionName]
        try
          resultObj.result = exposedFunctions[functionName](args)
        catch e
          resultObj.error = e.message
      else
        resultObj.error = "Function #{functionName} not found in exposed functions"
      
      if resultObj.result && resultObj.result.then && resultObj.result.fail
        resultObj.result.then (result)->
          resultObj.result = result
          socket.emit "rpc:#{functionName}:result:#{funcId}", resultObj
        .catch (error)->
          delete resultObj.result
          resultObj.error = error
          socket.emit "rpc:#{functionName}:result:#{funcId}", resultObj
      else
        socket.emit "rpc:#{functionName}:result:#{funcId}", resultObj
          
          
    
