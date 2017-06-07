//
//  liveAlertView.m
//  宠仔圈
//
//  Created by jieku on 2017/5/15.
//  Copyright © 2017年 TSM. All rights reserved.
//

#import "liveAlertView.h"
#import "UIImage+Blur.h"

@interface liveAlertView ()

@property (nonatomic, strong)UIControl *control;

@end
@implementation liveAlertView



- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [self setLiveAlertView];
        
    }
    return self;
}


-(void)setLiveAlertView{
    
    self.frame = [UIScreen mainScreen].bounds;
    
    _blurImage =[[UIImageView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    _blurImage.userInteractionEnabled = YES;
    [self addSubview:self.blurImage];
    
    
    _midButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _midButton.frame = CGRectMake(self.bounds.size.width/2, self.bounds.size.height-50, 50, 50);
    [_midButton addTarget:self action:@selector(dothings) forControlEvents:UIControlEventTouchUpInside];
    [_midButton setImage:[UIImage imageNamed:@"icon_photo_close_h"] forState:UIControlStateNormal];
    [_midButton setImage:[UIImage imageNamed:@"icon_photo_close_s"] forState:UIControlStateSelected];
    [self addSubview:self.midButton];
    
    _photoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _photoButton.frame = CGRectMake(100, 300, 50, 50);
    [_photoButton setTag:101];
    [_photoButton addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    [_photoButton setImage:[UIImage imageNamed:@"icon_photo_h"] forState:UIControlStateNormal];
    [_photoButton setImage:[UIImage imageNamed:@"icon_photo_s"] forState:UIControlStateSelected];
    [self addSubview:self.photoButton];

    
    _LiveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _LiveButton.frame  = CGRectMake(200, 300, 50, 50);
    [_LiveButton setTag:102];
    [_LiveButton setImage:[UIImage imageNamed:@"icon_play_h"] forState:UIControlStateNormal];
    [_LiveButton setImage:[UIImage imageNamed:@"icon_play_s"] forState:UIControlStateSelected];
    [_LiveButton addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.LiveButton];
    
    _recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _recordButton.frame = CGRectMake(300, 300, 50, 50);
    [_recordButton setTag:103];
    [_recordButton setImage:[UIImage imageNamed:@"icon_play_h"] forState:UIControlStateNormal];
    [_recordButton setImage:[UIImage imageNamed:@"icon_play_s"] forState:UIControlStateSelected];
    [_recordButton addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.recordButton];
   
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dothings)];
    [self addGestureRecognizer:gesture];
    
}

#pragma mark  关闭视图
-(void)dothings{
    if (_isShow) {
        [self dismiss];
    }
}

-(void)click:(UIButton *)sender{
    if (self.clickBlock) {
        self.clickBlock(sender);
    }
}
-(void)dismiss{
    if (_isShow) {
        _isShow = NO;
        [UIView animateWithDuration:0.1 // 动画时长
                              delay:0 // 动画延迟
                            options:UIViewAnimationOptionCurveEaseInOut // 动画过渡效果
                         animations:^{
                             _photoButton.center = CGPointMake(_midButton.center.x, self.bounds.size.height+100);
                             _blurImage.alpha = 0;
                         }
                         completion:nil];
        
        [UIView animateWithDuration:0.1 // 动画时长
                              delay:0.1 // 动画延迟
                            options:UIViewAnimationOptionCurveEaseInOut // 动画过渡效果
                         animations:^{
                             _LiveButton.center = CGPointMake(_midButton.center.x, self.bounds.size.height+100);
                         }
                         completion:nil];
        
        [UIView animateWithDuration:0.2 // 动画时长
                              delay:0.2 // 动画延迟
                            options:UIViewAnimationOptionCurveEaseInOut // 动画过渡效果
                         animations:^{
                             _recordButton.center = CGPointMake(_midButton.center.x, self.bounds.size.height+100);
                         }
                         completion:^(BOOL finished) {
                             [self removeFromSuperview];
                         }];
    }
}

-(void)show{
    if (!_isShow) {
        self.isShow = YES;
        UIWindow *keywindow = [[UIApplication sharedApplication] keyWindow];
        [keywindow addSubview:self];
        
        [_blurImage setAlpha:.70];
        
        __block typeof(self) weakSelf = self;
        dispatch_queue_t queue = dispatch_queue_create("Blur queue", NULL);
        dispatch_async(queue, ^ {
            
            UIImage *blurImage = [UIImage blurryImage:weakSelf.blurImage.image withBlurLevel:0.06];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                weakSelf.layer.contents = (id)blurImage.CGImage;
            });
        });
        
        
        [UIView animateWithDuration:0.5 // 动画时长
                              delay:0.0 // 动画延迟
             usingSpringWithDamping:0.6 // 类似弹簧振动效果 0~1
              initialSpringVelocity:3.0 // 初始速度
                            options:UIViewAnimationOptionCurveEaseInOut // 动画过渡效果
                         animations:^{
                             _midButton.transform = CGAffineTransformMakeScale(1, 1);
                             _photoButton.center = CGPointMake(_photoButton.center.x, self.bounds.size.height-105-74);
                         } completion:nil];
        
        [UIView animateWithDuration:0.5 // 动画时长
                              delay:0.2 // 动画延迟
             usingSpringWithDamping:0.6 // 类似弹簧振动效果 0~1
              initialSpringVelocity:3.0 // 初始速度
                            options:UIViewAnimationOptionCurveEaseInOut // 动画过渡效果
                         animations:^{
                             _LiveButton.center = CGPointMake(_LiveButton.center.x, self.bounds.size.height-105-74);
                         } completion:nil];
        
        [UIView animateWithDuration:0.5 // 动画时长
                              delay:0.2 // 动画延迟
             usingSpringWithDamping:0.6 // 类似弹簧振动效果 0~1
              initialSpringVelocity:3.0 // 初始速度
                            options:UIViewAnimationOptionCurveEaseInOut // 动画过渡效果
                         animations:^{
                             _recordButton.center = CGPointMake(_recordButton.center.x, self.bounds.size.height-105-74);
                             
                         } completion:nil];
    }
}

@end
