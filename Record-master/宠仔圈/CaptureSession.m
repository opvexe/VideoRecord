//
//  CaptureSession.m
//  宠仔圈
//
//  Created by jieku on 2017/5/16.
//  Copyright © 2017年 TSM. All rights reserved.
//

#import "CaptureSession.h"
#import "EncoderAAC.h"
#import "EncodeH264.h"

@interface CaptureSession ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic ,strong) AVCaptureSession *session; //管理对象

@property (nonatomic ,strong) AVCaptureDevice *videoDevice; //设备
@property (nonatomic ,strong) AVCaptureDevice *audioDevice;

@property (nonatomic ,strong) AVCaptureDeviceInput *videoInput;//输入对象
@property (nonatomic ,strong) AVCaptureDeviceInput *audioInput;

@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;//输出对象
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;

@property (nonatomic, strong) AVCaptureConnection *VideoConnection;//视频流
@property (nonatomic, strong) AVCaptureConnection  *AudioConnection;//音频流

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preViewLayer;
@property (nonatomic, assign)AVCaptureDevicePosition CameraPositon;//摄像头位置

@property (nonatomic, assign) CaptureSessionPreset definePreset;
@property (nonatomic, strong) NSString *realPreset;

@property (nonatomic, strong)EncoderAAC *aac;  //编码  ios >8.0 AudioToolbox
@property (nonatomic, strong)EncodeH264 *h264;

@end
@implementation CaptureSession
{
    CGFloat  pintchZoom;//缩放
    dispatch_queue_t CaptureQueue;
    dispatch_queue_t EncodeQueue;
}

- (instancetype)initWithFrame:(CGRect)frame  CaptureWithSessionPreset:(CaptureSessionPreset)preset CameraPositon:(AVCaptureDevicePosition)CameraPositon
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        _CameraPositon = CameraPositon;
        [self initAVcaptureSession];
        _definePreset = preset;
        
        //初始化音频编码
        _aac = [[EncoderAAC alloc] init];
        //初始化视频编码
        _h264 = [[EncodeH264 alloc] init];
        
        //创建视频解码会话
        [_h264 createEncodeSession:480 height:640 fps:25 bite:640*1000];
        
    }
    return self;
}

