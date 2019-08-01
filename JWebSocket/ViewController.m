//
//  ViewController.m
//  JWebSocket
//
//  Created by 姜泽东 on 2018/5/7.
//  Copyright © 2018年 MaiTian. All rights reserved.
//

#import "ViewController.h"
#import "JSRManager.h"
#import "MediaViewController.h"
#import "H264HwDecoderImpl.h"
#import "AAPLEAGLLayer.h"

@interface ViewController ()<JSRManagerDelegate,H264HwDecoderImplDelegate>
{
    __weak IBOutlet UILabel *_messageLabel;
    __weak IBOutlet UITextField *_content;
    __weak IBOutlet UITextField *_loginId;
    __weak IBOutlet UITextField *_sendToId;
    __weak IBOutlet UIImageView *_imgView;
    H264HwDecoderImpl *_264Decoder;
    AAPLEAGLLayer *_player;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [JSRManager sharedInstance].delegate = self;
    _264Decoder = [H264HwDecoderImpl new];
    _264Decoder.delegate = self;
    [_264Decoder initH264Decoder];
    
    
    _player = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(0, 50, 100, 100)];
    _player.backgroundColor = [UIColor blackColor].CGColor;
    
    [self.view.layer addSublayer:_player];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [[JSRManager sharedInstance] openWithUrlString:@"ws://10.0.15.22:8181/"];
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
        
        if ([message[kMsgType] isEqualToString:JSRSendImg]) {
            _imgView.image = [UIImage imageWithData:data];
        }else if([message[kMsgType] isEqualToString:JSRSendVideo]){
            const char bytes[] = "\x00\x00\x00\x01";
            size_t length = (sizeof bytes) - 1;
            NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
            NSMutableData *h264Data = [[NSMutableData alloc] init];
            [h264Data appendData:ByteHeader];
            [h264Data appendData:data];
            [_264Decoder decodeNalu:(uint8_t *)[h264Data bytes] withSize:(uint32_t)h264Data.length];
        }else if ([message[kMsgType] isEqualToString:JSRSendMsg]) {
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
                                               kMsgType:JSRSendImg}];
    _content.text = @"";
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    MediaViewController *medvc = segue.destinationViewController;
//    medvc.view.backgroundColor = [UIColor redColor];
    MT_WSELF
    medvc.backStream = ^(UIImage *data) {
        MT_SSELF_NIL_RETURN
        NSString *imageString =
        [UIImageJPEGRepresentation(data, 1) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        [[JSRManager sharedInstance] sendMessage:@{@"content":imageString,
                                                   @"to":self->_sendToId.text,
                                                   kMsgType:JSRSendImg}];
        self->_content.text = @"";
    };
    
    medvc.backData = ^(NSData *data) {
        MT_SSELF_NIL_RETURN
        NSString *videoString = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        [[JSRManager sharedInstance] sendMessage:@{@"content":videoString,
                                                   @"to":self->_sendToId.text,
                                                   kMsgType:JSRSendVideo}];
        self->_content.text = @"";
    };
    
    medvc.describeData = ^(NSData *sps, NSData *pps) {
        NSString *videoString = [sps base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        [[JSRManager sharedInstance] sendMessage:@{@"content":videoString,
                                                   @"to":self->_sendToId.text,
                                                   kMsgType:JSRSendVideo}];
        
        NSString *videoString1 = [pps base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        [[JSRManager sharedInstance] sendMessage:@{@"content":videoString1,
                                                   @"to":self->_sendToId.text,
                                                   kMsgType:JSRSendVideo}];
        self->_content.text = @"";
    };
    
}

- (void)displayDecodedFrame:(CVImageBufferRef)imageBuffer
{
    if(imageBuffer) {
        _player.pixelBuffer = imageBuffer;
        CVPixelBufferRelease(imageBuffer);
    }
}

@end
