//
//  MineViewController.m
//  宠仔圈
//
//  Created by jieku on 2017/5/15.
//  Copyright © 2017年 TSM. All rights reserved.
//

#import "MineViewController.h"
#import "DecodeViewController.h"
@interface MineViewController ()

@end

@implementation MineViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"点击进入解码界面" forState:UIControlStateNormal];
    btn.frame = CGRectMake(100, 100, 200, 20);
    btn.backgroundColor = [UIColor redColor];
    [btn addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
}

-(void)click{
    DecodeViewController *rvc = [[DecodeViewController alloc]init];
    [self.navigationController pushViewController:rvc animated:YES];
}

@end
