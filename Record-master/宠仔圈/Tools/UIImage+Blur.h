//
//  UIImage+Blur.h
//  宠仔圈
//
//  Created by jieku on 2017/5/15.
//  Copyright © 2017年 TSM. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Blur)

//高斯模糊
+(UIImage *)blurryImage:(UIImage *)image withBlurLevel:(CGFloat)blur;

+(UIImage *)imageFromView:(UIView *)theView ;
@end
