//
//  RecordViewController.m
//  宠仔圈
//
//  Created by jieku on 2017/5/16.
//  Copyright © 2017年 TSM. All rights reserved.
//

#import "RecordViewController.h"
#import "CaptureSession.h"


@interface RecordViewController ()


@property (nonatomic, strong) CaptureSession *captureSession;
@end

@implementation RecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
    
    _captureSession = [[CaptureSession alloc]initWithFrame:[UIScreen mainScreen].bounds CaptureWithSessionPreset:CaptureSessionPreset640x480 CameraPositon:AVCaptureDevicePositionBack];
 
    [_captureSession startCapture];  //开启编码
    [self.view addSubview:self.captureSession];
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [_captureSession closeCapture];
    _captureSession =nil;
}


-(void)dealloc{
    
    NSLog(@"==RecordViewController ==delloc");
}

@end
