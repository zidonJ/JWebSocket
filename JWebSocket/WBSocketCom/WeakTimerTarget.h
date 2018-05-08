//
//  WeakTimerTarget.h
//  SplitCollage
//
//  Created by zidonj on 2017/3/16.
//  Copyright © 2017年 nbt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WeakTimerTarget : NSObject

@property (nonatomic, assign) SEL selector;
@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic, weak) id target;

+ (NSTimer *) scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                      target:(id)aTarget
                                    selector:(SEL)aSelector
                                    userInfo:(id)userInfo
                                     repeats:(BOOL)repeats;

@end
