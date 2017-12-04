//
//  HJTCPClient.m
//  Smart_Device_Client
//
//  Created by Josie on 2017/9/19.
//  Copyright © 2017年 Josie. All rights reserved.
//
/*
 
 客户端：
 
    1、创建一个socket，用函数socket()；
 　　2、设置socket属性，用函数setsockopt();* 可选
 　　3、绑定IP地址、端口等信息到socket上，用函数bind();* 可选
 　　4、设置要连接的对方的IP地址和端口等属性；
 　　5、连接服务器，用函数connect()；
 　　6、收发数据，用函数send()和recv()，或者read()和write();
 　　7、关闭网络连接；
 */

#import "HJTCPClient.h"
#import "UnixInterfaceDefine.h"
#import "TCPSocketDefine.h"


pthread_mutex_t  mutex_cRecv=PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t  mutex_cSend=PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t  mutex_dRecv=PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t  mutex_dSend=PTHREAD_MUTEX_INITIALIZER;


@interface HJTCPClient()
{
    NSString *m_ipStr;                 // IP
    // 套接字描述符
    int             m_comdSockfd;                   // 命令套接字
    int             m_dataSockfd;                   // 数据通道套接字
    
    BOOL                        m_canRecvData;        // connect成功 并且登陆摄像头认证成功才可接收数据
    BOOL                        m_canRecvCommand;
}

@end

@implementation HJTCPClient

- (instancetype)init
{
    self = [super init];
    if (self) {
        m_canRecvData = false;
        m_canRecvCommand = false;
    }
    return self;
}

-(BOOL)startTCPConnectionWithData:(NSDictionary *)dataDic
{
    m_ipStr = dataDic[@"ip"];
    // 一般还会校验其他信息，此处省略 ...
    
    // 与摄像头认证、心跳包等的步骤省略，在本例中不是重点，实际应用中根据各自的业务逻辑去实现
    // 假设校验、连接已成功...
//    if (ret == 0) {
        // 发送音视频数据传输请求，告诉摄像头：需要数据
        // 开一个线程去做传输
        [NSThread detachNewThreadSelector:@selector(transmissionThread) toTarget:self withObject:nil];
//    }
    
    
    return false;
}

-(void)stopTCPConnect
{
    m_canRecvData = false;
    m_canRecvCommand = false;
    
    if(m_dataSockfd>0)
    {
        close(m_dataSockfd);
    }
    
    if(m_comdSockfd>0)
    {
        close(m_comdSockfd);
    }
}


-(void)transmissionThread
{
    //初始化数据通道Socket
    int ret = [self initDataSocketConnection];
    
    if (ret == 0) {        
        // ====== 请求 音视频数据 传输 数据通道 ======
        [self sendDataTransRequest];
        
        printf("------- 等待接收音视频数据 ---------\n");
        m_canRecvData = true;
        m_canRecvCommand = true;
        
        // 新开线程，在线程里一直在循环接收数据/命令，直到循环的开关(m_canRecvData)被关闭(-stopTCPConnect;)
        //一直接收数据（视频or音频）
        [NSThread detachNewThreadSelector:@selector(recvDataThread) toTarget:self withObject:nil];
    }
}



