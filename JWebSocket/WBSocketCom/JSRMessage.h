//
//  JSRMessage.h
//  JWebSocket
//
//  Created by 姜泽东 on 2018/5/9.
//  Copyright © 2018年 MaiTian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, JSRMessageType) {
    StringType,
    DataType,
    ImageTpe
};

@interface JSRMessage : NSObject

@property (nonatomic,assign) JSRMessageType msgType;
@property (nonatomic,copy) NSString *sendToId;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) UIImage *image;
@property (nonatomic, assign) BOOL incoming;

@end
