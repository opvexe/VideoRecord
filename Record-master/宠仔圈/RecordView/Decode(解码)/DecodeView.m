//
//  DecodeView.m
//  宠仔圈
//
//  Created by jieku on 2017/5/17.
//  Copyright © 2017年 TSM. All rights reserved.
//

#import "DecodeView.h"
#import "JWOpenGLView.h"

#import <VideoToolbox/VideoToolbox.h>
#import <AudioToolbox/AudioToolbox.h>

#define SCREENWIDTH  [UIScreen mainScreen].bounds.size.width
#define SCREENHEIGH  [UIScreen mainScreen].bounds.size.height
@interface DecodeView ()
{
    uint8_t                   *jPacketBuffer;
    long                      jPacketSize;
    uint8_t                   *jInputBuffer;
    long                      jInputSize;
    long                      jInputMaxSize;
    
    uint8_t                   *jSPS;
    long                      jSPSSize;
    uint8_t                   *jPPS;
    long                      jPPSSize;
    
    dispatch_queue_t          decodeQueue;
}
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) NSInputStream *inputStream; // 用NSInputStream读入原始H.264码流

@property (nonatomic, assign)VTDecompressionSessionRef decodeSession; // 解码
@property (nonatomic, assign) CMFormatDescriptionRef   formatDescription;

@property (nonatomic, strong)JWOpenGLView *jOpenGLView;
@end

const uint8_t lyStartCode[4] = {0, 0, 0, 1};
@implementation DecodeView


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.jOpenGLView = [[JWOpenGLView alloc] init];
        self.jOpenGLView.frame = self.bounds;
        [self addSubview:self.jOpenGLView];
        [self.jOpenGLView setupGL];
        
        decodeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0); // 用CADisplayLink 控制显示速率
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFrame)];
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode]; // 添加RunLoop
        [self.displayLink setPaused:YES];
    }
    return self;
}

/********************           ToolBox               ***************/
- (void)updateFrame {  // <RunLoop selector>不断刷新frame
    if (_inputStream) {
        
        dispatch_sync(decodeQueue, ^{
            
            [self readPacket];
            if (jPacketBuffer == NULL || jPacketSize == 0) {
                
                [self onInputEnd];
                NSLog(@"==解码成功");
                return;
            }
            // 替换头字节长度
            uint32_t nalSize = (uint32_t)(jPacketSize - 4);
            uint32_t *pNalSize = (uint32_t *)jPacketBuffer;
            *pNalSize = CFSwapInt32BigToHost(nalSize);
            
            // 在buffer的前面填入代表长度的int
            // 用NALU的前四个字节识别SPS和PPS并存储
            CVPixelBufferRef pixelBuffer = NULL;  // 包含未压缩像素数据，包括图像宽度、高度等
            int nalType = jPacketBuffer[4] & 0x1F;
            switch (nalType) {
                case 0x05:
                    NSLog(@"Nal type is IDR frame"); // 当读入IDR帧的时候初始化VideoToolbox，并开始同步解码
                    [self initVideoToolBox];
                    pixelBuffer = [self decode];
                    break;
                case 0x07:
                    NSLog(@"Nal type is SPS");
                    jSPSSize = jPacketSize - 4;
                    jSPS = malloc(jSPSSize);
                    memcpy(jSPS, jPacketBuffer + 4, jSPSSize); // 复制packet内容到新的缓冲区
                    break;
                case 0x08:
                    NSLog(@"Nal type is PPS");
                    jPPSSize = jPacketSize - 4;
                    jPPS = malloc(jPPSSize);
                    memcpy(jPPS, jPacketBuffer + 4, jPPSSize); // 复制packet内容到新的缓冲区
                    break;
                default:
                    NSLog(@"Nal type is B/P frame");
                    pixelBuffer = [self decode];
                    break;
            }
            
            if (pixelBuffer) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    // 显示解码的结果
                    // 解码得到的CVPixelBufferRef会传入OpenGL ES类进行解析渲染。
                    [self.jOpenGLView displayPixelBuffer:pixelBuffer];
                    CVPixelBufferRelease(pixelBuffer);
                });
            }
            NSLog(@"Read Nalu size %ld", jPacketSize);
        });
    }
}

// 获取前四个字节识别SPS和PPS并存储到缓存中
- (void)readPacket {
    
    if (jPacketSize && jPacketBuffer) {
        
        jPacketSize = 0;
        free(jPacketBuffer);
        jPacketBuffer = NULL;
    }
    // jInputStream.hasBytesAvailable:return YES if the stream has bytes available or if it impossible to tell without actually doing the read
    if (jInputSize < jInputMaxSize && _inputStream.hasBytesAvailable) {
        
        // 获取视频长度
        jInputSize += [_inputStream read:jInputBuffer + jInputSize maxLength:jInputMaxSize - jInputSize];
    }
    // memcmp是比较内存区域buf1和buf2的前count个字节, 当buf1<buf2时，返回值-1; 当buf1==buf2时，返回值=0; 当buf1>buf2时，返回值1
    if (memcmp(jInputBuffer, lyStartCode, 4) == 0) {
        
        // 获取读取视频内容
        if (jInputSize > 4) { // 除了开始码还有内容
            
            uint8_t *pStart = jInputBuffer + 4;
            uint8_t *pEnd = jInputBuffer + jInputSize;
            while (pStart != pEnd) { //这里使用一种简略的方式来获取这一帧的长度：通过查找下一个0x00000001来确定。
                if(memcmp(pStart - 3, lyStartCode, 4) == 0) {
                    jPacketSize = pStart - jInputBuffer - 3;
                    if (jPacketBuffer) {
                        free(jPacketBuffer);
                        jPacketBuffer = NULL;
                    }
                    jPacketBuffer = malloc(jPacketSize);
                    memcpy(jPacketBuffer, jInputBuffer, jPacketSize); // 复制packet内容到新的缓冲区
                    memmove(jInputBuffer, jInputBuffer + jPacketSize, jInputSize - jPacketSize); // 把缓冲区前移
                    jInputSize -= jPacketSize;
                    break;
                }
                else {
                    ++pStart;
                }
            }
            
        }
    }
}


