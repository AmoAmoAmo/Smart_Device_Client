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

@interface CameraViewController ()

@property (nonatomic, retain) HJTCPClient *client;

@end

@implementation CameraViewController

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 从沙盒中读取数据
    //获取本地沙盒路径
    NSArray *pathArr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //获取完整路径
    NSString *documentsPath = [pathArr objectAtIndex:0];
    NSString *path = [documentsPath stringByAppendingPathComponent:@"DevicesList.plist"];
    //沙盒文件中的内容（arr）
    NSArray *docArr = [NSArray arrayWithContentsOfFile:path];
    NSDictionary *dic = docArr[self.index];
    
    // ------ TCP -----
    self.client = [[HJTCPClient alloc] init];
    [self.client startTCPConnectionWithData:dic];
    
    // HUD
    [self showHUD];
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



@end
