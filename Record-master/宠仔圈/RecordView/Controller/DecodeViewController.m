//
//  DecodeViewController.m
//  宠仔圈
//
//  Created by jieku on 2017/6/15.
//  Copyright © 2017年 TSM. All rights reserved.
//

#import "DecodeViewController.h"
#import "DecodeView.h"

@interface DecodeViewController ()

@end

@implementation DecodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    DecodeView *decodeView = [[DecodeView alloc]initWithFrame:self.view.bounds];
    [decodeView startDecode];
    [self.view addSubview:decodeView];
}


@end
