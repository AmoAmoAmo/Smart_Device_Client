//
//  HJH264Decoder.m
//  Smart_Device_Client
//
//  Created by Josie on 2017/9/22.
//  Copyright © 2017年 Josie. All rights reserved.
//

#import "HJH264Decoder.h"


@interface HJH264Decoder()
{
    VTDecompressionSessionRef   mDecodeSession;
    CMFormatDescriptionRef      mFormatDescription; // video的格式，包括宽高、颜色空间、编码格式等；对于H.264的视频，PPS和SPS的数据也在这里；
    
    uint8_t*        packetBuffer;  // 一帧的缓冲区  // unsigned char *
    long            packetSize;    // 一帧的size（长度，字节
    
    uint8_t     *mSPS;
    long        mSPSSize;
    uint8_t     *mPPS;
    long        mPPSSize;
    
}
@end

@implementation HJH264Decoder

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

-(void)startH264DecodeWithVideoData:(char *)videoData andLength:(int)length andReturnDecodedData:(ReturnDecodedVideoDataBlock)block
{
    self.returnDataBlock = block;
    
    packetBuffer = (unsigned char *)videoData;
    packetSize = length;
    
    [self updateFrame];
}

-(void)stopH264Decode
{
    [self EndVideoToolBox];
}

// 一收到数据就调用这个方法，用来刷新屏幕
- (void)updateFrame
{
    // 同步 --》 顺序执行
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // 替换头字节长度
        uint32_t nalSize = (uint32_t)(packetSize - 4);
        uint32_t *pNalSize = (uint32_t *)packetBuffer;
        *pNalSize = CFSwapInt32HostToBig(nalSize);
        
        // 在buffer的前面填入代表长度的int    // 以00 00 00 01分割之后的下一个字节就是--NALU类型--
        CVPixelBufferRef pixelBuffer = NULL;
        int nalType = packetBuffer[4] & 0x1F;  // NALU类型  & 0001  1111
        switch (nalType) {
            case 0x05:
//                NSLog(@"*********** IDR frame, I帧");
                [self initVideoToolBox]; // 当读入IDR帧的时候初始化VideoToolbox，并开始同步解码
                pixelBuffer = [self decode]; // 解码得到的CVPixelBufferRef会传入OpenGL ES类进行解析渲染
                break;
            case 0x07:
//                NSLog(@"*********** SPS");
                mSPSSize = packetSize - 4;
                mSPS = malloc(mSPSSize);
                memcpy(mSPS, packetBuffer + 4, mSPSSize);
                break;
            case 0x08:
//                NSLog(@"*********** PPS");
                mPPSSize = packetSize - 4;
                mPPS = malloc(mPPSSize);
                memcpy(mPPS, packetBuffer + 4, mPPSSize);
                break;
            default:
//                NSLog(@"*********** B/P frame"); // P帧?
                pixelBuffer = [self decode];
                
                break;
        }
        
        if(pixelBuffer) {
            // 把解码后的数据block传给viewController
            self.returnDataBlock(pixelBuffer);
            CVPixelBufferRelease(pixelBuffer);
            
        }
    });
}

- (void)initVideoToolBox {
    if (!mDecodeSession) {
        // 把SPS和PPS包装成CMVideoFormatDescription
        const uint8_t* parameterSetPointers[2] = {mSPS, mPPS};
        const size_t parameterSetSizes[2] = {mSPSSize, mPPSSize};
        OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                              2, //param count
                                                                              parameterSetPointers,
                                                                              parameterSetSizes,
                                                                              4, //nal start code size
                                                                              &mFormatDescription);
        if(status == noErr) {
            CFDictionaryRef attrs = NULL;
            const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
            //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
            //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
            uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
            const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
            attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
            
            VTDecompressionOutputCallbackRecord callBackRecord;
            callBackRecord.decompressionOutputCallback = didDecompress;
            callBackRecord.decompressionOutputRefCon = NULL;
            
            status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                                  mFormatDescription,
                                                  NULL, attrs,
                                                  &callBackRecord,
                                                  &mDecodeSession);
            CFRelease(attrs);
        } else {
            NSLog(@"IOS8VT: reset decoder session failed status = %d", (int)status);
        }
    }
}




void didDecompress(void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}





-(CVPixelBufferRef)decode {
    
    CVPixelBufferRef outputPixelBuffer = NULL;
    if (mDecodeSession) {
        // 用CMBlockBuffer(未压缩的图像数据) 把NALUnit包装起来
        CMBlockBufferRef blockBuffer = NULL;
        OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                              (void*)packetBuffer, packetSize,
                                                              kCFAllocatorNull,
                                                              NULL, 0, packetSize,
                                                              0, &blockBuffer);
        if(status == kCMBlockBufferNoErr) {
            // ---- 创建CMSampleBuffer ----  把原始码流包装成CMSampleBuffer(存放一个或者多个压缩或未压缩的媒体文件)
            CMSampleBufferRef sampleBuffer = NULL;
            const size_t sampleSizeArray[] = {packetSize};
            status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                               blockBuffer,        // 用CMBlockBuffer把NALUnit包装起来
                                               mFormatDescription, // 把SPS和PPS包装成CMVideoFormatDescription
                                               1, 0, NULL, 1, sampleSizeArray,
                                               &sampleBuffer);
            
            // ------------- 解码并显示 -------------
            if (status == kCMBlockBufferNoErr && sampleBuffer) {
                
                VTDecodeFrameFlags flags = 0;
                VTDecodeInfoFlags flagOut = 0;
                // 默认是同步操作。
                // 调用didDecompress，返回后再回调
                OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(mDecodeSession,
                                                                          sampleBuffer,
                                                                          flags,
                                                                          &outputPixelBuffer,
                                                                          &flagOut);
                
                if(decodeStatus == kVTInvalidSessionErr) {
                    NSLog(@"IOS8VT: Invalid session, reset decoder session");
                } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                    NSLog(@"IOS8VT: decode failed status=%d(Bad data)", (int)decodeStatus);
                    
                } else if(decodeStatus != noErr) {
                    NSLog(@"IOS8VT: decode failed status=%d", (int)decodeStatus);
                    perror("decode failed, error:");
                }
                
                CFRelease(sampleBuffer);
            }
            CFRelease(blockBuffer);
        }
    }
    
    return outputPixelBuffer;
}

- (void)EndVideoToolBox
{
    if(mDecodeSession) {
        VTDecompressionSessionInvalidate(mDecodeSession);
        CFRelease(mDecodeSession);
        mDecodeSession = NULL;
    }
    
    if(mFormatDescription) {
        CFRelease(mFormatDescription);
        mFormatDescription = NULL;
    }
    
    free(mSPS);
    free(mPPS);
    mSPSSize = mPPSSize = 0;
}

@end
