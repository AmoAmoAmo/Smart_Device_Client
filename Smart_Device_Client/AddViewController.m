//
//  AddViewController.m
//  Smart_Device_Client
//
//  Created by Josie on 2017/9/18.
//  Copyright © 2017年 Josie. All rights reserved.
//
//  UDP搜索，5秒搜不到就退出搜索
//  一般应用中，硬件设备都会用到smart-config技术连接WIFI，此项目中只简单用UDP发广播搜索

#import "AddViewController.h"
#import "MBProgressHUD+HJ.h"

@interface AddViewController ()

@end

@implementation AddViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setUI];
}

#pragma mark - Methods
- (void)setUI
{
//    self.view.backgroundColor = [UIColor purpleColor];
    [self showHUD];
}

-(void)showHUD
{
    [MBProgressHUD showMessage:@"正在搜索设备中....."];
    
    // 几秒后消失,当然，这里可以改为网络请求
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 移除HUD
        [MBProgressHUD hideHUD];
        
        // 提醒有没有新数据
        [MBProgressHUD showError:@"没有新设备"];
    });
}


@end
