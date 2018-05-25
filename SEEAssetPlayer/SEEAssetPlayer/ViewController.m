//
//  ViewController.m
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/4/14.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import "ViewController.h"
#import "SEEPlayer.h"
#import "SEEFileInfo.h"
@interface ViewController ()

@property (nonatomic, strong) SEEPlayer * player;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    _player = [[SEEPlayer alloc]initWithFrame:CGRectZero];
    [self.view addSubview:_player];
    [_player setURL:[NSURL URLWithString:@"http://he.yinyuetai.com/uploads/videos/common/88CE01595A940BC83C7AB2C616308D62.mp4?sc=9b0ddcaad115e009&br=3099&vid=2763591&aid=25339&area=KR&vst=0"]];
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _player.frame = self.view.frame;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_player play];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_player pause];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
