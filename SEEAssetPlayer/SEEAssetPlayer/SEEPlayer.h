//
//  SEEPlayer.h
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/4/14.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SEEPlayerView.h"

@class SEEPlayer;


typedef NS_ENUM(NSUInteger, SEEPlayerStatus) {
    SEEPlayerStatusUnknow = 0,//未知状态，初始状态
    SEEPlayerStatusPlay = 1,//正在播放
    SEEPlayerStatusPause = 2,//暂停
    SEEPlayerStatusFailed = 3,//视频加载失败
    SEEPlayerStatusComplete = 4,//视屏播放完成
};

NS_ASSUME_NONNULL_BEGIN

@interface SEEPlayer : NSObject

/**
 播放状态
 */
@property (nonatomic, assign, readonly) SEEPlayerStatus status;

@property (nonatomic, assign, readonly, getter = isBuffing) BOOL buffing;

- (void)setURL:(NSURL *)url;

@property (nonatomic, strong, readonly) AVPlayer * player;

@property (nonatomic, strong, readonly) NSURL * currentUrl;

@property (nonatomic, strong, readonly) AVPlayerItem * playerItem;

@property (nonatomic, strong, readonly) AVPlayerLayer * playerLayer;

@property (nonatomic, assign, readonly) NSTimeInterval duration;

@property (nonatomic, assign, readonly) NSTimeInterval currentTime;



- (void)play;
- (void)pause;

- (void)seekToTime:(NSTimeInterval)time;


@end

NS_ASSUME_NONNULL_END
