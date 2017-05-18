//
//  NSString+Extent.m
//  宠仔圈
//
//  Created by jieku on 2017/5/16.
//  Copyright © 2017年 TSM. All rights reserved.
//

#import "NSString+Extent.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (Extent)


- (CGSize)sizeWithFont:(UIFont *)font maxW:(CGFloat)maxW
{
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    attrs[NSFontAttributeName] = font;
    CGSize maxSize = CGSizeMake(maxW, MAXFLOAT);
    return [self boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin |NSStringDrawingUsesFontLeading attributes:attrs context:nil].size;
}
@end
