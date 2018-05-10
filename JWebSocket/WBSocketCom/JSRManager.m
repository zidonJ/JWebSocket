//
//  JSRManager.m
//  JWebSocket
//
//  Created by 姜泽东 on 2018/5/7.
//  Copyright © 2018年 MaiTian. All rights reserved.
//

#import "JSRManager.h"
#import <SocketRocket.h>
#import "WeakTimerTarget.h"
#import "JSRMessage.h"

#define dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}

NSString * const JSRLogin = @"login";
NSString * const JSRSendMsg = @"JSRSendMsg";

@interface JSRManager()<SRWebSocketDelegate>

{
    NSTimer * _heartBeat;
    NSTimeInterval _reConnectTimes;
}
@property (nonatomic,strong) SRWebSocket *socket;
@property (nonatomic,copy) NSString *urlString;

@end

@implementation JSRManager

+ (instancetype)sharedInstance
{
    static JSRManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [JSRManager new];
    });
    return manager;
}

#pragma mark -- public func
//建立连接
- (void)openWithUrlString:(NSString *)url
{
    if (self.socket) return;
    self.urlString = url;
    self.socket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    
    NSLog(@"请求的websocket地址：%@",self.socket.url.absoluteString);
    
    self.socket.delegate = self;//SRWebSocketDelegate 协议
    [self.socket open];//开始连接
}

- (void)loginWithUserId:(NSDictionary *)userInfo
{
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:userInfo options:NSJSONWritingPrettyPrinted error:&error];
    if (data && error == nil) {
        [self sendData:data];
    }
}

//发送消息
- (void)sendMessage:(id)msg
{
    if (![msg isKindOfClass:[NSString class]]) {
        NSError *error;
        NSData *data = [NSJSONSerialization dataWithJSONObject:msg options:NSJSONWritingPrettyPrinted error:&error];
        if (data && error == nil) {
            [self sendData:data];
        }
    }else{
        [self sendData:msg];
    }
    
}

#pragma mark -- private func
//重新连接
- (void)reConnect
{
    [self srWebSocketClose];
    
    //超过一分钟就不再重连 所以只会重连5次 2^5 = 64
    if (_reConnectTimes > 64) {
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_reConnectTimes * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.socket = nil;
        [self openWithUrlString:self.urlString];
        NSLog(@"重连");
    });
    
    //重连时间2的指数级增长
    if (_reConnectTimes == 0) {
        _reConnectTimes = 2;
    }else{
        _reConnectTimes *= 2;
    }
}
//关闭
-(void)srWebSocketClose{
    if (self.socket){
        [self.socket close];
        self.socket = nil;
        //断开连接时销毁心跳
        [self destoryHeartBeat];
    }
}
//ping
- (void)ping{
    if (self.socket.readyState == SR_OPEN) {
        [self.socket sendPing:nil];
    }
}
//初始化心跳
- (void)initHeartBeat
{
    dispatch_main_async_safe( ^{
        [self destoryHeartBeat];
        //心跳设置为3分钟,NAT超时一般为5分钟
        self->_heartBeat = [NSTimer timerWithTimeInterval:3
                                                   target:self
                                                 selector:@selector(sentHeart)
                                                 userInfo:nil
                                                  repeats:YES];
        //和服务端约定好发送什么作为心跳标识,尽可能的减小心跳包大小
        [[NSRunLoop currentRunLoop] addTimer:self->_heartBeat forMode:NSRunLoopCommonModes];
    });
}
//销毁心跳
- (void)destoryHeartBeat
{
    dispatch_main_async_safe(^{
        
        if (self->_heartBeat) {
            if ([self->_heartBeat respondsToSelector:@selector(isValid)]){
                if ([self->_heartBeat isValid]){
                    [self->_heartBeat invalidate];
                    self->_heartBeat = nil;
                }
            }
        }
    });
}

- (void)sendData:(id)data {
    
    //NSLog(@"发送的消息内容:%@",data);
    
    dispatch_queue_t queue =  dispatch_queue_create("jsr", DISPATCH_QUEUE_CONCURRENT);
    MT_WSELF
    dispatch_async(queue, ^{
        
        MT_SSELF_NIL_RETURN
        if (self.socket != nil) {
            // 只有 SR_OPEN 开启状态才能调 send 方法啊,不然要崩
            if (self.socket.readyState == SR_OPEN) {
                [self.socket send:data];    // 发送数据
                
            } else if (self.socket.readyState == SR_CONNECTING) {
                NSLog(@"正在连接中,重连后其他方法会去自动同步数据");
                // 每隔2秒检测一次 socket.readyState 状态,检测 10 次左右
                // 只要有一次状态是 SR_OPEN 的就调用 [ws.socket send:data] 发送数据
                // 如果 10 次都还是没连上的,那这个发送请求就丢失了,这种情况是服务器的问题了,小概率的
                // 代码有点长,我就写个逻辑在这里好了
                [self reConnect];
                
            } else if (self.socket.readyState == SR_CLOSING || self.socket.readyState == SR_CLOSED) {
                // websocket 断开了,调用 reConnect 方法重连
                
                NSLog(@"重连");
                
                [self reConnect];
            }
        } else {
            NSLog(@"没网络,发送失败,一旦断网 socket 会被我设置 nil 的");
            NSLog(@"其实最好是发送前判断一下网络状态比较好,我写的有点晦涩,socket==nil来表示断网");
        }
    });
}

-(void)sentHeart
{
//    NSDictionary *dic = @{@"chatId":@"111",@"content":@"这是一段经典的旋律",@"type":@"receive"};
//    NSError *error;
//    NSData *message = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
//    if (message && error == nil) {
//        [self sendData:message];
//    }
}

#pragma mark -- SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    //每次正常连接的时候清零重连时间
    _reConnectTimes = 0;
    //开启心跳
    [self initHeartBeat];
    if (webSocket == self.socket) {
        NSLog(@"************************** socket 连接成功************************** ");
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    
    if (webSocket == self.socket) {
        NSLog(@"************************** socket 连接失败************************** ");
        _socket = nil;
        //连接失败就重连
        [self reConnect];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    if (webSocket == self.socket) {
        NSLog(@"************************** socket连接断开************************** ");
        NSLog(@"被关闭连接,code:%ld,reason:%@,wasClean:%d",(long)code,reason,wasClean);
        [self srWebSocketClose];
    }
}

/*该函数是接收服务器发送的pong消息,其中最后一个是接受pong消息的,
 在这里就要提一下心跳包,一般情况下建立长连接都会建立一个心跳包,
 用于每隔一段时间通知一次服务端,客户端还是在线,这个心跳包其实就是一个ping消息,
 我的理解就是建立一个定时器,每隔十秒或者十五秒向服务端发送一个ping消息,这个消息可是是空的
 */
-(void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload
{
    NSString *reply = [[NSString alloc] initWithData:pongPayload encoding:NSUTF8StringEncoding];
    NSLog(@"reply===%@",reply);
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message  {
    
    if (webSocket == self.socket) {
        NSLog(@"收到约定的message是json格式数据收到数据");
        
        if ([message isKindOfClass:[NSData class]]) {
            NSError *error;
            NSData *data = (NSData *)message;
            id value = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            if (!error) {
                NSLog(@"jsonValue:%@",value);
                [self.delegate didReceiveMessage:value];
            }            
        }else{
            NSLog(@"message:%@",message);
            [self.delegate didReceiveMessage:message];
        }
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessageWithString:(nonnull NSString *)string
{
    NSLog(@"Received \"%@\"", string);
    //[self _addMessage:[[JSRMessage alloc] initWithMessage:string incoming:YES]];
}

@end
