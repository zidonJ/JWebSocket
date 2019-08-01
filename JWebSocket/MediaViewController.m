//
//  MediaViewController.m
//  JWebSocket
//
//  Created by 姜泽东 on 2018/5/11.
//  Copyright © 2018年 MaiTian. All rights reserved.
//

#import "MediaViewController.h"
#import "H264HwEncoderImpl.h"

@import AVFoundation;

@interface MediaViewController ()<AVCapturePhotoCaptureDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,H264HwEncoderImplDelegate>
{
    
    CALayer *_customPreviewLayer;
    __weak IBOutlet UIImageView *_imgView;
    
    AVCaptureConnection *_connection;
    H264HwEncoderImpl *_264Ecoder;
}

@property (nonatomic,assign) BOOL isFlash;

@property (nonatomic,strong) AVCaptureSession *session;

/** iOS10_0*/
@property (nonatomic,strong) AVCaptureDeviceDiscoverySession *discoverySession;

@property (nonatomic,strong) AVCaptureInput *cinput;
/** 为’AVCaptureSession‘提供媒体数据与系统连接的设备的输入源*/
@property (nonatomic,strong) AVCaptureDeviceInput *input;
/** iOS10_0*/
@property (nonatomic,strong) AVCapturePhotoOutput *photoOutPut;
@property (nonatomic,strong) AVCaptureVideoDataOutput *videoOutPut;

@property (nonatomic,strong) AVCaptureDevice *device;

@property (nonatomic,strong) AVCaptureVideoPreviewLayer *videoCaptureLayer;

@property (nonatomic,strong) AVCapturePhotoSettings *settings;

@end

@implementation MediaViewController

#pragma mark -- super
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _264Ecoder = [H264HwEncoderImpl new];
    [_264Ecoder initWithConfiguration];
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [_264Ecoder initEncode:640 height:480];
//    });
    _264Ecoder.delegate = self;
    //输入
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    }
    //输出
    if ([self.session canAddOutput:self.photoOutPut]) {
        [self.session addOutput:self.photoOutPut];
    }
    
    [self.view.layer insertSublayer:self.videoCaptureLayer atIndex:0];
    
    AVCapturePhotoSettings *setting = [AVCapturePhotoSettings photoSettings];
    //闪光灯状态在此处设置
    if (self.isFlash) {
        setting.flashMode = AVCaptureFlashModeOn;
    }else{
        setting.flashMode = AVCaptureFlashModeOff;
    }
    
    if (@available(iOS 11.0, *)) {
        setting.livePhotoVideoCodecType = AVVideoCodecTypeH264;
    } else {
        
    }
    
    [self.photoOutPut capturePhotoWithSettings:setting delegate:self];
    
    
    self.videoOutPut.videoSettings =
    [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]
                                forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    
    [self.videoOutPut setAlwaysDiscardsLateVideoFrames:YES];
    
    [self.videoOutPut setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    [self.session startRunning];
    
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 350, 200, 30)];
    label.text = @"点击视频传输画面";
    [self.view addSubview:label];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"屏蔽上级界面的touch事件");
    //[self dismissViewControllerAnimated:YES completion:nil];
    if ([self.session canAddOutput:self.videoOutPut]) {
        [self.session addOutput:self.videoOutPut];
    }else{
        [self.session removeOutput:self.photoOutPut];
        [self.session addOutput:self.videoOutPut];
    }
    
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        self.session.sessionPreset = AVCaptureSessionPreset640x480;
    }
    
    AVCaptureConnection *videoConnection = [self.videoOutPut connectionWithMediaType:AVMediaTypeVideo];
    
    _connection = videoConnection;
    [self.session commitConfiguration];
    if (!videoConnection) {
        NSLog(@"录像错误");
    }
}