//初始化AVCaptureSession
- (void)initAVcaptureSession {
#pragma mark 视频设置
    _session = [[AVCaptureSession alloc] init];
    // 设置录像分辨率
    if (![self.session canSetSessionPreset:self.realPreset]) {
        if (![self.session canSetSessionPreset:AVCaptureSessionPresetiFrame960x540]) {
            if (![self.session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
            }
        }
    }
    
    //开始配置
    [_session beginConfiguration];
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //获取视频设备对象
    for(AVCaptureDevice *device in devices) {
        if (device.position == _CameraPositon) {
            self.videoDevice = device;//前置摄像头or后置摄像头
            
        }
    }
    //初始化视频捕获输入对象
    NSError *error;
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.videoDevice error:&error];
    if (error) {
        NSLog(@"摄像头错误");
        return;
    }
    //输入对象添加到Session
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    //输出对象
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    //是否卡顿时丢帧
    self.videoOutput.alwaysDiscardsLateVideoFrames = NO;
    // 设置像素格式
    [self.videoOutput setVideoSettings:@{
                                         (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
                                         }];
    //将输出对象添加到队列、并设置代理
    dispatch_queue_t captureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    [self.videoOutput setSampleBufferDelegate:self queue:captureQueue];
    
    // 判断session 是否可添加视频输出对象
    if ([self.session canAddOutput:self.videoOutput]) {
        [self.session addOutput:self.videoOutput];
        // 链接视频 I/O 对象
    }
    //创建连接  AVCaptureConnection输入对像和捕获输出对象之间建立连接。
    self.VideoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    //视频的方向
     self.VideoConnection .videoOrientation = AVCaptureVideoOrientationPortrait;
    //设置稳定性，判断connection连接对象是否支持视频稳定
    if ([ self.VideoConnection  isVideoStabilizationSupported]) {
        //这个稳定模式最适合连接
         self.VideoConnection .preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    }
    //缩放裁剪系数
     self.VideoConnection .videoScaleAndCropFactor =  self.VideoConnection .videoMaxScaleAndCropFactor;
    
#pragma mark 音频设置
    
    NSError *error1;
    //获取音频设备对象
    self.audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    //初始化捕获输入对象
    self.audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.audioDevice error:&error];
    if (error1) {
        NSLog(@"== 录音设备出错");
    }
    // 添加音频输入对象到session
    if ([self.session canAddInput:self.audioInput]) {
        [self.session addInput:self.audioInput];
    }
    //初始化输出捕获对象
    self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    
    // 添加音频输出对象到session
    if ([self.session canAddOutput:self.audioOutput]) {
        [self.session addOutput:self.audioOutput];
    }
    
    // 获取视频输入与输出连接，用于分辨音视频数据
    self.AudioConnection = [ self.audioOutput connectionWithMediaType:AVMediaTypeAudio];
    
    // 创建设置音频输出代理所需要的线程队列
    dispatch_queue_t audioQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    [self.audioOutput setSampleBufferDelegate:self queue:audioQueue];    // 提交配置
    
    [self.session commitConfiguration];
    
    _preViewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [_preViewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    _preViewLayer.frame = self.bounds;
    [self.layer addSublayer:self.preViewLayer];
    
}

//开启摄像头
-(void)startCapture{
    if (!self.session) {
        [self initAVcaptureSession];
    }
    if (![self.session isRunning]) {
        [self.session startRunning];
    }
}

//关闭摄像头
-(void)closeCapture{
    if ([self.session isRunning]) {
        [self.session stopRunning];
        NSLog(@"==关闭摄像头");
    }
}

/*****************************         摄像头设置    *******************/
//闪光灯状态
- (FlashStatus)openOrCloseFlash{
    FlashStatus status=FlashDefault;
    NSArray *inputs = self.session.inputs;
    for ( AVCaptureDeviceInput *input in inputs ) {
        AVCaptureDevice *device = input.device;
        if ( [device hasMediaType:AVMediaTypeVideo] ) {
            AVCaptureDevicePosition position = device.position;
            if (position==AVCaptureDevicePositionBack) {
                NSError *error;
                if ([device hasTorch] && [device hasFlash]){
                    if ([device lockForConfiguration:&error]) {
                        if (device.torchMode==AVCaptureTorchModeOn) {
                            [device setFlashMode:AVCaptureFlashModeOff];
                            [device setTorchMode:AVCaptureTorchModeOff];
                            status=FlashOff;
                        }else{
                            [device setFlashMode:AVCaptureFlashModeOn];
                            [device setTorchMode:AVCaptureTorchModeOn];
                            status=FlashOn;
                        }
                        [device unlockForConfiguration];
                    }else{
                        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
                    }
                }
            }
        }
    }
    return status;
}

//置换前后摄像头
-(void)switchCamera{
    if (!_session || ![_session isRunning]) {
        return;
    }
    if ([_session isRunning]) {
        [_session stopRunning];
        _session = nil;
    }
    if (_CameraPositon == AVCaptureDevicePositionBack)
        _CameraPositon = AVCaptureDevicePositionFront;
    else
        _CameraPositon = AVCaptureDevicePositionBack;
    [self initAVcaptureSession];
    if (![_session isRunning]) {
        [_session startRunning];
    }
}

//判断摄像头前后
- (BOOL)isCameraBack{
    if (_CameraPositon == AVCaptureDevicePositionBack) {
        return YES;
    }
    return NO;
}

/******************************       放大缩小因子 *************************/
//放大缩小手势
- (void)shotPinchGesture:(UIPinchGestureRecognizer *)recognizer{
    NSArray *array=[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *device=nil;
    for(AVCaptureDevice *device_ in array){
        if (device_.position==_CameraPositon) {
            device=device_;
            break;
        }
    }
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        pintchZoom = device.videoZoomFactor;
    }
    if ([self deviceCanScale:device]) {
        CGFloat zoomFactor;
        CGFloat scale = recognizer.scale;
        if (scale < 1.0f) {
            zoomFactor = pintchZoom - pow(device.activeFormat.videoMaxZoomFactor, 1.0f - recognizer.scale)/10.f;
        }
        else
        {
            zoomFactor = pintchZoom + pow(device.activeFormat.videoMaxZoomFactor, (recognizer.scale - 1.0f) / 2.0f)/10.f;
        }
        // 控制放大的倍数 最大的放大因子为10 ，最小为1
        zoomFactor = MIN(10.0f, zoomFactor);
        zoomFactor = MAX(1.0f, zoomFactor);
        [self scaleDevice:device zoom:zoomFactor];
        if(self.cameraScale){
            self.cameraScale((zoomFactor-1.0)/9.0);
        }
    }else{
        NSLog(@"==不支持摄像头放大");
    }
}

//判断设备是否支持缩放
-(BOOL)deviceCanScale:(AVCaptureDevice *)device{
    if (device.activeFormat.videoMaxZoomFactor==1.0) {
        return NO;
    }
    return YES;
}

//放大因子
-(void)scaleDevice:(AVCaptureDevice *)device zoom:(CGFloat)zoomFactor
{
    NSError *error = nil;
    [device lockForConfiguration:&error];
    if (!error) {
        device.videoZoomFactor = zoomFactor;
        [device unlockForConfiguration];
    }
}

//缩小因子
-(void)scaleDeviceImage:(float)scale{
    AVCaptureDevice *device=[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([self deviceCanScale:device]) {
        CGFloat zoomFactor=10*scale;
        if (zoomFactor<1.0) {
            [self scaleDevice:device zoom:MAX(1.0, zoomFactor)];
        }else{
            [self scaleDevice:device zoom:zoomFactor];
        }
        if(self.cameraScale){
            self.cameraScale(scale);
        }
    }else{
        NSLog(@"不支持摄像头放大");
    }
}

/***************************          设置视频参数             ********************/
- (NSString*)realPreset {
    switch (_definePreset) {
        case CaptureSessionPreset640x480:
            _realPreset = AVCaptureSessionPreset640x480;
            break;
        case CaptureSessionPresetiFrame960x540:
            _realPreset = AVCaptureSessionPresetiFrame960x540;
            
            break;
        case CaptureSessionPreset1280x720:
            _realPreset = AVCaptureSessionPreset1280x720;
            
            break;
        default:
            _realPreset = AVCaptureSessionPreset640x480;
            
            break;
    }
    return _realPreset;
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    CMTime pts = CMSampleBufferGetDuration(sampleBuffer);
    
    double dPTS = (double)(pts.value) / pts.timescale;
    NSLog(@"DPTS is %f",dPTS);
    
    if (connection == self.VideoConnection ) {
            // 摄像头采集后的图像是未编码的CMSampleBuffer形式，
            [_h264 encodeSmapleBuffer:sampleBuffer];
    }
    else if (connection == self.AudioConnection) {
            [_aac encodeSmapleBuffer:sampleBuffer];
    }
}

-(void)dealloc{
    NSLog(@"==closefile==dealloc");
}

@end
