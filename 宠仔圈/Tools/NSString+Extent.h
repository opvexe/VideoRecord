//
//  NSString+Extent.h
//  宠仔圈
//
//  Created by jieku on 2017/5/16.
//  Copyright © 2017年 TSM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (Extent)

- (CGSize)sizeWithFont:(UIFont *)font maxW:(CGFloat)maxW;

@end
