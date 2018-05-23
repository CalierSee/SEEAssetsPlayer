//
//  SEEPlayerToolsView.h
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/5/8.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SEEPlayerToolsViewDelegate <NSObject>

/**
 播放暂停
 当点击播放/暂停按钮时通知代理 由代理返回播放器最终状态

 @param isPlay YES播放  NO暂停
 @return YES播放  NO暂停
 */
- (BOOL)playOrPause:(BOOL)isPlay;

/**
 跳转到指定进度

 @param progress [0,1]
 */
- (void)seekToTime:(CGFloat)progress;

/**
 关闭视屏
 */
- (void)close;


@end

@interface SEEPlayerToolsView : UIView

+ (instancetype)playerToolsView;

@property (nonatomic, weak) id <SEEPlayerToolsViewDelegate> delegate;

- (void)setCurrentTime:(NSInteger)time;

- (void)setProgress:(float)progress;

- (void)setDuration:(NSInteger)duration;

- (void)playOrPause:(BOOL)isPlay;

@end
