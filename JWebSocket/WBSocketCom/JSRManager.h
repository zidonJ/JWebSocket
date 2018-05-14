//
//  JSRManager.h
//  JWebSocket
//
//  Created by 姜泽东 on 2018/5/7.
//  Copyright © 2018年 MaiTian. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreMedia;

#define MT_WSELF __weak __typeof__(self) _weakSelf = self;
#define MT_SSELF __strong __typeof__(self) self = _weakSelf;
#define MT_SSELF_NIL_RETURN MT_SSELF;if (!self) {return ;}

static NSString * const kMsgType = @"type";
static NSString * const kUrlSringKey = @"urlstring";

typedef NSString * NSMessageTypeString;

extern NSMessageTypeString const JSRLogin;
extern NSMessageTypeString const JSRSendMsg;
extern NSMessageTypeString const JSRSendImg;
extern NSMessageTypeString const JSRSendVideo;


@protocol JSRManagerDelegate;

@interface JSRManager : NSObject

+ (instancetype)sharedInstance;

- (void)openWithUrlString:(NSString *)url;
- (void)sendMessage:(id)msg;

- (void)loginWithUserId:(NSDictionary *)userInfo;

@property (nonatomic,weak) id <JSRManagerDelegate> delegate;


- (void)sendWithEncodeSampleBuffer:(NSData *)data;

@end

@protocol JSRManagerDelegate<NSObject>

- (void)didReceiveMessage:(id)message;

@end
