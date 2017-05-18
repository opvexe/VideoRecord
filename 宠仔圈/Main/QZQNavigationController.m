//
//  QZQNavigationController.m
//  宠仔圈
//
//  Created by jieku on 2017/5/15.
//  Copyright © 2017年 TSM. All rights reserved.
//

#import "QZQNavigationController.h"

@interface QZQNavigationController ()

@end

@implementation QZQNavigationController

+(void)initialize{
    UINavigationBar *navBar=[UINavigationBar appearance];
    [navBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    
    NSMutableDictionary *textAttrs = [NSMutableDictionary dictionary];
    textAttrs[NSForegroundColorAttributeName] = [UIColor redColor];
    textAttrs[NSFontAttributeName] =  [UIFont systemFontOfSize:16.0];
    navBar.shadowImage=[[UIImage alloc]init];  //隐藏掉导航栏底部的那条线
    [navBar setTitleTextAttributes:textAttrs];

}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (self.viewControllers.count > 0)
    {
        viewController.hidesBottomBarWhenPushed = YES;
    }
    [super pushViewController:viewController animated:animated];
}

@end
