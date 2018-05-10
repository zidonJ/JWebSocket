//创建websocketServer
var WebSocketServer = require('ws').Server,

wss = new WebSocketServer({ port: 8081 });

var HashMap = require('hashmap');
//连接池
var userConnectionMap = new HashMap();
var connectNum = 0;


wss.on('connection', function (ws) {
    ++ connectNum;
    console.log('A client has connected. current connect num is : ' + connectNum);

    var objMessage;
    //收到消息回调
    ws.on('message', function (message) {

        console.log(message);
        objMessage = JSON.parse(message);
        var strType  = objMessage['type'];
        //objMessage['chatId'] 发送者的唯一表示 chatId是约定好的字段
        console.log('json序列化'+objMessage['chatId']);
        switch(strType) {
            case 'login' : 
                userConnectionMap.set(objMessage['chatId'], ws);
                break;
            default:
                var ws_send = userConnectionMap.get(objMessage['to']);
                if (ws_send) {
                    console.log('向客户端发送了消息');
                    ws_send.send(message);
                }
        }
        

    });

    // 退出聊天  
    ws.on('close', function(close) {  
        
        console.log('退出连接了',userConnectionMap);
        if (objMessage == null) {
            userConnectionMap.remove(objMessage['chatId']);
            -- connectNum;
        }
        
    }); 

    ws.on('error',error); 
});

function error(err){
    //处理错误
    console.log('报错了');  
}

console.log('开始监听8081端口');

// var WebSocketServer = require('websocket').server;
// var http = require('nodejs-websocket');
 
// var server = http.createServer(function(request, response) {
//     console.log((new Date()) + ' Received request for ' + request.url);
//     // response.writeHead(404);
//     // response.end();
// });
// server.listen(8081, function() {
//     console.log((new Date()) + ' Server is listening on port 8081');
// });
 
// wsServer = new WebSocketServer({
//     httpServer: server,
//     // You should not use autoAcceptConnections for production
//     // applications, as it defeats all standard cross-origin protection
//     // facilities built into the protocol and the browser.  You should
//     // *always* verify the connection's origin and decide whether or not
//     // to accept it.
//     autoAcceptConnections: false
// });
 
// function originIsAllowed(origin) {
//   // put logic here to detect whether the specified origin is allowed.
//   return true;
// }
 
// wsServer.on('request', function(request) {
//     if (!originIsAllowed(request.origin)) {
//       // Make sure we only accept requests from an allowed origin
//       request.reject();
//       console.log((new Date()) + ' Connection from origin ' + request.origin + ' rejected.');
//       return;
//     }
    
//     var connection = request.accept('ws:', request.origin);
//     console.log((new Date()) + ' Connection accepted.');
//     connection.on('message', function(message) {
//         if (message.type === 'utf8') {
//             console.log('Received Message: ' + message.utf8Data);
//             connection.sendUTF(message.utf8Data);

//         }
//         else if (message.type === 'binary') {
//             console.log('Received Binary Message of ' + message.binaryData.length + ' bytes');
//             connection.sendBytes(message.binaryData);
            
//         }
//     });
//     connection.on('close', function(reasonCode, description) {
//         console.log((new Date()) + ' Peer ' + connection.remoteAddress + ' disconnected.');
//     });
// });

// var http = require('nodejs-websocket');

// var data = {key:'value',hello:'hello'};

// var srv = http.createServer(function(req,res){

//     //res.writeHead(200,{'Content-type':'application/json'});

//     //res.end(JSON.stringify(data));

// });

// srv.listen(8081,function(){

// console.log('listening on localhost:8081');

// });


// var app = require('express')();

// var http = require('http').Server(app);

// var io = require('socket.io')(http);

// app.get('/', function(req, res){res.send(

// 'Welcome Realtime Server'

// );});

// http.listen(8081, function(){console.log('listening on *:8081');});