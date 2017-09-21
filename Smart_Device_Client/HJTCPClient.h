//
//  HJTCPClient.h
//  Smart_Device_Client
//
//  Created by Josie on 2017/9/19.
//  Copyright © 2017年 Josie. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RecvVideoDataDelegate <NSObject>

-(void)recvVideoData:(char*)videoData andDataLength:(int)length; // 收到视频数据 进行解码

@end


@interface HJTCPClient : NSObject

@property (nonatomic, assign) id<RecvVideoDataDelegate> delegate;



-(BOOL)startTCPConnectionWithData:(NSDictionary*)dataDic; // 从沙盒中取出的数据
-(void)stopTCPConnect;

@end
