//
//  UDPSearchDefine.h
//  IntelliDev
//
//  Created by Josie on 2017/5/27.
//  Copyright © 2017年 Josie. All rights reserved.
//
//  嵌入式工程师给的协议头

#ifndef LocalSearchDefine_h
#define LocalSearchDefine_h

#define     INT8        unsigned char
#define     INT16       unsigned short
#define     INT32       unsigned int

static const INT16 CONTROLLCODE_SEARCH_BROADCAST_REQUEST    = 0;  // 广播请求操作码
static const INT16 CONTROLLCODE_SEARCH_BROADCAST_REPLY      = 1;  // 广播回应操作码

// Big2Little16 大端转小端
#define Big2Little16(A)  ((((unsigned short)(A) & 0xff00) >> 8) | \
(((unsigned short)(A) & 0x00ff) << 8))
#define Big2Little32(A)  ((((unsigned int)(A) & 0xff000000) >> 24) | \
(((unsigned int)(A) & 0x00ff0000) >> 8) | \
(((unsigned int)(A) & 0x0000ff00) << 8) | \
(((unsigned int)(A) & 0x000000ff) << 24))



#define SERVER_PORT 20001  // 发送端口   服务器开放给我们的端口号


// 结构体1字节对齐
#pragma pack(push, 1)

typedef struct searchMsgHeader
{
    char            protocolHeader[4];   //协议头  4  // HM_S
    short           controlMask;         //操作码  2

}HJ_SearchMsgHeader;



// 服务器的回应
typedef struct searchReply
{
    HJ_SearchMsgHeader  header;             //头部
    short               devID;              //设备ID
    short               type;
    unsigned int        IP;                 //IP; 大端
    unsigned short      port;               //端口 大端
    
}HJ_SearchReply;

#pragma pack(pop)


#endif /* LocalSearchDefine_h */






