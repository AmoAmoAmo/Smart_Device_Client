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


#define PLAYVIEW_PORTRAIT_STARTX    0
#define PLAYVIEW_PORTRAIT_STARTY    (SCREENHEIGHT - SCREENWIDTH * (480 / 640.0)) / 2.0
#define PLAYVIEW_PORTRAIT_WIDTH     SCREENWIDTH
#define PLAYVIEW_PORTRAIT_HEIGHT    SCREENWIDTH * (480 / 640.0)

//#define PLAYVIEW_LANDSCAPE_STARTX    0


@interface CameraViewController ()<RecvVideoDataDelegate>

@property (nonatomic, retain) HJTCPClient *client;

@property (nonatomic, retain) HJH264Decoder *decoder;

@property (nonatomic, strong) HJOpenGLView  *playView;

@property (nonatomic, strong) UILabel *byteLabel;       // 网速label

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign)   int  videoLength;

@property (nonatomic, strong) UIButton *fullBtn;        // 全屏按钮

@property (nonatomic, strong) UIView *btnBarView;

//@property (nonatomic, assign) BOOL isFullScreen;

@end

@implementation CameraViewController

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
//    _isFullScreen = false;
    
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
    
    // 开一个线程去创建计时器，记得要在该子线程中 使用自线程的runloop，否则计时器跑不起来
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
}


-(void)showHUD
{
    [MBProgressHUD showMessage:@"初始化..."];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 移除HUD
        [MBProgressHUD hideHUD];

    });
}


-(void)buildPlayerUI
{
    [self.view addSubview:self.btnBarView];
    [self.btnBarView addSubview:self.byteLabel];
    [self.btnBarView addSubview:self.fullBtn];
    
    
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
        self.byteLabel.text = [NSString stringWithFormat:@"%.1f KB/s",_videoLength / 1024.0];
    });
}


#pragma mark - RecvVideoDataDelegate - 收到H264视频数据 并进行解码

-(void)recvVideoData:(char *)videoData andDataLength:(int)length
{
    _videoLength = length;
    
    
    // 解码
    [self.decoder startH264DecodeWithVideoData:videoData andLength:length andReturnDecodedData:^(CVPixelBufferRef pixelBuffer) {
        
        //
//        printf("-------- 解码后的数据： --------\n");
//        unsigned char * tempData = (unsigned char *)videoData;
//        for (int i = 0; i < length; i++) {
//            printf("%02x", tempData[i]);
//        }
//        printf("\n");
        
       // OpenGL渲染
        [self.playView displayPixelBuffer:pixelBuffer];
    }];
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
        _fullBtn.frame = CGRectMake(SCREENWIDTH - 40 - 10, 5, 40, 40);
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

@end
