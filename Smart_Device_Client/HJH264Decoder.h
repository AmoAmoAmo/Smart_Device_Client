//
//  HJH264Decoder.h
//  Smart_Device_Client
//
//  Created by Josie on 2017/9/22.
//  Copyright © 2017年 Josie. All rights reserved.
//
//  视频解码

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

typedef void (^ReturnDecodedVideoDataBlock) (CVPixelBufferRef pixelBuffer);

@interface HJH264Decoder : NSObject

@property (nonatomic, copy) ReturnDecodedVideoDataBlock returnDataBlock;

-(void)startH264DecodeWithVideoData:(char *)videoData andLength:(int)length andReturnDecodedData:(ReturnDecodedVideoDataBlock)block;
-(void)stopH264Decode;

@end
