//
//  CameraViewController.m
//  Smart_Device_Client
//
//  Created by Josie on 2017/9/18.
//  Copyright © 2017年 Josie. All rights reserved.
//

#import "CameraViewController.h"
#import "HJTCPClient.h"
#import "MBProgressHUD+HJ.h"
#import "HJH264Decoder.h"
#import "HJOpenGLView.h"
#import "HeaderDefine.h"
#import "AACPlayer.h"


#define PLAYVIEW_PORTRAIT_STARTX    0
#define PLAYVIEW_PORTRAIT_STARTY    (SCREENHEIGHT - SCREENWIDTH * (480 / 640.0)) / 2.0
#define PLAYVIEW_PORTRAIT_WIDTH     SCREENWIDTH
#define PLAYVIEW_PORTRAIT_HEIGHT    SCREENWIDTH * (480 / 640.0)

//#define PLAYVIEW_LANDSCAPE_STARTX    0
#define BTN_MARGIN                  10      // 按钮之间的间隔
#define BTN_WIDTH                   40      // 按钮宽度

@interface CameraViewController ()<RecvDataDelegate>

@property (nonatomic, retain) HJTCPClient *client;

@property (nonatomic, retain) HJH264Decoder *decoder;

@property (nonatomic, strong) HJOpenGLView  *playView;

@property (nonatomic, strong) UILabel *byteLabel;       // 网速label

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign)   int  speedLength;

@property (nonatomic, strong) UIButton *deleteBtn;      // 删除设备按钮

@property (nonatomic, strong) UIButton *fullBtn;        // 全屏按钮

@property (nonatomic, strong) UIButton *audioBtn;       // 音频播放/暂停 按钮

@property (nonatomic, strong) UIButton *videoBtn;       // 视频播放/暂停 按钮

@property (nonatomic, assign) BOOL  videoIsStop;        // 记录 视频是否在暂停的状态

@property (nonatomic, strong) UIView *btnBarView;

@property (nonatomic, strong) AACPlayer *aacPlayer;

//@property (nonatomic,strong) UIAlertView *alertView;


@end

@implementation CameraViewController

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.aacPlayer = [[AACPlayer alloc] init];
    _speedLength = 0;
    self.videoIsStop = false;
    
    // 从沙盒中读取数据
    NSArray *pathArr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [pathArr objectAtIndex:0];
    NSString *path = [documentsPath stringByAppendingPathComponent:@"DevicesList.plist"];
    NSArray *docArr = [NSArray arrayWithContentsOfFile:path];
    NSDictionary *dic = docArr[self.index];
    
    // ------ TCP -----
    self.client = [[HJTCPClient alloc] init];
    self.client.delegate = self;
    [self.client startTCPConnectionWithData:dic];
    
    // HUD
    [self showHUD];
    
    // 开一个线程去创建计时器，记得要在该子线程中 使用子线程的runloop，否则计时器跑不起来
    [NSThread detachNewThreadSelector:@selector(creatTimer) toTarget:self withObject:nil];
    
    // playView
    [self.view addSubview:self.playView];
    self.playView.frame = CGRectMake(PLAYVIEW_PORTRAIT_STARTX, PLAYVIEW_PORTRAIT_STARTY, PLAYVIEW_PORTRAIT_WIDTH, PLAYVIEW_PORTRAIT_HEIGHT);
//    NSLog(@"-- %d, %f, %f, %f",PLAYVIEW_PORTRAIT_STARTX, PLAYVIEW_PORTRAIT_STARTY, PLAYVIEW_PORTRAIT_WIDTH, PLAYVIEW_PORTRAIT_HEIGHT);
    [self.playView setupGL];
    
    // 设置播放器上的按钮UI
    [self buildPlayerUI];
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor blackColor];
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat margin = 4.5;
    backBtn.frame = CGRectMake(16+margin, 24+margin, 40-2*margin, 40-2*margin);
    [backBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(clickBackBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backBtn];
    
    [self.view addSubview:self.deleteBtn];
    
    // 通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showDevOffLineHUD) name:@"dev_off_line" object:nil];
    
}


