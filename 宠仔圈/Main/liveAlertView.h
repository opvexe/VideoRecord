//
//  liveAlertView.h
//  宠仔圈
//
//  Created by jieku on 2017/5/15.
//  Copyright © 2017年 TSM. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface liveAlertView : UIView

@property (nonatomic, strong)UIImageView *blurImage; //高斯模糊背景图片
@property (nonatomic, strong)UIButton *midButton;
@property (nonatomic, strong)UIButton *photoButton;
@property (nonatomic, strong)UIButton *LiveButton;
@property (nonatomic, strong)UIButton *recordButton;
@property (nonatomic, assign)BOOL isShow;

-(void)show;

-(void)dismiss;

@property (nonatomic, copy)void(^clickBlock)(UIButton *sender);
@end
