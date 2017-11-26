//
//  HJUDPSearchClient.m
//  Smart_Device_Client
//
//  Created by Josie on 2017/9/19.
//  Copyright © 2017年 Josie. All rights reserved.
//

#import "HJUDPSearchClient.h"
#import "UnixInterfaceDefine.h"
#import "UDPSearchDefine.h"

@interface HJUDPSearchClient()
{
    int                 m_sockfd;
    struct sockaddr_in  m_serveraddr;   // 服务器地址
    
    NSDictionary        *m_dataDic;
}
@property (nonatomic, assign) BOOL recvSignal;

@end

@implementation HJUDPSearchClient

- (instancetype)init
{
    self = [super init];
    if (self) {
        m_sockfd = -1;
        self.recvSignal = true;
        m_dataDic = [NSDictionary dictionary];
    }
    return self;
}

-(int)startUDPSearchWithBlock:(ReturnDataWithStopSearchBlock)block
{
    self.returnDataBlock = block;
    self.recvSignal = true;
    
    // -------------- 1. socket -------------
    m_sockfd = socket(AF_INET, SOCK_DGRAM, 0);
//    NSLog(@"startUDPSearch ======= , %d", m_sockfd);
    if (m_sockfd == -1) {
        perror("socket: error\n");
        return -1;
    }
    
    // ---- 2-1. 向服务端地址发送数据广播：---limited broadcast,广播地址是255.255.255.255, 需要做一个SetSockopt():
    int broadCast = 1;
    setsockopt(m_sockfd, SOL_SOCKET, SO_BROADCAST, &broadCast, sizeof(int));
    
    m_serveraddr.sin_family = AF_INET;
    m_serveraddr.sin_addr.s_addr = INADDR_BROADCAST; // 255.255.255.255
    m_serveraddr.sin_port = htons(SERVER_PORT);  // htons 将整型变量从主机字节顺序转变成网络字节顺序，即小端转大端
    
    // 开一个线程 去执行搜索的功能
    [NSThread detachNewThreadSelector:@selector(startSearchingThread) toTarget:self withObject:nil];
    printf("startUDPSearch, socketfd = %d.......\n",m_sockfd);
    
    return 0;
}

-(void)stopUDPSearch
{
    self.recvSignal = false;
    close(m_sockfd);
    m_sockfd = -1;
    m_dataDic = nil;
}



#pragma mark - Methods

- (void)startSearchingThread
{
    // 清空数据源
    if (m_dataDic) {
        m_dataDic = [NSDictionary dictionary];
    }
    
    // 搜索 先发一个广播包。向局域网端口广播 UDP, 手机发一个广播包 给嵌入式设备，设备才会去做响应
    [self sendSearchBroadCast];
    
    // 嵌入式设备收到广播 返回 IP地址 端口，设备信息
    usleep(1 * 1000); // //停留1毫秒
    [self recvDataAndProcess];
    
    //回调函数，自动更新到UI.
    self.returnDataBlock(m_dataDic);
    
    
    
}

// 发送广播包
-(BOOL)sendSearchBroadCast
{
    printf("发送广播包.......\n");
    
    HJ_SearchMsgHeader msgHeader;
    memset(&msgHeader, 0, sizeof(msgHeader));
    int headLength = sizeof(msgHeader);
    
    msgHeader.protocolHeader[0] = 'H';
    msgHeader.protocolHeader[1] = 'M';
    msgHeader.protocolHeader[2] = '_';
    msgHeader.protocolHeader[3] = 'S';
    msgHeader.controlMask = CONTROLLCODE_SEARCH_BROADCAST_REQUEST;

    if ([self sendData:(char *)&msgHeader length:headLength]) {
        return true;
    }
    
    return false;
}

-(BOOL)sendData:(char*)pBuf length:(int)length
{
    int sendLen = 0;
    ssize_t nRet = 0;
    socklen_t addrlen = 0;
    
    addrlen = sizeof(m_serveraddr);
    while (sendLen < length) {
        nRet = sendto(m_sockfd, pBuf, length, 0, (struct sockaddr*)&m_serveraddr, addrlen);
        
        if (nRet == -1) {
            perror("sendto error:\n");
            return false;
        }
        printf("发送了%ld个字符\n", nRet);
        sendLen += nRet;
        pBuf += nRet;
    }
    return true;
}

-(BOOL)recvData:(char*)pBuf length:(int)length
{
    int readLen=0;
    long nRet=0;
    socklen_t addrlen = sizeof(m_serveraddr);
    
    while(readLen<length)
    {
        nRet=recvfrom(m_sockfd,pBuf,length-readLen,0,(struct sockaddr*)&m_serveraddr,(socklen_t*)&addrlen);// 一直在搜索 阻塞，直到 接收到服务器的回复，即搜索到设备
        
        if(nRet==-1){
            perror("recvfrom error: \n");
            return false;
        }
        readLen+=nRet;
        pBuf+=nRet;
    }
    return true;
}

-(void)recvDataAndProcess
{
    HJ_SearchReply searchReply;
    memset (&searchReply,0,sizeof(searchReply));
    
    if ([self recvData:(char *)&searchReply length:sizeof(searchReply)]) {
        
        if (searchReply.header.controlMask==CONTROLLCODE_SEARCH_BROADCAST_REPLY) {

            NSString *tempIPString = [NSString stringWithFormat:@"%s",inet_ntoa(m_serveraddr.sin_addr)];
            NSString *tempPortString = [NSString stringWithFormat:@"%d",htons(m_serveraddr.sin_port)];
            NSString *typeStr = [NSString stringWithFormat:@"%d",searchReply.type];
            NSString *idStr = [NSString stringWithFormat:@"%d",searchReply.devID];
            
            // 添加到数据源
            m_dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                         tempIPString,  @"key_ip",
                         tempPortString,@"key_port",
                         typeStr,       @"key_type",
                         idStr,         @"key_id",nil];
//            NSLog(@"--- %@ ---- %@", m_dataDic[@"key_ip"],m_dataDic[@"key_port"]);
        }
    }
}




@end


















