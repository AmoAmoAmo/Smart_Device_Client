//
//  HJTCPClient.h
//  Smart_Device_Client
//
//  Created by Josie on 2017/9/19.
//  Copyright © 2017年 Josie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HJTCPClient : NSObject

-(BOOL)startTCPConnectionWithData:(NSDictionary*)dataDic; // 从沙盒中取出的数据
-(void)stopTCPConnect;

@end
