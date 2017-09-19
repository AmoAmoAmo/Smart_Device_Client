//
//  HJUDPSearchClient.h
//  Smart_Device_Client
//
//  Created by Josie on 2017/9/19.
//  Copyright © 2017年 Josie. All rights reserved.
//


#import <Foundation/Foundation.h>

typedef void(^ReturnDataWithStopSearchBlock)(NSDictionary *dataDic); // 搜索到的数据用dic保存

@interface HJUDPSearchClient : NSObject

@property (nonatomic, copy) ReturnDataWithStopSearchBlock returnDataBlock;


-(int)startUDPSearchWithBlock:(ReturnDataWithStopSearchBlock)block;
//-(int)sendAddedMsgToServer;
-(void)stopUDPSearch;

@end
