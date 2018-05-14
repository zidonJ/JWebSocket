//
//  MediaViewController.h
//  JWebSocket
//
//  Created by 姜泽东 on 2018/5/11.
//  Copyright © 2018年 MaiTian. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^BackMediaData)(NSData *data);
typedef void(^BackDescribeData)(NSData *sps,NSData *pps);
typedef void(^BackMedisImage)(UIImage *data);

@interface MediaViewController : UIViewController

@property (nonatomic,copy) BackMedisImage backStream;
@property (nonatomic,copy) BackMediaData backData;
@property (nonatomic,copy) BackDescribeData describeData;

@end
