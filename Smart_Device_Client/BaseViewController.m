//
//  BaseViewController.m
//  Smart_Device_Client
//
//  Created by Josie on 2017/9/18.
//  Copyright © 2017年 Josie. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    imgView.image = [UIImage imageNamed:@"background_3"];
    [self.view addSubview:imgView];
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat margin = 4.5;
    backBtn.frame = CGRectMake(16+margin, 24+margin, 40-2*margin, 40-2*margin);
    [backBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(clickBackBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backBtn];
}

-(void)clickBackBtn
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
