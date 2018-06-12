//
//  SNSeveralRequestController.m
//  GCDTest
//
//  Created by Temporary on 2018/6/11.
//  Copyright © 2018年 Temporary. All rights reserved.
//

#import "SNSeveralRequestController.h"
#import "MJRefresh.h"
#import "AFNetworking.h"

@interface SNSeveralRequestController ()<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic,copy)NSArray *topArr;
@property(nonatomic,copy)NSArray *shehuiArr;
@property(nonatomic,copy)NSArray *guoneiArr;


@end

@implementation SNSeveralRequestController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    
    [self.mainTable registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    
    self.mainTable.delegate = self;
    self.mainTable.dataSource = self;
    
    
    
    //    MJRefreshHeader MJRefreshNormalHeader
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [self requestAll_GCDGroup];
    }];
    _mainTable.mj_header = header;
    header.lastUpdatedTimeLabel.hidden  = YES;
    [_mainTable.mj_header beginRefreshing];
    
}

-(void)requestAll_GCDGroup{
// 方法一： GCD的leave和enter    我们利用dispatch_group_t创建队列组，手动管理group关联的block运行状态，进入和退出group的次数必须匹配。
    //1.创建队列组
    dispatch_group_t group = dispatch_group_create();
    //2.创建队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //3.添加请求
    dispatch_group_async(group, queue, ^{
        dispatch_group_enter(group);
        [self requestTopWithSuccessCallBack:^(NSArray *array) {
            self.topArr = array;
            dispatch_group_leave(group);
        } failCallback:^(bool isFail) {
            dispatch_group_leave(group);
        }];

    });
    dispatch_group_async(group, queue, ^{
        dispatch_group_enter(group);
        [self requestShehuiWithSuccessCallBack:^(NSArray *array) {
            self.shehuiArr = array;
            dispatch_group_leave(group);
        } failCallback:^(bool isFail) {
            dispatch_group_leave(group);
        }];
     
    });
    
    dispatch_group_async(group, queue, ^{
        dispatch_group_enter(group);
        [self requestGuoneiWithSuccessCallBack:^(NSArray *array) {
            self.guoneiArr = array;
            dispatch_group_leave(group);
        } failCallback:^(bool isFail) {
            dispatch_group_leave(group);
        }];
        
    });
    
    //4.队列组所有请求完成回调刷新UI
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
//        NSLog(@"model:%f",_buyingStrategyModel.leverrisk);
        NSLog(@"加载完成");
        [self.mainTable.mj_header endRefreshing];
        [self.mainTable reloadData];
    });
}

-(void)requestAll_GCDSemaphore{
    //创建信号量
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group, queue, ^{
        [HomeRequest getPointBuyAllConfigurationStrategyType:_dataType success:^(NSInteger code, NSDictionary *dict) {
            dispatch_semaphore_signal(semaphore);
        } failuer:^(NSInteger code, NSString *message) {
            dispatch_semaphore_signal(semaphore);
        }];
    });
    dispatch_group_async(group, queue, ^{
        [HomeRequest getStockLeverRiskStockCode:_buyingStrategyModel.stockCode strategyType:_dataType success:^(NSInteger code, NSDictionary *dict) {
            dispatch_semaphore_signal(semaphore);
        } failuer:^(NSInteger code, NSString *message) {
            dispatch_semaphore_signal(semaphore);
        }];
    });
    dispatch_group_notify(group, queue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"信号量为0");
    });
}


-(void)requestTopWithSuccessCallBack:(void(^)(NSArray *array))successCallbackBlock failCallback:(void(^)(bool isFail)) failCallbackBlock{
    [self requestWithFenLei:@"top" successCallBack:successCallbackBlock failCallback:failCallbackBlock];
}

-(void)requestShehuiWithSuccessCallBack:(void(^)(NSArray *array))successCallbackBlock failCallback:(void(^)(bool isFail)) failCallbackBlock{
    [self requestWithFenLei:@"shehui" successCallBack:successCallbackBlock failCallback:failCallbackBlock];
}

-(void)requestGuoneiWithSuccessCallBack:(void(^)(NSArray *array))successCallbackBlock failCallback:(void(^)(bool isFail)) failCallbackBlock{
    [self requestWithFenLei:@"guonei" successCallBack:successCallbackBlock failCallback:failCallbackBlock];
}

-(void)requestWithFenLei:(NSString *)fenLei successCallBack:(void(^)(NSArray *array))successCallbackBlock failCallback:(void(^)(bool isFail)) failCallbackBlock{
    
    NSString *url = [NSString stringWithFormat:@"http://v.juhe.cn/toutiao/index?type=%@&key=f1db1cefce44c93b2549b592a7fe6039",fenLei];
    
    [[AFHTTPSessionManager  manager] GET:url parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        ;
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"完成请求");
        NSDictionary *resultDic = responseObject[@"result"];
        NSArray *array = resultDic[@"data"];

        if (successCallbackBlock) {
            successCallbackBlock(array);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failCallbackBlock) {
            failCallbackBlock(YES);
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- ( NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case 0:
        {
            return @"头条";
        }
            break;
        case 1:
        {
            return @"社会";
        }
            break;
        case 2:
        {
             return @"国内";
        }
            break;
            
        default:
            break;
    }
    return  @"其他";
}


 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];

     cell.textLabel.text = @"123";
     cell.detailTextLabel.text = @"21";
     
     NSDictionary *dictData = nil;
     
     switch (indexPath.section) {
         case 0:
             {
                 if (self.topArr) {
                      dictData = self.topArr[indexPath.row];
                 }
                
             }
             break;
         case 1:
         {
             if (self.shehuiArr) {
                 dictData = self.shehuiArr[indexPath.row];
             }
             
         }
             break;
         case 2:
         {
             if (self.guoneiArr) {
                 dictData = self.guoneiArr[indexPath.row];
             }
             
         }
             break;
             
         default:
             break;
     }
     
     NSString *title = dictData[@"title"];
     cell.textLabel.text = title;
     cell.textLabel.textColor = [UIColor blueColor];
 
 // Configure the cell...
 
 return cell;
 }
 
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UIViewController *controller = [[UIViewController alloc]init];
    [self.navigationController pushViewController:controller animated:YES];
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