//初始化VideoToolBox
- (void)initVideoToolBox {
    
    if (!_decodeSession) {
        
        // 把SPS和PPS包装成CMVideoFormatDescription
        const uint8_t *parameterSetPointers[2] = {jSPS, jPPS};
        const size_t parameterSetSizes[2] = {jSPSSize, jPPSSize};
        OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                              2, // param count
                                                                              parameterSetPointers,
                                                                              parameterSetSizes,
                                                                              4, // nal start code size
                                                                              &_formatDescription);
        if (status == noErr) {
            
            CFDictionaryRef dictRef = NULL;
            const void *keys[] = {kCVPixelBufferPixelFormatTypeKey};
            //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
            //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
            uint32_t key = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
            const void *values[] = {CFNumberCreate(NULL, kCFNumberSInt32Type, &key)};
            dictRef = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
            
            VTDecompressionOutputCallbackRecord callBackRecord;
            callBackRecord.decompressionOutputCallback = didDecompress;
            callBackRecord.decompressionOutputRefCon = NULL;
            
            status = VTDecompressionSessionCreate(kCFAllocatorDefault, _formatDescription, NULL, dictRef, &callBackRecord, &_decodeSession);
            
            CFRelease(dictRef);
        }
        else {
            
            NSLog(@"IOS8VT: reset decoder session failed status =% d", status);
        }
    }
}

/********************************             视频，音频解码 *************************/

// 开始视频解码
- (void)startDecode {
    
    [self audioStart];
    
    [self videoStart];
    
    [self.displayLink setPaused:NO];
}

//获取aac音频解码
- (void)audioStart {
    
    NSString *urlString = AudioAacPath;
    NSURL *audioUrl = [NSURL URLWithString:urlString];
    
    SystemSoundID soundID;
    // Creates a system sound object.
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(audioUrl), &soundID);
    // Registers a callback function that is invoked when a specified system sound finishes playing.
    AudioServicesAddSystemSoundCompletion(soundID, NULL, NULL, &playCallBack, (__bridge void * _Nullable)(self));
    // AudioServicesPlayAlertSound(soundID);
    AudioServicesPlaySystemSound(soundID);
}

void playCallBack(SystemSoundID ID, void *clientData) {
    
    NSLog(@"callBack");
}


// 停止解码
- (void)onInputEnd {
    
    [_inputStream close];
    _inputStream = nil;
    if (jInputBuffer) {
        free(jInputBuffer);
        jInputBuffer = NULL;
    }
    [self.displayLink setPaused:YES];
    [self endVideoToolBox];
}

//结束播放
- (void)endVideoToolBox {
    
    if (_decodeSession) {
        
        VTDecompressionSessionInvalidate(_decodeSession);
        CFRelease(_decodeSession);
        _decodeSession = NULL;
    }
    if (_formatDescription) {
        
        CFRelease(_formatDescription);
        _formatDescription = NULL;
    }
    free(jSPS);
    free(jPPS);
}

//开始解码
- (CVPixelBufferRef)decode {
    
    CVPixelBufferRef outputPixelBuffer = NULL;
    if (_decodeSession) {
        
        // 用CMBlockBuffer把NALUnit包装起来
        CMBlockBufferRef blockBuffer = NULL;
        OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault, (void *)jPacketBuffer, jPacketSize, kCFAllocatorNull, NULL, 0, jPacketSize, 0, &blockBuffer);
        if (status == kCMBlockBufferNoErr) {
            
            // 传入CMSampleBuffer
            CMSampleBufferRef sampleBuffer = NULL;
            const size_t sampleSizeArray[] = {jPacketSize};
            status = CMSampleBufferCreateReady(kCFAllocatorDefault, blockBuffer, _formatDescription, 1, 0, NULL, 1, sampleSizeArray, &sampleBuffer);
            
            if (status == kCMBlockBufferNoErr && sampleBuffer) {
                
                VTDecodeFrameFlags flags = 0;
                VTDecodeInfoFlags  infoFlags = 0;
                // 默认是同步操作->会调用didDecompress，再回调
                // outputPixelBuffer 开始解码
                OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_decodeSession, sampleBuffer, flags, &outputPixelBuffer, &infoFlags);
                
                if(decodeStatus == kVTInvalidSessionErr) {
                    NSLog(@"IOS8VT: Invalid session, reset decoder session");
                } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                    NSLog(@"IOS8VT: decode failed status=%d(Bad data)", (int)decodeStatus);
                } else if(decodeStatus != noErr) {
                    NSLog(@"IOS8VT: decode failed status=%d", (int)decodeStatus);
                }
                CFRelease(sampleBuffer);
            }
            CFRelease(blockBuffer);
        }
    }
    return outputPixelBuffer;
}

//完成回调
void didDecompress(void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ) {
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}



//获取储存的H.264
- (void)videoStart {
    
    // H.264储存的路径
    NSString *filePath = VideoH264Path;

    // 用NSInputStream读入原始H.264码流
    _inputStream = [[NSInputStream alloc] initWithFileAtPath:filePath];
    [_inputStream open];
    jInputSize = 0;
    jInputMaxSize = SCREENHEIGH * SCREENWIDTH * 3 * 4;
    jInputBuffer = malloc(jInputMaxSize); // malloc 向系统申请分配指定size个字节的内存空间
}

- (void)dealloc
{
    NSLog(@"DecodeView");
}

@end