#pragma mark -- AVCapturePhotoCaptureDelegate

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void)captureOutput:(AVCapturePhotoOutput *)output
didFinishProcessingPhotoSampleBuffer:(nullable CMSampleBufferRef)photoSampleBuffer
previewPhotoSampleBuffer:(nullable CMSampleBufferRef)previewPhotoSampleBuffer
     resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
      bracketSettings:(nullable AVCaptureBracketedStillImageSettings *)bracketSettings
                error:(nullable NSError *)error/** iOS10*/ {
    
    NSData *imageData = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer
                                                                    previewPhotoSampleBuffer:previewPhotoSampleBuffer];
    
    UIImage *image = [UIImage imageWithData:imageData];
    
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}
#pragma clang diagnostic pop

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
}

/** NS_AVAILABLE_IOS(11.0) 去掉只支持iOS11的警告*/
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error NS_AVAILABLE_IOS(11.0) {
    NSData *data = [photo fileDataRepresentation];
    UIImage *image = [UIImage imageWithData:data];
    
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishRecordingLivePhotoMovieForEventualFileAtURL:(NSURL *)outputFileURL resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    
    
}

#pragma mark -- AVCaptureVideoDataOutputSampleBufferDelegate

- (CGImageRef) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer {
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);// Lock the image buffer
    
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);   // Get information of the image
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    CGContextRelease(newContext);
    
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    //CVBufferRelease(imageBuffer);// don't call this!
    
    return newImage;
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CGImageRef cgImage = [self imageFromSampleBuffer:sampleBuffer];
    UIImage *img = [UIImage imageWithCGImage:cgImage];
    _imgView.image = img;
    CGImageRelease( cgImage );
    
    [_264Ecoder encode:sampleBuffer];
    
//    CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBuffer);
//    size_t length = CMBlockBufferGetDataLength(blockBufferRef);
//    Byte buffer[length];
//    CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, buffer);
//    NSData *data = [NSData dataWithBytes:buffer length:length];
//    !_backData?:_backData(data);
    
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"录像le啦");
}

#pragma mark -- H264HwEncoderImplDelegate

- (void)gotSpsPps:(NSData *)sps pps:(NSData *)pps {
    dispatch_async(dispatch_get_main_queue(), ^{
        !_describeData?:_describeData(sps,pps);
    });
}

- (void)gotEncodedData:(NSData *)data isKeyFrame:(BOOL)isKeyFrame {
    dispatch_async(dispatch_get_main_queue(), ^{
       !_backData?:_backData(data);
    });
}

#pragma mark --getters

- (AVCaptureSession *)session {
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
    }
    return _session;
}

- (AVCaptureDevice *)device {
    if (!_device) {
        AVCaptureDeviceDiscoverySession *discoverySession =
        [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera]
                                                               mediaType:AVMediaTypeVideo
                                                                position:AVCaptureDevicePositionBack];
        
        if (discoverySession.devices.count > 0) {
            _device = discoverySession.devices.firstObject;
        }
    }
    return _device;
}

- (AVCaptureDeviceInput *)input {
    if (!_input) {
        NSError *error = nil;
        _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
        if (error) {
            NSLog(@"获取设备输入错误");
            return nil;
        }
    }
    return _input;
}

- (AVCapturePhotoOutput *)photoOutPut {
    if (!_photoOutPut) {
        _photoOutPut = [[AVCapturePhotoOutput alloc] init];
    }
    return _photoOutPut;
}

- (AVCaptureVideoPreviewLayer *)videoCaptureLayer {
    
    if (!_videoCaptureLayer) {
        _videoCaptureLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        _videoCaptureLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, 300);
        _videoCaptureLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _videoCaptureLayer;
}

- (AVCapturePhotoSettings *)settings {
    if (!_settings) {
        _settings = [AVCapturePhotoSettings photoSettings];
    }
    return _settings;
}

- (AVCaptureVideoDataOutput *)videoOutPut {
    if (!_videoOutPut) {
        _videoOutPut = [[AVCaptureVideoDataOutput alloc] init];
    }
    return _videoOutPut;
}

@end
