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
#import "HJUDPSearchClient.h"
#import "HeaderDefine.h"

@interface AddViewController ()<UIPickerViewDataSource,UIPickerViewDelegate>

@property (nonatomic, retain) HJUDPSearchClient *client;
@property (nonatomic, assign) BOOL          isRecv;

/** 滚轮选择器 */
@property (nonatomic, strong) UIPickerView  *pickerView;
@property (nonatomic, assign) NSInteger     pickerRow;
@property (nonatomic, strong) UITextField   *typeTF;
@property (nonatomic, strong) UITextField   *idTF;
@property (nonatomic, strong) UITextField   *ipTF;
@property (nonatomic, strong) NSArray       *typeDataArr;

@property (nonatomic, strong) UIButton      *addBtn;

@property (nonatomic, strong) NSDictionary  *searchedDataDic; // UDP搜索到的数据

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
    self.isRecv = false;
    self.pickerRow = 0;
    [self buildSearchedUI];
    
    [self showHUD];
    
    [self startUDPSearch];
}

-(void)showHUD
{
    [MBProgressHUD showMessage:@"正在搜索设备中....."];
    
    // 几秒后消失,当然，这里可以改为网络请求
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (!self.isRecv) { // 5秒后还没有收到的话
            // 移除HUD
            [MBProgressHUD hideHUD];
            
            // 提醒有没有新数据
            [MBProgressHUD showError:@"没有新设备"];
        }
        
    });
}

-(void)startUDPSearch
{
    self.client = [[HJUDPSearchClient alloc] init];
    
    [self.client startUDPSearchWithBlock:^(NSDictionary *dataDic) {
        
        NSLog(@"---搜索到 ip = %@, port = %@, type = %@ ,id = %@ ----",dataDic[@"key_ip"],dataDic[@"key_port"], dataDic[@"key_type"], dataDic[@"key_id"]);
        self.isRecv = true;
        
        // UDP搜索到的数据
        self.searchedDataDic = [NSDictionary dictionaryWithDictionary:dataDic];
        
        // 更新到主线程 UI
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // 移除HUD
            [MBProgressHUD hideHUD];
            self.addBtn.enabled = YES;
            
            
            // 把搜索到的数据更新到textField
            [self setupTextFieldData];
            
            [self addBtnEnable];
        });
        
        // 停止搜索
        [self onStopSearch];
    }];
}

-(void)setupTextFieldData
{
    if ([self.searchedDataDic[@"key_type"] isEqualToString:@"0"]) { // 搜索到的只可能是类型“0”
        self.typeTF.text = @"监控";
        self.idTF.text = self.searchedDataDic[@"key_id"];
        self.ipTF.text = self.searchedDataDic[@"key_ip"];
    }
}

-(void)addBtnEnable
{
    self.addBtn.enabled = YES;
    _addBtn.layer.borderColor = [UIColor whiteColor].CGColor;
}

- (void)onStopSearch
{
    [self.client stopUDPSearch];
}