// 初始化数据通道Socket
- (int)initDataSocketConnection
{
    m_dataSockfd = socket(AF_INET,SOCK_STREAM,0);
    if( m_dataSockfd < 0)
    {
        printf("socket error! \n");
        return -1;
    }
    printf("\n\n--- socketfd = %d \n",m_dataSockfd);
    
    // 设置要连接的对方的IP地址和端口等属性；
    const char *ipString = [m_ipStr UTF8String]; // NSString 转化为 char *
    struct sockaddr_in serveraddr = {0};
    serveraddr.sin_family = AF_INET;                // ipv4
    serveraddr.sin_port = htons(SERVER_PORT);       // 端口号 h(ost) to n(et),电脑转网络, s(hort)
    serveraddr.sin_addr.s_addr = htons(INADDR_ANY); // IP地址
    
    
    if(inet_pton(AF_INET,ipString,&serveraddr.sin_addr.s_addr)<=0)// inet_pton：将“点分十进制” －> “二进制整数”
    {
        printf("inet_pton error!!!\n");
        return -3;
    }
    
    
    //2.连接服务器
    int retConn=connect(m_dataSockfd, ( struct sockaddr*)&serveraddr, sizeof( struct sockaddr));
    if (retConn < 0) {
        perror("-- tcp - Socket -  - 连接失败");
        // hud
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"dev_off_line" object:nil];
//        });
        
        return -1;
    }
    printf("Socket -  - Connect Result:%d\n",retConn);
    
    // 设置阻塞模式
    int flags1 = fcntl(m_dataSockfd, F_GETFL, 0);
    fcntl(m_dataSockfd, F_SETFL, flags1 &( ~O_NONBLOCK));
    
    
    struct timeval timeout = {10,0};
    
    if(setsockopt(m_dataSockfd, SOL_SOCKET, SO_SNDTIMEO, (const char *)&timeout, sizeof(struct timeval)))
    {
        return -1;
    }
    if(setsockopt(m_dataSockfd, SOL_SOCKET, SO_RCVTIMEO, (const char *)&timeout, sizeof(struct timeval) ))
    {
        return -1;
    }
    
    printf("Socket -  - 初始化结束.........\n\n");
    
    return 0;
}


- (BOOL)sendDataTransRequest
{
    printf("....数据 请求传输开始 .......\n");
    
    HJ_VideoAndAudioDataRequest request;
    memset(&request, 0, sizeof(request));
    
    request.msgHeader.protocolHeader[0]='H';
    request.msgHeader.protocolHeader[1]='M';
    request.msgHeader.protocolHeader[2]='_';
    request.msgHeader.protocolHeader[3]='D';
    
    request.msgHeader.controlMask = CODECONTROLL_DATATRANS_REQUEST;
    request.msgHeader.contentLength=4;

    int sendLength = sizeof(request);
    
    
//    // 打印结构体
//    char *tempBuf = (char *)malloc(sizeof(request));
//    memcpy(tempBuf, &request, sizeof(request));
//    for (int i = 0; i < sizeof(request); i++) {
//        printf("%02x", tempBuf[i]);
//    }
//    printf("\n");
    
    if([self sendDataSocketData:(char*)&request dataLength:sendLength]){
        return true;
    }
    
    return false;
}


//一直接收数据（视频or音频）
-(void)recvDataThread
{
    while (m_canRecvData) {
        
        // 不知道是什么类型的数据
        HJ_MsgHeader msgHeader;
        memset(&msgHeader, 0, sizeof(msgHeader));
        // 读包头
//        printf("---- sizeof(msgHeader) = %d\n", (int)sizeof(msgHeader));
        if (![self recvDataSocketData:(char *)&msgHeader dataLength:sizeof(msgHeader)])
        {
            return;
        }
        char tempMsgHeader[5]={0};
        memcpy(tempMsgHeader, &msgHeader.protocolHeader, sizeof(tempMsgHeader));
        memset(tempMsgHeader+4, 0, 1);
        
        NSString* headerStr=[NSString stringWithCString:tempMsgHeader encoding:NSASCIIStringEncoding];
        if ([headerStr compare:@"HM_D"] == NSOrderedSame) {
            
            // 视频数据
            if(msgHeader.controlMask == CODECONTROLL_VIDEOTRANS_REPLY )
            {
                HJ_VideoDataContent dataContent;
                memset(&dataContent, 0, sizeof(dataContent));
//                printf("----- sizeof(dataContent) = %d\n",(int)sizeof(dataContent));
                if([self recvDataSocketData:(char*)&dataContent dataLength:sizeof(dataContent)])
                {
                    // ---- 来一份数据就向缓冲里追加一份 ----
                    
                    const size_t kRecvBufSize = 204800;
                    char* buf = (char*)malloc(kRecvBufSize * sizeof(char));
                    

                    int dataLength = dataContent.videoLength;
                    printf("------ struct video len = %d\n",dataLength);
                    
                    if([self recvDataSocketData:(char*)buf dataLength:dataLength])
                    {
                        
                        // 接收到视频,
                        //解码 ---> OpenGL ES渲染
                        //
                        if ([_delegate respondsToSelector:@selector(recvVideoData:andDataLength:)]) {
                            //
                            [_delegate recvVideoData:(unsigned char *)buf andDataLength:dataLength];
                        }
                        
                    }
                }
                
            }
            
            // 音频数据
            else if(msgHeader.controlMask==CONTROLLCODE_AUDIOTRANS_REPLY)
            {
                HJ_AudioDataContent dataContent;
                memset(&dataContent, 0, sizeof(dataContent));
//                printf("------ audio sizeof(dataContent) = %d \n",(int)sizeof(dataContent));
                if([self recvDataSocketData:(char*)&dataContent dataLength:sizeof(dataContent)])
                {
                    //音频数据Buffer
                    const size_t kRecvBufSize = 40000; // 1280
                    char* dataBuf = (char*)malloc(kRecvBufSize * sizeof(char));
                    
                    int audioLength=dataContent.dataLength;
//                    printf("---- audio audioLength = %d \n", audioLength);
                    if([self recvDataSocketData:dataBuf dataLength:audioLength])
                    {
                        //接收到音频以后的处理
                        if ([_delegate respondsToSelector:@selector(recvAudioData:andDataLength:)]) {
                            [_delegate recvAudioData:(unsigned char *)dataBuf andDataLength:audioLength];
                        }
                    }
                }
            }
        }
    }
}


