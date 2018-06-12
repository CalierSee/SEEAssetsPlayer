//
//  SEEVideoDisplayVC.m
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/5/31.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import "SEEVideoDisplayVC.h"
#import "SEEVideoDisplayCell.h"
#import "SEEVideoModel.h"
#import "UITableView+HeightCache.h"
#import "SEEPlayerView.h"
@interface SEEVideoDisplayVC () <SEEVideoDisplayCellDelegate>


@property (nonatomic, strong) NSArray <SEEVideoModel *> * datas;

@property (nonatomic, strong) SEEPlayerView * player;

@property (nonatomic, strong) NSIndexPath * currentPlayIndexPath;




@end

@implementation SEEVideoDisplayVC

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.player = [SEEPlayerView playerView];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.player = [SEEPlayerView playerView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [UITableView cacheEnabled:YES];
    
    self.tableView.separatorInset = UIEdgeInsetsMake(10,10,10,10);

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (SEEPlayerView *)cell:(SEEVideoDisplayCell *)cell playerWithIndexPath:(NSIndexPath *)indexPath {
    if (!cell.playing) {
        [self.player setURL:[NSURL URLWithString:self.datas[indexPath.row].url]];
        if (self.currentPlayIndexPath) {
            self.datas[self.currentPlayIndexPath.row].playing = NO;
            SEEVideoDisplayCell * cell = [self.tableView cellForRowAtIndexPath:self.currentPlayIndexPath];
            cell.playing = NO;
        }
        self.datas[indexPath.row].playing = YES;
        self.currentPlayIndexPath = indexPath;
    }
    return self.player;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Incomplete implementation, return the number of sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of rows
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SEEVideoDisplayCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.delegate = self;
    cell.indexPath = indexPath;
    [cell configureWithModel:self.datas[indexPath.row]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView heightForCellWithIdentifier:@"cell" indexPath:indexPath configuration:^(__kindof UITableViewCell *cell) {
        [(SEEVideoDisplayCell *)cell configureWithModel:self.datas[indexPath.row]];
    }];
}


- (NSArray *)datas {
    if (_datas == nil) {
        
        NSArray * urls = @[
          @"http://he.yinyuetai.com/uploads/videos/common/88CE01595A940BC83C7AB2C616308D62.mp4?sc=9b0ddcaad115e009&br=3099&vid=2763591&aid=25339&area=KR&vst=0",
          @"http://p11s9kqxf.bkt.clouddn.com/coder.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/buff.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/cat.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/child.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/english.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/erha.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/face.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/fanglian.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/gao.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/girlfriend.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/haha.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/hide.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/juzi.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/keai.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/nvpengy.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/samo.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/shagou.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/shagougou.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/shamiao.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/sichuan.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/tuolaiji.mp4",
          @"http://p11s9kqxf.bkt.clouddn.com/xiaobiaozi.mp4",
          ];
        
        _datas = [SEEVideoModel modelsWithNames:urls urls:urls];
    }
    return _datas;
}

@end