-(void)buildSearchedUI
{
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
//    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    
    CGFloat marginY = 50;
//    CGFloat marginX = 70;
    
    CGFloat labelX = 30;
    CGFloat labelY = 100;
    CGFloat labelW = 80;
    CGFloat labelH = 30;
    
    
    CGFloat textX = labelX+labelW + 20;
    CGFloat textW = screenWidth - textX - 20;
    CGFloat textH = 40;
    
    
    
    UILabel *typeL = [[UILabel alloc] initWithFrame:CGRectMake(labelX, labelY, labelW, labelH)];
    typeL.text = @"type:";
    typeL.textColor = [UIColor whiteColor];
    [self.view addSubview:typeL];
    
    self.typeTF = [[UITextField alloc] initWithFrame:CGRectMake(textX, labelY, textW, textH)];
    self.typeTF.backgroundColor = [UIColor whiteColor];
    self.typeTF.inputView = self.pickerView;
    self.typeTF.inputAccessoryView = [self buildInputViewWithTitle:@"选择类型"];
    [self.view addSubview:self.typeTF];
    
    
    UILabel *idL = [[UILabel alloc] initWithFrame:CGRectMake(labelX, labelY+marginY, labelW, labelH)];
    idL.text = @"deviceID:";
    idL.textColor = [UIColor whiteColor];
    [self.view addSubview:idL];
    
    self.idTF = [[UITextField alloc] initWithFrame:CGRectMake(textX, labelY+marginY, textW, textH)];
    self.idTF.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.idTF];
    
    UILabel *ipL = [[UILabel alloc] initWithFrame:CGRectMake(labelX, labelY+marginY+marginY, labelW, labelH)];
    ipL.text = @"IPADDR:";
    ipL.textColor = [UIColor whiteColor];
    [self.view addSubview:ipL];
    
    self.ipTF = [[UITextField alloc] initWithFrame:CGRectMake(textX, labelY+marginY+marginY, textW, textH)];
    self.ipTF.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.ipTF];
    
    [self.view addSubview:self.addBtn];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    // 触摸收键盘
    [self.view endEditing:YES];
}
-(UIView*)buildInputViewWithTitle:(NSString *)title
{
    UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, SCREENWIDTH, 40)];
    
    UIView *lineV = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREENWIDTH, 1)];
    lineV.backgroundColor = [UIColor lightGrayColor];
    lineV.alpha = 0.6;
    [toolBar addSubview:lineV];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREENWIDTH, 40)];
    titleLabel.text = title;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.alpha = 0.8;
    titleLabel.font = [UIFont systemFontOfSize:15];
    [toolBar addSubview:titleLabel];
    
    UIButton *noBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    noBtn.frame = CGRectMake(0, 0, 80, 40);
    [noBtn setTitle:@"取消" forState:UIControlStateNormal];
    [noBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    noBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [noBtn addTarget:self action:@selector(selectedTypeTextFieldDidChange:) forControlEvents:UIControlEventTouchUpInside];
    [toolBar addSubview:noBtn];
    
    UIButton *yesBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    yesBtn.frame = CGRectMake(SCREENWIDTH-80, 0, 80, 40);
    [yesBtn setTitle:@"确定" forState:UIControlStateNormal];
    [yesBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    yesBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [yesBtn addTarget:self action:@selector(selectedTypeTextFieldDidChange:) forControlEvents:UIControlEventTouchUpInside];
    [toolBar addSubview:yesBtn];
    
    
    return toolBar;
}

-(void)selectedTypeTextFieldDidChange:(UIButton*)btn
{
    if ([btn.titleLabel.text isEqualToString:@"确定"]) {
        
        NSString *str = self.typeDataArr[self.pickerRow];
        
        [self.typeTF setText:str];
        
        [self.view endEditing:YES];
        [self addBtnEnable];
        
    }else                                   // 取消
        [self.view endEditing:YES];
}


// -------- 把数据写入沙盒 ---------
-(void)writeDataToSandBoxWithData:(NSDictionary*)dic
{
    // 根据设备唯一标识符来判断设备是否已被添加（这里用自定义的id来模拟UUID）
    NSString *idStr = dic[@"id"];
//    NSLog(@"--idstr = %@",idStr);
    
    //获取本地沙盒路径
    NSArray *pathArr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //获取完整路径
    NSString *documentsPath = [pathArr objectAtIndex:0];
    NSString *path = [documentsPath stringByAppendingPathComponent:@"DevicesList.plist"];
    //沙盒文件中的内容（arr）
//    NSArray *docArr = [NSArray arrayWithContentsOfFile:path];
    NSMutableArray *arr = [NSMutableArray arrayWithContentsOfFile:path];
    
    
    BOOL signal = false;
    for (int i = 0; i < arr.count; i++) {
        NSDictionary *tempDic = arr[i];
        if ([tempDic[@"id"] isEqualToString:idStr]) {
            // 设备已存在
            signal = true;
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [MBProgressHUD showError:@"设备已存在"];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    // 移除HUD
                    [MBProgressHUD hideHUD];
                });
            });
            // 退出遍历
            break;
        }
    }
    if (!signal) {
        // 添加到plist
        //            [arr addObject:dic];
        NSUInteger index = arr.count;
        [arr insertObject:dic atIndex:index];
        NSLog(@"-- 添加到plist文件后，arr.count = %ld ", (unsigned long)arr.count);
        [arr writeToFile:path atomically:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [MBProgressHUD showMessage:@"添加成功"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // 移除HUD
                [MBProgressHUD hideHUD];
                [self dismissViewControllerAnimated:YES completion:nil];
            });
        });
        
    }
}

