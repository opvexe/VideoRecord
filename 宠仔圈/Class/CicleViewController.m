//
//  CicleViewController.m
//  宠仔圈
//
//  Created by jieku on 2017/5/15.
//  Copyright © 2017年 TSM. All rights reserved.
//

#import "CicleViewController.h"
#import "RecordViewController.h"

@interface CicleViewController ()

@end

@implementation CicleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"lick" forState:UIControlStateNormal];
    btn.frame = CGRectMake(100, 100, 50, 50);
    btn.backgroundColor = [UIColor redColor];
    [btn addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

-(void)click{
    RecordViewController *rvc = [[RecordViewController alloc]init];
    [self.navigationController pushViewController:rvc animated:YES];
}
@end
