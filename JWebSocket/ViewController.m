//
//  ViewController.m
//  JWebSocket
//
//  Created by 姜泽东 on 2018/5/7.
//  Copyright © 2018年 MaiTian. All rights reserved.
//

#import "ViewController.h"
#import "JSRManager.h"

@interface ViewController ()<JSRManagerDelegate>
{
    __weak IBOutlet UILabel *_messageLabel;
    __weak IBOutlet UITextField *_content;
    __weak IBOutlet UITextField *_loginId;
    __weak IBOutlet UITextField *_sendToId;
    __weak IBOutlet UIImageView *_imgView;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [JSRManager sharedInstance].delegate = self;
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [[JSRManager sharedInstance] openWithUrlString:@"ws://192.168.85.107:8081/"];
    [self.view endEditing:YES];
}

- (void)didReceiveMessage:(id)message
{
    if ([message isKindOfClass:[NSString class]]) {
        _messageLabel.text = [_messageLabel.text stringByAppendingFormat:@"\n%@",message];
    }else{
        id content = message[@"content"];
        NSData *data = [[NSData alloc] initWithBase64EncodedString:content
                                                           options:NSDataBase64DecodingIgnoreUnknownCharacters];
        if (data.length) {
            _imgView.image = [UIImage imageWithData:data];
        }else{
            _messageLabel.text = [_messageLabel.text stringByAppendingFormat:@"\n%@",message[@"content"]];
        }
    }
}

- (IBAction)loginChat:(UIButton *)sender
{
    [[JSRManager sharedInstance] loginWithUserId:@{@"chatId":_loginId.text,kMsgType:JSRLogin}];
}

- (IBAction)sendingMsg:(UIButton *)sender
{
    [[JSRManager sharedInstance] sendMessage:@{@"content":_content.text,@"to":_sendToId.text,kMsgType:JSRSendMsg}];
    _content.text = @"";
}

- (IBAction)sendImage:(UIButton *)sender
{
    UIImage *image = [UIImage imageNamed:@"22.jpg"];
    NSString *imageString =
    [UIImageJPEGRepresentation(image, 1) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    [[JSRManager sharedInstance] sendMessage:@{@"content":imageString,
                                               @"to":_sendToId.text,
                                               kMsgType:JSRSendMsg}];
    _content.text = @"";
}

@end