-(void)clickDeleteBtn
{
//    NSLog(@"delete........");
    //显示提示框
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                   message:@"确定删除该设备信息？"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"删除"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              //响应事件                                                              
                                                              [self removePlistDeviceData];
                                                              
                                                              
                                                          }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             //响应事件
                                                         }];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
    
    
}

-(void)clickBackBtn
{
    [self.client stopTCPConnect];
    [self.decoder stopH264Decode];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)clickFullBtn
{
    // 切换全屏
    self.fullBtn.selected = !self.fullBtn.selected;
    if (self.fullBtn.selected) {
        // 全屏
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationLandscapeRight] forKey:@"orientation"];
        [self.playView setFrame:CGRectMake(0, 0, SCREENWIDTH, SCREENHEIGHT)];
        [self.btnBarView setFrame:CGRectMake(0, 0, SCREENWIDTH, 50)];
        
    }else{
        // 退出全屏
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait] forKey:@"orientation"];
        [self.playView setFrame:CGRectMake(PLAYVIEW_PORTRAIT_STARTX, PLAYVIEW_PORTRAIT_STARTY, PLAYVIEW_PORTRAIT_WIDTH, PLAYVIEW_PORTRAIT_HEIGHT)];
        [self.btnBarView setFrame:CGRectMake(0, 64, SCREENWIDTH, 50)];
        
    }
    // btnBarView 的子视图要重设frame
    self.fullBtn.frame = CGRectMake(SCREENWIDTH - BTN_WIDTH - BTN_MARGIN, 5, BTN_WIDTH, BTN_WIDTH);
    self.audioBtn.frame = CGRectMake(SCREENWIDTH - (BTN_WIDTH + BTN_MARGIN)*2, 5, BTN_WIDTH, BTN_WIDTH);
    self.videoBtn.frame = CGRectMake(SCREENWIDTH - (BTN_WIDTH + BTN_MARGIN)*3, 5, BTN_WIDTH, BTN_WIDTH);
}

-(void)clickAudioBtn
{
    self.audioBtn.selected = !self.audioBtn.selected;
    if (self.audioBtn.selected) {
        // 静音
        printf("-------- 静音 -----\n");
        [self.aacPlayer audioPause];
    }else{
        // 非静音
        printf("-------- 播放 -----\n");
        [self.aacPlayer audioStart];
    }
    
}

-(void)clickVideoBtn
{
    self.videoBtn.selected = !self.videoBtn.selected;
    // 视频的暂停与播放，根据是否向displayPixelBuffer里传数据
    if (self.videoBtn.selected) {
        // 暂停
        self.videoIsStop = true;
    }else{
        // 播放
        self.videoIsStop = false;
    }
}


-(void)removePlistDeviceData
{
    // 从沙盒中删除
    //获取本地沙盒路径
    NSArray *pathArr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //获取完整路径
    NSString *documentsPath = [pathArr objectAtIndex:0];
    NSString *path = [documentsPath stringByAppendingPathComponent:@"DevicesList.plist"];
    //沙盒文件中的内容（arr）
    //    NSArray *docArr = [NSArray arrayWithContentsOfFile:path];
    NSMutableArray *arr = [NSMutableArray arrayWithContentsOfFile:path];
    [arr removeObjectAtIndex:self.index];
    [arr writeToFile:path atomically:YES];
    
    
    //
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateHomeUI" object:nil];
    //
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)showHUD
{
    [MBProgressHUD showMessage:@"初始化..."];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 移除HUD
        [MBProgressHUD hideHUD];

    });
}
-(void)showDevOffLineHUD
{
    // 显示设备已离线
    [MBProgressHUD showError:@"设备已离线"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUD];
    });
    
}


-(void)buildPlayerUI
{
    [self.view addSubview:self.btnBarView];
    [self.btnBarView addSubview:self.byteLabel];
    [self.btnBarView addSubview:self.fullBtn];
    [self.btnBarView addSubview:self.audioBtn];
    [self.btnBarView addSubview:self.videoBtn];
}

-(void)creatTimer
{
    _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateByteLabelText) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] run];
}
// 每1秒(计时器)更新一下byteLabel：
-(void)updateByteLabelText
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.byteLabel.text = [NSString stringWithFormat:@"%.1f KB/s",_speedLength / 1024.0];
        // 清空_videoLength
        _speedLength = 0;
    });
}


