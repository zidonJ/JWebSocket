//
//  JSRMessage.h
//  JWebSocket
//
//  Created by 姜泽东 on 2018/5/9.
//  Copyright © 2018年 MaiTian. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JSRMessage : NSObject

- (instancetype)initWithMessage:(NSString *)message incoming:(BOOL)incoming;

@property (nonatomic,copy) NSString *receiverId;
@property (nonatomic,copy) NSString *senderId;
@property (nonatomic, copy, readonly) NSString *message;
@property (nonatomic, assign, readonly, getter=isIncoming) BOOL incoming;

@end
