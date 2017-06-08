//
//  EncodeH264.m
//  AVColletion
//
//  Created by TSM W on 2017/3/5.
//  Copyright © 2017年 oppsr. All rights reserved.
//

#import "EncodeH264.h"


@interface EncodeH264 (){
    
    dispatch_queue_t encodeQueue;
    long timeStamp;
    VTCompressionSessionRef encodeSesion;//压缩会话
}
@property (nonatomic , assign) BOOL isObtainspspps;//判断是否已经获取到pps和sps
@property (nonatomic, strong) NSFileHandle *handle;
@end

/**
 编码回调
 
 @param userData 回调参考值
 @param sourceFrameRefCon 帧的引用值
 @param status noErr代表压缩成功; 如果压缩不成功，则为错误代码。
 @param infoFlags 编码操作的信息
 @param sampleBuffer 包含压缩帧，如果压缩成功并且帧未被删除; 否则为NULL。
 
 */
void encodeOutputCallback(void *userData, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags,
                          CMSampleBufferRef sampleBuffer )
{
    if (status != noErr) {
        NSLog(@"didCompressH264 error: with status %d, infoFlags %d", (int)status, (int)infoFlags);
        return;
    }
    if (!CMSampleBufferDataIsReady(sampleBuffer))
    {
        NSLog(@"didCompressH264 data is not ready ");
        return;
    }
    
    EncodeH264 *h264 = (__bridge EncodeH264*)userData;
    
    // 判断当前帧是否为关键帧
    bool keyframe = !CFDictionaryContainsKey( (CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)), kCMSampleAttachmentKey_NotSync);
    
//    // 获取sps & pps数据. sps pps只需获取一次，保存在h264文件开头即可
    if (keyframe&& !h264.isObtainspspps) {
        
        // CMVideoFormatDescription：图像存储方式，编解码器等格式描述
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        // sps
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        OSStatus statusSPS = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0);
        if (statusSPS == noErr) {
            
            // Found sps and now check for pps
            // pps
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusPPS = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0);
            if (statusPPS == noErr) {
                
                // found sps pps
                NSData *sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                NSData *pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                if (h264) {
                    
                    [h264 gotSPS:sps withPPS:pps];
                }
            }
        }
    }

    
    size_t lengthAtOffset, totalLength;
    char *data;
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    OSStatus error = CMBlockBufferGetDataPointer(dataBuffer, 0, &lengthAtOffset, &totalLength, &data);
    
    if (error == noErr) {
        size_t offset = 0;
        const int lengthInfoSize = 4; // 返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
        
        // 循环获取nalu数据
        while (offset < totalLength - lengthInfoSize) {
            uint32_t naluLength = 0;
            memcpy(&naluLength, data + offset, lengthInfoSize); // 获取nalu的长度，
            
            // 大端模式转化为系统端模式
            naluLength = CFSwapInt32BigToHost(naluLength);
            NSLog(@"got nalu data, length=%d, totalLength=%zu", naluLength, totalLength);
            
             NSData *dataPoint = [[NSData alloc] initWithBytes:(data + offset + lengthInfoSize) length:naluLength];
            // 保存nalu数据到文件
            [h264 gotEncodedData:dataPoint isKeyFrame:keyframe];
            // 读取下一个nalu，一次回调可能包含多个nalu
            offset += lengthInfoSize + naluLength;
        }
    }
}

@implementation EncodeH264

- (instancetype)init {
    
    if ([super init]) {
        encodeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        timeStamp = 0;
        
        NSString *filePath = VideoH264Path;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil]; // 移除旧文件
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil]; // 创建新文件
        self.handle = [NSFileHandle fileHandleForWritingAtPath:filePath];  // 管理写进文件
        
    }
    return self;
}

