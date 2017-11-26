//
//  AACPlayer.m
//  Audio_Client
//
//  Created by Josie on 2017/10/11.
//  Copyright © 2017年 Josie. All rights reserved.
//

#import "AACPlayer.h"
#import <netdb.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>
#include <pthread.h>

#define PRINTERROR(LABEL)	printf("%s err %4.4s %d\n", LABEL, (char *)&err, err)

const unsigned int kNumAQBufs = 3;			// audio queue buffers 数量
const size_t kAQBufSize = 128 * 1024;		// buffer 的大小 单位是字节
const size_t kAQMaxPacketDescs = 512;		// ASPD的最大数量
BOOL canPlay;  // 音频播放的开关

struct MyData
{
    AudioFileStreamID audioFileStream;	// the audio file stream parser
    
    AudioQueueRef audioQueue;								// the audio queue
    AudioQueueBufferRef audioQueueBuffer[kNumAQBufs];		// audio queue buffers
    
    AudioStreamPacketDescription packetDescs[kAQMaxPacketDescs];	// packet descriptions for enqueuing audio
    
    unsigned int fillBufferIndex;	// the index of the audioQueueBuffer that is being filled
    size_t bytesFilled;				// how many bytes have been filled
    size_t packetsFilled;			// how many packets have been filled
    
    bool inuse[kNumAQBufs];			// flags to indicate that a buffer is still in use
    bool started;					// flag to indicate that the queue has been started
    bool failed;					// flag to indicate an error occurred
    
    pthread_mutex_t mutex;			// a mutex to protect the inuse flags
    pthread_cond_t cond;			// a condition varable for handling the inuse flags
    pthread_cond_t done;			// a condition varable for handling the inuse flags
};
typedef struct MyData MyData;

@interface AACPlayer()
{
    MyData* myData;
}

@end

@implementation AACPlayer


- (instancetype)init
{
    self = [super init];
    if (self) {
        canPlay = true;
        [self initBasic];
    }
    return self;
}

-(int)initBasic
{
    // allocate a struct for storing our state
    myData = (MyData*)calloc(1, sizeof(MyData));
    
    // initialize a mutex and condition so that we can block on buffers in use.
    pthread_mutex_init(&myData->mutex, NULL);
    pthread_cond_init(&myData->cond, NULL);
    pthread_cond_init(&myData->done, NULL);
    
    
    // 创建音频文件流分析器
    OSStatus err = AudioFileStreamOpen(myData,
                                       MyPropertyListenerProc,
                                       MyPacketsProc,
                                       kAudioFileAAC_ADTSType,
                                       &myData->audioFileStream);
    if (err)
    {
        PRINTERROR("AudioFileStreamOpen");
//        free(buf);
        return 1;
    }
    return 0;
}

-(void)playAudioWithData:(char *)pBuf andLength:(ssize_t)length
{
    // 解析数据. 将会调用 MyPropertyListenerProc 和 MyPacketsProc
    OSStatus err = AudioFileStreamParseBytes(myData->audioFileStream,
                                    (UInt32)length,
                                    pBuf,
                                    0);
    if (err)
    {
        PRINTERROR("AudioFileStreamParseBytes");
    }
}


