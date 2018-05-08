//
//  ViewController.m
//  JWebSocket
//
//  Created by 姜泽东 on 2018/5/7.
//  Copyright © 2018年 MaiTian. All rights reserved.
//

#import "ViewController.h"
#import "JSRManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [[JSRManager sharedInstance] openWithUrlString:@"http://192.168.85.107:8081/"];
}


@end
