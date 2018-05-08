//
//  WeakTimerTarget.m
//  SplitCollage
//
//  Created by zidonj on 2017/3/16.
//  Copyright © 2017年 nbt. All rights reserved.
//

#import "WeakTimerTarget.h"
#import <objc/message.h>
@implementation WeakTimerTarget

+ (NSTimer *) scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                      target:(id)aTarget
                                    selector:(SEL)aSelector
                                    userInfo:(id)userInfo
                                     repeats:(BOOL)repeats{
    
    WeakTimerTarget * timer = [WeakTimerTarget new];
    timer.target = aTarget;
    timer.selector = aSelector;
    
    timer.timer = [NSTimer scheduledTimerWithTimeInterval:interval target:timer selector:@selector(fire:) userInfo:userInfo repeats:repeats];
    [[NSRunLoop currentRunLoop] addTimer:timer.timer forMode:NSRunLoopCommonModes];
    return timer.timer;
}

-(void)fire:(NSTimer *)timer{
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if (self.target) {
        ((void (*)(id, SEL, NSDictionary *)) objc_msgSend)(self.target, self.selector,timer.userInfo);
    } else {
        [self.timer invalidate];
    }
#pragma clang diagnostic pop
}


@end
