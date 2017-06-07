//
//  CZQTabBarController.m
//  宠仔圈
//
//  Created by jieku on 2017/5/15.
//  Copyright © 2017年 TSM. All rights reserved.
//

#import "CZQTabBarController.h"
#import "CicleViewController.h"
#import "MineViewController.h"  
#import "QZQNavigationController.h"

#import "liveAlertView.h"
#import "UIImage+Blur.h"

#import "RecordViewController.h"

@interface CZQTabBarController ()

@property (nonatomic, strong)UIButton *liveButton;
@property (nonatomic, strong)liveAlertView *liveAlertView;
@end

@implementation CZQTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];

    [self addChileVC];
}

- (void)addChileVC{

    CicleViewController *cicrl = [[CicleViewController alloc]init];
    QZQNavigationController *nav1 = [self setChildVC:cicrl title:@"编码" imageName:@"icon_circle_n" withSelectedName:@"icon_circle_s"];
    
    MineViewController *mine = [[MineViewController alloc]init];
    QZQNavigationController *nav2 =  [self setChildVC:mine title:@"解码" imageName:@"icon_myself_n" withSelectedName:@"icon_myself_s"];
    
    self.viewControllers = @[nav1,nav2];
    [self addLiveBtn];
}

- (QZQNavigationController *)setChildVC:(UIViewController *)vc title:(NSString *)title imageName:(NSString *)imgName withSelectedName:(NSString *)selectedName{
    
    vc.title                = title;
    vc.tabBarItem.image     = [[UIImage imageNamed:imgName]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];;
    vc.tabBarItem.selectedImage = [[UIImage imageNamed:selectedName]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [vc.tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor grayColor], NSForegroundColorAttributeName, [UIFont systemFontOfSize:10.0],NSFontAttributeName,nil] forState:UIControlStateNormal];
    [vc.tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor redColor], NSForegroundColorAttributeName,[UIFont systemFontOfSize:10.0],NSFontAttributeName,nil] forState:UIControlStateSelected];
    QZQNavigationController *nav = [[QZQNavigationController alloc]initWithRootViewController:vc];

    
    return nav;
}


-(void)addLiveBtn{
    
    [[UITabBar appearance] setShadowImage:[UIImage new]];
    [[UITabBar appearance] setBackgroundImage:[UIImage new]];
    
    UIView *line = [[UIView alloc] init];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    line.frame = CGRectMake(0, 0, self.tabBar.bounds.size.width, 0.5);
    [self.tabBar addSubview:line];
    
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    [super setSelectedIndex:selectedIndex];
    [self beginAnimation];
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    [self beginAnimation];
}
- (void)beginAnimation
{
    CATransition *animation         = [[CATransition alloc]init];
    animation.duration              = 0.5;
    animation.type                  = kCATransitionFade;
    animation.subtype               = kCATransitionFromRight;
    animation.timingFunction        = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    animation.accessibilityFrame    = CGRectMake(0, 64, self.tabBar.frame.size.width, self.tabBar.frame.size.height);
    [self.view.layer addAnimation:animation forKey:@"switchView"];
}
@end