#pragma mark - ********* socket 读写 *********

// sendSocketData
- (BOOL)sendDataSocketData:(char*)pBuf dataLength: (int)aLength
{
    // 打印结构体
    char *tempBuf = (char *)malloc(aLength);
    memcpy(tempBuf, pBuf, aLength);
    for (int i = 0; i < aLength; i++) {
        printf("%02x", tempBuf[i]);
    }
    printf("\n");
    
    
    signal(SIGPIPE, SIG_IGN);
    
    pthread_mutex_lock(&mutex_dSend);
    
    int sendLen=0;
    long nRet=0;
    
    while(sendLen<aLength)
    {
        if(m_dataSockfd>0)
        {
            nRet=send(m_dataSockfd,pBuf,aLength-sendLen,0);
            
            if(-1==nRet || 0==nRet)
            {
                pthread_mutex_unlock(&mutex_dSend);
                printf("cSocket send error\n");
                return false;
            }
            
            sendLen+=nRet;
            pBuf+=nRet;
            
            printf("发送了%d个字节\n",sendLen);
//            // 打印结构体
//            char *tempBuf = (char *)malloc(aLength);
//            memcpy(tempBuf, pBuf, aLength);
//            for (int i = 0; i < aLength; i++) {
//                printf("%02x", tempBuf[i]);
//            }
//            printf("\n");
        }
        else
        {
            printf("dSocket fd error %d\n",m_dataSockfd);
            pthread_mutex_unlock(&mutex_dSend);
            return false;
        }
        
    }
    
    pthread_mutex_unlock(&mutex_dSend);
    
    return true;
}

- (BOOL)recvDataSocketData: (char*)pBuf dataLength: (int)aLength
{
    signal(SIGPIPE, SIG_IGN);  // 防止程序收到SIGPIPE后自动退出
    
    pthread_mutex_lock(&mutex_dRecv);
    
    int recvLen=0;
    long nRet=0;
//    printf("------ aLength = %d -------\n", aLength);
    while(recvLen<aLength)
    {
        nRet=recv(m_dataSockfd,pBuf,aLength-recvLen,0);
        
        if(-1==nRet || 0==nRet)
        {
            pthread_mutex_unlock(&mutex_dRecv);
            printf("DSocket recv error\n\n");
            return false;
        }
        recvLen+=nRet;
        pBuf+=nRet;
        
        printf("接收了%d个字节,\n\n",recvLen);

    }
    
    pthread_mutex_unlock(&mutex_dRecv);
    
    return true;
}

@end
















