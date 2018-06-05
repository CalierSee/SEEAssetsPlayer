//
//  ViewController.m
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/4/14.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import "ViewController.h"
#import "SEEPlayerView.h"
#import "SEEFileInfo.h"
#import "UIViewController+Top.h"
@interface ViewController ()

@property (nonatomic, strong) SEEPlayerView * player;

@property (nonatomic, strong) NSArray * douyinVideoStrings;


@property (nonatomic, assign) NSInteger  currentIndex;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
        NSLog(@"%@",[UIViewController topViewController]);
    
    _player = [SEEPlayerView playerView];
    [self.view addSubview:_player];
    [_player setURL:[NSURL URLWithString:self.douyinVideoStrings[self.currentIndex]]];
    self.navigationController.navigationBar.translucent = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"下一个" style:UIBarButtonItemStyleDone target:self action:@selector(see_next)];
    _player.panGesture.enabled = NO;
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)see_next {
    self.currentIndex ++;
    [_player setURL:[NSURL URLWithString:self.douyinVideoStrings[self.currentIndex]]];
    _player.returnType = SEEPlayerViewReturnButtonTypeReturn;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _player.frame = CGRectMake(0, 0, self.view.bounds.size.width, 200);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)playerDidClose {
    [_player removeFromSuperview];
    _player = nil;
}

- (NSArray<NSString *> *)douyinVideoStrings {
    if(!_douyinVideoStrings){
        _douyinVideoStrings = @[
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
    }
    return _douyinVideoStrings;
}

@end