-(void)clickAddBtn
{
    NSString *typeStr = @"";
    NSString *nameStr = @"";
    NSString *ipStr = @"";
    NSString *idStr = @"";
    if (self.searchedDataDic) {
        // 搜索到的数据
        typeStr = @"0";
        nameStr = @"监控";
        ipStr = self.searchedDataDic[@"key_ip"];
        idStr = self.searchedDataDic[@"key_id"];
        
        // 判断设备是Mac还是iPhone
        if ([idStr isEqualToString:@"12355"]) {// mac
            nameStr = @"监控_1";
        }
    }else{
        // 手动填写的数据
        nameStr = self.typeTF.text;
        // 如果要添加的是摄像头
        if ([nameStr isEqualToString:@"监控"]) {
            // ip地址不能为空
            printf("--- ip地址不能为空，默认IP为192.168.3.19 ---\n");
            ipStr = @"192.168.3.19";
        }
        
        NSInteger index = [self.typeDataArr indexOfObject:nameStr];
        typeStr = [NSString stringWithFormat:@"%ld",(long)index];
        idStr = [NSString stringWithFormat:@"%d",arc4random()%99999 ];
    }
    NSDictionary *tempDic = [NSDictionary dictionaryWithObjectsAndKeys:
                             typeStr,   @"type",
                             nameStr,   @"name",
                             ipStr,     @"ip",
                             idStr,     @"id",nil];
    // -------- 把数据写入沙盒 ---------
    [self writeDataToSandBoxWithData:tempDic];
    
    
    
    // ------------ 通知HomeVC更新UI ---------
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateHomeUI" object:nil];
}

#pragma mark - UIPickerViewDataSource
// 有几列
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// 每一列有几行
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.typeDataArr.count;
}

// 每一行显示的内容
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *str = self.typeDataArr[row];
    return str;
}

#pragma mark - UIPickerViewDelegate

// 停留在了哪一列，哪一行
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.pickerRow = row;
//    NSLog(@"%ld 行", row);
}


#pragma mark - 懒加载
-(UIPickerView *)pickerView
{
    if (!_pickerView)
    {
        _pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, SCREENHEIGHT-200, SCREENWIDTH, 200)];
        
        
        // 代理和数据源，显示的内容是通过数据源指定的
        _pickerView.delegate = self;
        _pickerView.dataSource = self;
    }
    return _pickerView;
}

-(NSArray *)typeDataArr
{
    if (!_typeDataArr) {
        _typeDataArr = [NSArray arrayWithObjects:@"监控", @"窗帘", @"电灯", @"空调", @"插座", nil];
    }
    return _typeDataArr;
}

-(UIButton *)addBtn
{
    if (!_addBtn) {
        _addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _addBtn.frame = CGRectMake((SCREENWIDTH-100)/2, 360, 100, 40);
        [_addBtn setTitle:@"添 加" forState:UIControlStateNormal];
        [_addBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_addBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        _addBtn.enabled = NO;
        _addBtn.layer.cornerRadius = 15;
        _addBtn.layer.borderColor = [UIColor lightGrayColor].CGColor;
        _addBtn.layer.borderWidth = 3;
        [_addBtn addTarget:self action:@selector(clickAddBtn) forControlEvents:UIControlEventTouchUpInside];
    }
    return _addBtn;
}

@end






