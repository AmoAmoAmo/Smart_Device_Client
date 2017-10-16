//
//  HJTCPClient.h
//  Smart_Device_Client
//
//  Created by Josie on 2017/9/19.
//  Copyright © 2017年 Josie. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol RecvDataDelegate <NSObject>

-(void)recvVideoData:(unsigned char*)videoData andDataLength:(int)length; // 收到视频数据 进行解码
-(void)recvAudioData:(unsigned char *)audioData andDataLength:(int)length;

@end




@interface HJTCPClient : NSObject

@property (nonatomic, assign) id<RecvDataDelegate> delegate;



-(BOOL)startTCPConnectionWithData:(NSDictionary*)dataDic; // 从沙盒中取出的数据
-(void)stopTCPConnect;

@end
