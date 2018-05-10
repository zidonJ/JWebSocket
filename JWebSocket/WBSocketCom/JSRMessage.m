//
//  JSRMessage.m
//  JWebSocket
//
//  Created by 姜泽东 on 2018/5/9.
//  Copyright © 2018年 MaiTian. All rights reserved.
//

#import "JSRMessage.h"

@implementation JSRMessage

- (instancetype)initWithMessage:(NSString *)message incoming:(BOOL)incoming
{
    self = [super init];
    if (!self) return self;
    
    _incoming = incoming;
    _message = message;
    
    return self;
}


@end