void MyPropertyListenerProc(void *							inClientData,
                            AudioFileStreamID				inAudioFileStream,
                            AudioFileStreamPropertyID		inPropertyID,
                            UInt32 *						ioFlags)
{
    // this is called by audio file stream when it finds property values
    MyData* myData = (MyData*)inClientData;
    OSStatus err = noErr;
    
    printf("found property '%c%c%c%c'\n",   (char)(inPropertyID>>24)&255,
                                            (char)(inPropertyID>>16)&255,
                                            (char)(inPropertyID>>8)&255,
                                            (char)inPropertyID&255);
    
    switch (inPropertyID) {
        case kAudioFileStreamProperty_ReadyToProducePackets :   // 'redy'
        {
            // the file stream parser is now ready to produce audio packets.
            // get the stream format.
            AudioStreamBasicDescription asbd;
            UInt32 asbdSize = sizeof(asbd);
            err = AudioFileStreamGetProperty(inAudioFileStream,
                                             kAudioFileStreamProperty_DataFormat,
                                             &asbdSize,
                                             &asbd);
            if (err) { PRINTERROR("get kAudioFileStreamProperty_DataFormat"); myData->failed = true; break; }
            printf("------ get the stream format. -------\n");
            
            
            // create the audio queue
            err = AudioQueueNewOutput(&asbd,
                                      MyAudioQueueOutputCallback,
                                      myData,
                                      NULL, NULL, 0,
                                      &myData->audioQueue);
            if (err) { PRINTERROR("AudioQueueNewOutput"); myData->failed = true; break; }
            printf("------ create the audio queue -------\n");
            
            
            // allocate audio queue buffers
            for (unsigned int i = 0; i < kNumAQBufs; ++i) {
                err = AudioQueueAllocateBuffer(myData->audioQueue,
                                               kAQBufSize,
                                               &myData->audioQueueBuffer[i]);
                if (err) { PRINTERROR("AudioQueueAllocateBuffer"); myData->failed = true; break; }
                printf("------ allocate audio queue buffers ------\n");
            }
            
            
            // get the cookie size
            UInt32 cookieSize;
            Boolean writable;
            err = AudioFileStreamGetPropertyInfo(inAudioFileStream,
                                                 kAudioFileStreamProperty_MagicCookieData,
                                                 &cookieSize,
                                                 &writable);
            if (err) { PRINTERROR("info kAudioFileStreamProperty_MagicCookieData"); break; }
            printf("cookieSize %d\n", (unsigned int)cookieSize);
            
            // get the cookie data
            void* cookieData = calloc(1, cookieSize);
            err = AudioFileStreamGetProperty(inAudioFileStream,
                                             kAudioFileStreamProperty_MagicCookieData,
                                             &cookieSize,
                                             cookieData);
            if (err) { PRINTERROR("get kAudioFileStreamProperty_MagicCookieData"); free(cookieData); break; }
            printf("------ get the cookie data -------\n");
            
            
            // set the cookie on the queue.
            err = AudioQueueSetProperty(myData->audioQueue,
                                        kAudioQueueProperty_MagicCookie,
                                        cookieData,
                                        cookieSize);
            free(cookieData);
            if (err) { PRINTERROR("set kAudioQueueProperty_MagicCookie"); break; }
            printf("------ set the cookie on the queue ------\n");
            
            
            // listen for kAudioQueueProperty_IsRunning
            err = AudioQueueAddPropertyListener(myData->audioQueue,
                                                kAudioQueueProperty_IsRunning,
                                                MyAudioQueueIsRunningCallback,
                                                myData);
            if (err) {
                PRINTERROR("AudioQueueAddPropertyListener");
                myData->failed = true;
                break;
            }
            NSLog(@"------- listen for kAudioQueueProperty_IsRunning -----");
            break;
        }
    }
}
void MyPacketsProc(void *							inClientData,
                   UInt32							inNumberBytes,
                   UInt32							inNumberPackets,
                   const void *                     inInputData,
                   AudioStreamPacketDescription	*   inPacketDescriptions)
{
//    printf("----- MyPacketsProc is called -----\n");  // 一直在频繁地调用，直到
    
    // this is called by audio file stream when it finds packets of audio
    MyData* myData = (MyData*)inClientData;
    
    // the following code assumes we're streaming VBR data. for CBR data, you'd need another code branch here.
    
    for (int i = 0; i < inNumberPackets; ++i) {
        SInt64 packetOffset = inPacketDescriptions[i].mStartOffset;
        SInt64 packetSize   = inPacketDescriptions[i].mDataByteSize;
        
        // if the space remaining in the buffer is not enough for this packet, then enqueue the buffer.
        size_t bufSpaceRemaining = kAQBufSize - myData->bytesFilled;
        if (bufSpaceRemaining < packetSize) {
            printf("*********** 1 ************\n");
            MyEnqueueBuffer(myData);
            WaitForFreeBuffer(myData);
        }
        
        // 将数据复制到音频队列缓冲区
        AudioQueueBufferRef fillBuf = myData->audioQueueBuffer[myData->fillBufferIndex];
        memcpy((char*)fillBuf->mAudioData + myData->bytesFilled, (const char*)inInputData + packetOffset, packetSize);
        // fill out packet description
        myData->packetDescs[myData->packetsFilled] = inPacketDescriptions[i];
        myData->packetDescs[myData->packetsFilled].mStartOffset = myData->bytesFilled;
        // keep track of bytes filled and packets filled
        myData->bytesFilled += packetSize;
        myData->packetsFilled += 1;
        
        // if that was the last free packet description, then enqueue the buffer.
        size_t packetsDescsRemaining = kAQMaxPacketDescs - myData->packetsFilled;
        if (packetsDescsRemaining == 0) {
            NSLog(@"*********** 2 ************");
            MyEnqueueBuffer(myData);
            WaitForFreeBuffer(myData);
        }
    }
}

// 开始播放音频
OSStatus StartQueueIfNeeded(MyData* myData)
{
    
    OSStatus err = noErr;
    if (!myData->started && canPlay) {		// start the queue if it has not been started already
        
        err = AudioQueueStart(myData->audioQueue, NULL);
        if (err) {
            PRINTERROR("AudioQueueStart");
            myData->failed = true;
            return err;
        }
        myData->started = true;
        printf("started\n");
    }
    return err;
}