#pragma mark - RecvDataDelegate - 收到H264视频数据 并进行解码

-(void)recvVideoData:(unsigned char *)videoData andDataLength:(int)length
{
    // 累加1秒内所有数据包的大小
    _speedLength += length;
//    _speedLength = length;
    printf("----- recved len = %d \n", length);
    
    // 解码
    [self.decoder startH264DecodeWithVideoData:(char *)videoData andLength:length andReturnDecodedData:^(CVPixelBufferRef pixelBuffer) {
        
       // OpenGL渲染
        if (!self.videoIsStop) {
            [self.playView displayPixelBuffer:pixelBuffer];
        }
    }];
}

-(void)recvAudioData:(unsigned char *)audioData andDataLength:(int)length
{
    // 开始播放音频 (必须在主线程刷新)
    if (!self.audioBtn.selected) {
        printf("***********************\n");
        [self.aacPlayer playAudioWithData:(char *)audioData andLength:length];
    }
    
}














#pragma mark - 懒加载
-(HJH264Decoder *)decoder
{
    if (!_decoder) {
        _decoder = [[HJH264Decoder alloc] init];
    }
    return _decoder;
}

-(HJOpenGLView *)playView
{
    if (!_playView) {
        _playView = [[HJOpenGLView alloc] init];
    }
    return _playView;
}

-(UILabel *)byteLabel
{
    if (!_byteLabel) {
        _byteLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 100, 30)];
        [_byteLabel setTextColor:[UIColor whiteColor]];
        [_byteLabel setTextAlignment:NSTextAlignmentRight];
        _byteLabel.text = @"0 KB/s";
    }
    return _byteLabel;
}

-(UIButton *)fullBtn
{
    if (!_fullBtn) {
        _fullBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _fullBtn.frame = CGRectMake(SCREENWIDTH - BTN_WIDTH - BTN_MARGIN, 5, BTN_WIDTH, BTN_WIDTH);
        [_fullBtn setImage:[UIImage imageNamed:@"全屏"] forState:UIControlStateNormal];
        [self.fullBtn setImage:[UIImage imageNamed:@"退出全屏"] forState:UIControlStateSelected];
        [_fullBtn addTarget:self action:@selector(clickFullBtn) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _fullBtn;
}

-(UIView *)btnBarView
{
    if (!_btnBarView) {
        _btnBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, SCREENWIDTH, 50)];
        _btnBarView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    }
    return _btnBarView;
}

-(UIButton *)audioBtn
{
    if (!_audioBtn) {
        _audioBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _audioBtn.frame = CGRectMake(SCREENWIDTH - (BTN_WIDTH + BTN_MARGIN)*2, 5, BTN_WIDTH, BTN_WIDTH);
        [_audioBtn setImage:[UIImage imageNamed:@"非静音"] forState:UIControlStateNormal];
        [_audioBtn setImage:[UIImage imageNamed:@"静音"] forState:UIControlStateSelected];
        [_audioBtn addTarget:self action:@selector(clickAudioBtn) forControlEvents:UIControlEventTouchUpInside];
        // 开始为静音的状态
        _audioBtn.selected = true;
    }
    return _audioBtn;
}

-(UIButton *)videoBtn
{
    if (!_videoBtn) {
        _videoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _videoBtn.frame = CGRectMake(SCREENWIDTH - (BTN_WIDTH + BTN_MARGIN)*3, 5, BTN_WIDTH, BTN_WIDTH);
        [_videoBtn setImage:[UIImage imageNamed:@"暂停"] forState:UIControlStateNormal];
        [_videoBtn setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateSelected];
        [_videoBtn addTarget:self action:@selector(clickVideoBtn) forControlEvents:UIControlEventTouchUpInside];
    }
    return _videoBtn;
}


-(UIButton *)deleteBtn
{
    if (!_deleteBtn) {
        _deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat btnWidth = 34;
        _deleteBtn.frame = CGRectMake(SCREENWIDTH-btnWidth-20, 27, btnWidth, btnWidth);
        [_deleteBtn setImage:[UIImage imageNamed:@"删除 (1)"] forState:UIControlStateNormal];
        [_deleteBtn addTarget:self action:@selector(clickDeleteBtn) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteBtn;
}

@end







