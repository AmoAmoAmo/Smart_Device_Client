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
    
}

@end