OSStatus MyEnqueueBuffer(MyData* myData)
{
    OSStatus err = noErr;
    myData->inuse[myData->fillBufferIndex] = true;		// set in use flag
    
    // enqueue buffer
    AudioQueueBufferRef fillBuf = myData->audioQueueBuffer[myData->fillBufferIndex];
    fillBuf->mAudioDataByteSize = (UInt32)myData->bytesFilled;
    err = AudioQueueEnqueueBuffer(myData->audioQueue, fillBuf, (UInt32)myData->packetsFilled, myData->packetDescs);
    if (err) { PRINTERROR("AudioQueueEnqueueBuffer"); myData->failed = true; return err; }
    
    StartQueueIfNeeded(myData);
    
    return err;
}


void WaitForFreeBuffer(MyData* myData)
{
    // go to next buffer
    if (++myData->fillBufferIndex >= kNumAQBufs) myData->fillBufferIndex = 0;
    myData->bytesFilled = 0;		// reset bytes filled
    myData->packetsFilled = 0;		// reset packets filled
    
    // wait until next buffer is not in use
    printf("WaitForFreeBuffer->lock\n");
    pthread_mutex_lock(&myData->mutex);
    while (myData->inuse[myData->fillBufferIndex]) {
        printf("... WAITING ...\n");
        pthread_cond_wait(&myData->cond, &myData->mutex);
    }
    pthread_mutex_unlock(&myData->mutex);
    printf("WaitForFreeBuffer->unlock\n");
}

int MyFindQueueBuffer(MyData* myData, AudioQueueBufferRef inBuffer)
{
    for (unsigned int i = 0; i < kNumAQBufs; ++i) {
        if (inBuffer == myData->audioQueueBuffer[i])
            return i;
    }
    return -1;
}


void MyAudioQueueOutputCallback(	void*					inClientData,
                                AudioQueueRef			inAQ,
                                AudioQueueBufferRef		inBuffer)
{
    // this is called by the audio queue when it has finished decoding our data.
    // The buffer is now free to be reused.
    MyData* myData = (MyData*)inClientData;
    
    unsigned int bufIndex = MyFindQueueBuffer(myData, inBuffer);
    
    if (bufIndex != -1) {
        // signal waiting thread that the buffer is free.
        printf("MyAudioQueueOutputCallback->lock\n");
        pthread_mutex_lock(&myData->mutex);
        myData->inuse[bufIndex] = false;
        pthread_cond_signal(&myData->cond);
        printf("MyAudioQueueOutputCallback->unlock\n");
        pthread_mutex_unlock(&myData->mutex);
    }
    
}

void MyAudioQueueIsRunningCallback(void*					inClientData,
                                   AudioQueueRef			inAQ,
                                   AudioQueuePropertyID     inID)
{
    MyData* myData = (MyData*)inClientData;
    
    UInt32 running;
    UInt32 size;
    OSStatus err = AudioQueueGetProperty(inAQ,
                                         kAudioQueueProperty_IsRunning,
                                         &running,
                                         &size);
    if (err) {
        PRINTERROR("get kAudioQueueProperty_IsRunning");
        return;
    }
    if (!running) {
        printf("MyAudioQueueIsRunningCallback->lock\n");
        pthread_mutex_lock(&myData->mutex);
        pthread_cond_signal(&myData->done);
        printf("MyAudioQueueIsRunningCallback->unlock\n");
        pthread_mutex_unlock(&myData->mutex);
    }
}





-(void)stop
{
    // enqueue last buffer
    MyEnqueueBuffer(myData);
    
    
    printf("flushing\n");
    // AudioQueueFlush ---> 重新设置解码器的解码状态
    OSStatus err = AudioQueueFlush(myData->audioQueue);
//    if (err) { PRINTERROR("AudioQueueFlush"); free(buf); return 1; }
    
    printf("stopping\n");
    err = AudioQueueStop(myData->audioQueue, false);
    
    
    
//    if (err) { PRINTERROR("AudioQueueStop"); free(buf); return 1; }
    
    printf("waiting until finished playing..\n");
    printf("start->lock\n");
    pthread_mutex_lock(&myData->mutex);
    pthread_cond_wait(&myData->done, &myData->mutex);
    printf("start->unlock\n");
    pthread_mutex_unlock(&myData->mutex);
    
    
    printf("done\n");
    
    // cleanup
//    free(buf);
    err = AudioFileStreamClose(myData->audioFileStream);
    err = AudioQueueDispose(myData->audioQueue, false);
//    close(connection_socket);
    free(myData);
}

//
-(void)audioPause
{
    // AudioQueuePause
    OSStatus err = noErr;
    if (myData->started) {		// pause the queue if it has been started already
//        err = AudioQueuePause(myData->audioQueue);
        err = AudioQueueStop(myData->audioQueue, true);
        if (err) {
            PRINTERROR("AudioQueueStart");
            myData->failed = true;
            
        }else{
            canPlay = false;
            myData->started = false;
            printf("paused\n");
        }
    }
}
-(void)audioStart
{
    canPlay = true;
//    StartQueueIfNeeded(myData);
}

@end







