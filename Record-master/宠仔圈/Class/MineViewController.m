//
//  MineViewController.m
//  宠仔圈
//
//  Created by jieku on 2017/5/15.
//  Copyright © 2017年 TSM. All rights reserved.
//

#import "MineViewController.h"
#import "DecodeView.h"

@interface MineViewController ()

@end

@implementation MineViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    DecodeView *decodeView = [[DecodeView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    [decodeView startDecode];
    [self.view addSubview:decodeView];
    
    
}


@end
