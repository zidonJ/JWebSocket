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
