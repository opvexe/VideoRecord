//
//  CaptureSession.h
//  宠仔圈
//
//  Created by jieku on 2017/5/16.
//  Copyright © 2017年 TSM. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


//设置视频分辨率
typedef NS_ENUM(NSUInteger,CaptureSessionPreset){
    CaptureSessionPreset640x480,
    CaptureSessionPresetiFrame960x540,
    CaptureSessionPreset1280x720,
};

//设置闪关灯状态
typedef  enum{
    FlashDefault,
    FlashOn,
    FlashOff,
} FlashStatus;

//打开录播代理行为
@protocol openCameraRecordDelage <NSObject>

-(void)initWithOpenCamera:(UIButton *)sender;

@end


@interface CaptureSession : UIView

//接受代理行为
@property (nonatomic, weak)id <openCameraRecordDelage> delegate;

@property (nonatomic,copy)void (^cameraScale)(float progress) ; ///摄像头缩放系数

- (instancetype)initWithFrame:(CGRect)frame  CaptureWithSessionPreset:(CaptureSessionPreset)preset CameraPositon:(AVCaptureDevicePosition)CameraPositon;

//开启，关闭
-(void)startCapture;
-(void)closeCapture;

//前后摄像头置换
-(void)switchCamera;

//手势摄像头 放大缩小
- (void)shotPinchGesture:(UIPinchGestureRecognizer *)recognizer;
-(void)scaleDeviceImage:(float)scale;

//闪光灯状态
-(FlashStatus)openOrCloseFlash;
@end