- (BOOL)createEncodeSession:(int)width height:(int)height fps:(int)fps bite:(int)bt {
    
    OSStatus status;
    
    //帧压缩完成时调用的回调原型。
    VTCompressionOutputCallback cb = encodeOutputCallback;
    //创建压缩视频帧的会话。
    status = VTCompressionSessionCreate(kCFAllocatorDefault, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, cb, (__bridge void *)(self), &encodeSesion);
    
    if (status != noErr) {
        NSLog(@"VTCompressionSessionCreate failed. ret=%d", (int)status);
        return NO;
    }
    
    //******设置会话的属性******
    //提示视频编码器，压缩是否实时执行。
    status = VTSessionSetProperty(encodeSesion, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    NSLog(@"set realtime  return: %d", (int)status);
    
    //指定编码比特流的配置文件和级别。直播一般使用baseline，可减少由于b帧带来的延时
    status = VTSessionSetProperty(encodeSesion, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
    NSLog(@"set profile   return: %d", (int)status);
    
    //设置比特率。 比特率可以高于此。默认比特率为零，表示视频编码器。应该确定压缩数据的大小。注意，比特率设置只在定时时有效，为源帧提供信息，并且一些编解码器提供不支持限制到指定的比特率。
    status  = VTSessionSetProperty(encodeSesion, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(bt));
    //速率的限制
    status += VTSessionSetProperty(encodeSesion, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)@[@(bt*2/8), @1]); // Bps
    NSLog(@"set bitrate   return: %d", (int)status);
    
    // 设置关键帧速率。
    status = VTSessionSetProperty(encodeSesion, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)@(fps*2));
    
    // 设置预期的帧速率。
    status = VTSessionSetProperty(encodeSesion, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)@(fps));
    NSLog(@"set framerate return: %d", (int)status);
    
    // 开始编码
    status = VTCompressionSessionPrepareToEncodeFrames(encodeSesion);
    NSLog(@"start encode  return: %d", (int)status);
    
    return YES;

}

#pragma mark - 编码完成写入h264文件中
- (void)gotSPS:(NSData *)sps withPPS:(NSData *)pps {
    
    NSLog(@"gotSPSAndPPS %d withPPS %d", (int)[sps length], (int)[pps length]);
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *byteHeader = [NSData dataWithBytes:bytes length:length];
    [_handle writeData:byteHeader];
    [_handle writeData:sps];
    [_handle writeData:byteHeader];
    [_handle writeData:pps];
}

- (void)gotEncodedData:(NSData *)data isKeyFrame:(BOOL)isKeyFrame {
    
    NSLog(@"gotEncodedData %d", (int)[data length]);
    if (_handle != NULL) {
        
        const char bytes[]= "\x00\x00\x00\x01";
        size_t lenght = (sizeof bytes) - 1;
        NSData *byteHeader = [NSData dataWithBytes:bytes length:lenght];
        [_handle writeData:byteHeader];
        [_handle writeData:data];
    }
}

- (void) stopEncodeSession
{
    VTCompressionSessionCompleteFrames(encodeSesion, kCMTimeInvalid);
    VTCompressionSessionInvalidate(encodeSesion);
    CFRelease(encodeSesion);
    encodeSesion = NULL;
    [self closefile];
}

- (void)encodeSmapleBuffer:(CMSampleBufferRef)sampleBuffer {
 
    dispatch_sync(encodeQueue, ^{
        //CVImageBuffer的媒体数据。
        CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        // 此帧的呈现时间戳，将附加到样本缓冲区，传递给会话的每个显示时间戳必须大于上一个。
        timeStamp ++;
        CMTime pts = CMTimeMake(timeStamp, 1000);
        //此帧的呈现持续时间
        CMTime duration = kCMTimeInvalid;
        VTEncodeInfoFlags flags;
        // 调用此函数可将帧呈现给压缩会话。
        OSStatus statusCode = VTCompressionSessionEncodeFrame(encodeSesion,
                                                              imageBuffer,
                                                              pts, duration,
                                                              NULL, NULL, &flags);
        
        if (statusCode != noErr) {
            NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
            
            [self stopEncodeSession];
            return;
        }
    });
}
#pragma mark 关闭摄像头时关闭文件
- (void)closefile {
    [_handle closeFile];
    _handle = NULL;
}
@end
