//
//  ViewController.m
//  Smart_Device_Client
//
//  Created by Josie on 2017/9/18.
//  Copyright © 2017年 Josie. All rights reserved.
//

#import "ViewController.h"
#import "AddViewController.h"
#import "HeaderDefine.h"
#import "DevCell.h"
#import "OtherViewController.h"
#import "CameraViewController.h"

@interface ViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>

// 背景图片
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImgView;


// 添加设备按钮
@property (nonatomic, strong) UIButton *addDevBtn;


@property (nonatomic, strong) UICollectionView *collection;

@property (nonatomic, strong) UIView *viewHead;

// 数据源
@property (nonatomic, strong) NSArray *dataArr;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUI) name:@"updateHomeUI" object:nil];
    
    [self setCollectionView];
}

-(void)addDevice
{
    AddViewController *vc = [[AddViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)updateUI
{
    self.dataArr = nil;
    
    // 重新从沙盒读取数据
    [self.collection reloadData];
}

#pragma mark - ****** collection ******
-(void)setCollectionView
{
    //    collection
    [self.view insertSubview:self.collection atIndex:1];
    [self.collection registerNib:[UINib nibWithNibName:@"DevCell" bundle:nil] forCellWithReuseIdentifier:@"cell"];
    
    [self.collection addSubview:self.viewHead];
    [self.viewHead addSubview:self.addDevBtn];
}

#pragma mark - UICollectionViewDataSource

//每个section有几个cell
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataArr.count;
}
//cell复用
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{


    NSDictionary *dic = self.dataArr[indexPath.row];
    
    DevCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    NSString *nameStr = [NSString stringWithFormat:@"%@",dic[@"name"]];
    cell.nameLabel.text = nameStr;
    
    if ([nameStr isEqualToString:@"监控_1"]) {
        nameStr = @"监控";
    }
    cell.imgView.image = [UIImage imageNamed:nameStr];
    
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout
//定义每个cell的大小
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{

    CGFloat margin = 20;
    
    return CGSizeMake(CELLWIDTH, CELLWIDTH+margin);
}
//定义每个UICollectionView 的 inset
-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    
    return UIEdgeInsetsMake(50, 30, 50, 30);//上、左、下、右（是相当于整个section的）
}



#pragma mark - UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // 此工程只做监控音视频TCP传输的细节
    NSDictionary *dic = self.dataArr[indexPath.row];
    if ([dic[@"type"] isEqualToString:@"0"]) {
        CameraViewController *cameraVC = [[CameraViewController alloc] init];
        cameraVC.index = indexPath.row;
        [self presentViewController:cameraVC animated:YES completion:nil];
    }else
    {
        OtherViewController *otherVC = [[OtherViewController alloc] init];
        otherVC.index = indexPath.row;
        [self presentViewController:otherVC animated:YES completion:nil];
    }
}



#pragma mark - setter and getter
-(UICollectionView *)collection
{
    if (!_collection) {
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        
        _collection = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collection.delegate = self;
        _collection.dataSource = self;
        _collection.backgroundColor = [UIColor clearColor];
    }
    return _collection;
}

-(UIView *)viewHead
{
    if (!_viewHead) {
        _viewHead = [[UIView alloc] initWithFrame:CGRectMake(0, -64, SCREENWIDTH, 64)];
        _viewHead.backgroundColor = [UIColor clearColor];
        self.collection.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);//重要，整个collection的inset
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 63, SCREENWIDTH, 1)];
        lineView.backgroundColor = [UIColor whiteColor];
        lineView.alpha = 0.4;
        [_viewHead addSubview:lineView];
    }
    return _viewHead;
}

-(UIButton *)addDevBtn
{
    if (!_addDevBtn) {
        _addDevBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _addDevBtn.frame = CGRectMake(16, 20, 40, 40);
        [_addDevBtn setImage:[UIImage imageNamed:@"添加"] forState:UIControlStateNormal];
        [_addDevBtn addTarget:self action:@selector(addDevice) forControlEvents:UIControlEventTouchUpInside];
    }
    return _addDevBtn;
}

-(NSArray *)dataArr
{
    if (!_dataArr) {
        
        // 已添加的设备数据
        // 先从沙盒目录中读取，如果沙盒中没有的话，再从plist文件中读取
        //获取本地沙盒路径
        NSArray *pathArr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        //获取完整路径
        NSString *documentsPath = [pathArr objectAtIndex:0];
        NSString *path = [documentsPath stringByAppendingPathComponent:@"DevicesList.plist"];
//        NSLog(@"1====%@",path);
        
        // 如果沙盒里有MyAddressData.plist该文件的话则直接读文件内容
        NSFileManager *manager = [NSFileManager defaultManager];
        if ([manager fileExistsAtPath:path]) {
            //沙盒文件中的内容（arr）
            NSArray *docArr = [NSArray arrayWithContentsOfFile:path];
            _dataArr = docArr;
        }else
        {
            // 否则从mainBundle 的 plist文件读取数据，写入沙盒
            NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"DevicesList" ofType:@"plist"];
            NSArray *arr = [NSArray arrayWithContentsOfFile:plistPath];
            _dataArr = arr;
            
            //把plist文件里面的内容写入沙盒
            [_dataArr writeToFile:path atomically:YES];
        }
    }
    return _dataArr;
}

@end








