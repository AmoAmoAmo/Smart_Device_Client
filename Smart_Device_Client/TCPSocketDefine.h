//
//  TCPSocketDefine.h
//  Smart_Device_Client
//
//  Created by Josie on 2017/9/19.
//  Copyright © 2017年 Josie. All rights reserved.
//

#ifndef TCPSocketDefine_h
#define TCPSocketDefine_h

#include "HeaderDefine.h"

static INT16        CODECONTROLL_DATATRANS_REQUEST          =0;   // 数据请求
static INT16        CODECONTROLL_VIDEOTRANS_REPLY           =1;   // 视频
static INT16        CONTROLLCODE_AUDIOTRANS_REPLY           =2;   // 音频


#define SERVER_PORT 20001  // 发送端口   服务器开放给我们的端口号


#pragma pack(push, 1)


//      login时只需要发一个包头
typedef struct msgHeader
{
    unsigned char       protocolHeader[4];  // 协议头  HM_C 命令，HM_D 传数据
    short               controlMask;        // 操作码 :用来区分同一协议中的不同命令
    int                 contentLength;      // 正文长度-> 包后面跟的数据的长度
    
}HJ_MsgHeader;



//// 视频传输请求
//typedef struct videoTranslationRequest
//{
//    HJ_MsgHeader        msgHeader;
//    char                reserved;
//    
//}HJ_VideoTranslationRequest;
//
//
//
//// 视频传输响应命令
//typedef struct videoTranslationReply
//{
//    HJ_MsgHeader        msgHeader;
//    short               result;             // 0: 同意   2 超过最大连接数被拒绝
//    unsigned int        videoID;            // 当Result=0 并且之前没有进行因视频传输时，本字段才存在.用来标识数据连接的ID
//    
//}HJ_VideoTranslationReply;




// 数据传输请求 command
typedef struct videoAndAudioDataRequest
{
    HJ_MsgHeader        msgHeader;
    
}HJ_VideoAndAudioDataRequest;



// 视频正文
typedef struct videoDataContent
{
    unsigned int        timeStamp;          // 时间戳
    unsigned int        frameTime;          // 帧采集时间
    unsigned char       reserved;           // 保留
    unsigned int        videoLength;        // video帧 size
    
}HJ_VideoDataContent;



// 音频正文
typedef struct audioDataContent
{
    unsigned int        timeStamp;          // 时间戳
    unsigned int        collectTime;        // 采集时间
    char                audioFormat;        // 音频格式
    unsigned int        dataLength;         // 数据长度
    
}HJ_AudioDataContent;


// 报警
typedef struct alarmNotify
{
    char                alarmType;          //报警类型 0 停止 1 移动检测 2 外部报警
    
}HJ_AlarmNotify;



#pragma pack(pop)


#endif /* TCPSocketDefine_h */
