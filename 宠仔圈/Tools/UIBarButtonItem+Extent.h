//
//  UIBarButtonItem+Extent.h
//  宠仔圈
//
//  Created by jieku on 2017/5/16.
//  Copyright © 2017年 TSM. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBarButtonItem (Extent)

+ (UIBarButtonItem *)itemWithTarget:(id)target action:(SEL)action image:(NSString *)image highImage:(NSString *)highImage;
+ (UIBarButtonItem *)itemWithTarget:(id)target action:(SEL)action text:(NSString *)text;

+(UIBarButtonItem *)itemWithTarget:(id)target action:(SEL)action URLimage:(NSString *)imageUrl;

+ (UIBarButtonItem *)itemWithTarget:(id)target action:(SEL)action image:(NSString *)image;

@end
