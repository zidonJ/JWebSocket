//
//  JSRManager.h
//  JWebSocket
//
//  Created by 姜泽东 on 2018/5/7.
//  Copyright © 2018年 MaiTian. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MT_WSELF __weak __typeof__(self) _weakSelf = self;
#define MT_SSELF __strong __typeof__(self) self = _weakSelf;
#define MT_SSELF_NIL_RETURN MT_SSELF;if (!self) {return ;}

@interface JSRManager : NSObject

+ (instancetype)sharedInstance;

- (void)openWithUrlString:(NSString *)url;

@end
