//
//  OtherViewController.m
//  Smart_Device_Client
//
//  Created by Josie on 2017/9/18.
//  Copyright © 2017年 Josie. All rights reserved.
//

#import "OtherViewController.h"
#import "HeaderDefine.h"
@interface OtherViewController ()

@end

@implementation OtherViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(80, 80, 80, 40)];
    label1.text = @"电源";
    label1.textColor = [UIColor whiteColor];
    [self.view addSubview:label1];
    
    UISwitch *switch1 = [[UISwitch alloc] initWithFrame:CGRectMake(180, 80, 80, 40)];
    [self.view addSubview:switch1];
    
    
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(50, 180, SCREENWIDTH-100, 20)];
    [self.view addSubview:slider];
    
    
    UIButton *removeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    CGFloat btnW = 60;
//    CGFloat btnH = 30;
//    removeBtn.frame = CGRectMake(SCREENWIDTH - 10-btnW, 35, btnW, btnH);
//    [removeBtn setTitle:@"删除" forState:UIControlStateNormal];
//    [removeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    CGFloat btnWidth = 34;
    removeBtn.frame = CGRectMake(SCREENWIDTH-btnWidth-20, 27, btnWidth, btnWidth);
    [removeBtn setImage:[UIImage imageNamed:@"删除 (1)"] forState:UIControlStateNormal];
    [removeBtn addTarget:self action:@selector(clickRemoveBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:removeBtn];
}

-(void)clickRemoveBtn
{
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
                                                         }];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];

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
@end









