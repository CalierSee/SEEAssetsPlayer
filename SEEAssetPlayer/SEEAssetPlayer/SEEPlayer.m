//
//  SEEPlayer.m
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/4/14.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import "SEEPlayer.h"
#import "SEEResourceLoaderDelegate.h"
#import "SEEPlayerMacro.h"
#import "SEEFileManager.h"

@interface SEEPlayer ()

@property (nonatomic, assign) SEEPlayerStatus status;

@property (nonatomic, assign, getter = isBuffing) BOOL buffing;

@property (nonatomic, assign) NSTimeInterval  duration;

@property (nonatomic, assign) NSTimeInterval  currentTime;

@end

@implementation SEEPlayer {
    NSURL * _currentUrl;
    int _loadCount;
    SEEResourceLoaderDelegate * _resourceLoaderDelegate;
    AVPlayer * _player;
    AVPlayerItem * _playerItem;
    AVPlayerLayer * _playerLayer;
    id _timeObserver;
}

@synthesize player = _player;
@synthesize playerItem = _playerItem;
@synthesize playerLayer = _playerLayer;
@synthesize currentUrl = _currentUrl;

#pragma mark life circle
- (instancetype)init {
    if (self = [super init]) {
        //创建resourceLoader在整个播放器生命周期中 resourceLoader 不变
        [self see_initPlayer];
    }
    return self;
}

- (void)dealloc {
    //清除播放器
    [self see_clearPlayer];
    [_player removeObserver:self forKeyPath:@"status"];
    [_player removeTimeObserver:_timeObserver];
    _timeObserver = nil;
}

#pragma mark public method

/**
 设置播放url

 @param url url
 */
- (void)setURL:(NSURL *)url {
    if ([_currentUrl isEqual:url]) {
        if (++_loadCount > 3) {
            self.status = SEEPlayerStatusFailed;
            return;
        }
    }
    else {
        _loadCount = 0;
        _currentUrl = url;
    }
    [_player pause];
    //0 播放器播放新url之前清除上一次的监听等
    [self see_clearPlayer];
    //1 播放状态重置
    self.status = SEEPlayerStatusUnknow;
    //2 重新设置item
    AVPlayerItem * newItem = [AVPlayerItem playerItemWithAsset:[self->_resourceLoaderDelegate assetWithURL:url] automaticallyLoadedAssetKeys:@[@"duration",@"preferredRate",@"preferredVolume",@"preferredTransform"]];
    //3 设置新的item
    [self->_player replaceCurrentItemWithPlayerItem:newItem];
    //4 添加对播放器的监听
    [self see_preparePlayer];
}

- (void)play {
    if (self.status != SEEPlayerStatusPlay) {
        self.status = SEEPlayerStatusPlay;
    }
}

- (void)pause {
    if (self.status != SEEPlayerStatusPause) {
        self.status = SEEPlayerStatusPause;
    }
}

- (void)seekToTime:(NSTimeInterval)time {
    if (self.duration == 0) return;
    switch (self.status) {

        case SEEPlayerStatusPlay:
            [_player pause];
            break;
        case SEEPlayerStatusComplete:
            self.status = SEEPlayerStatusPause;
            break;
        case SEEPlayerStatusUnknow:
            return;
            break;

        default:
            break;
    }
    __weak typeof(self) weakSelf = self;
    CGFloat scale = time / self.duration;
    CMTime newTime = CMTimeMake(_player.currentItem.duration.value * scale, _player.currentItem.duration.timescale);
    [_player seekToTime:newTime completionHandler:^(BOOL finished) {
        __strong typeof(weakSelf) self = weakSelf;
        if (finished && self.status == SEEPlayerStatusPlay) {
            [self->_player play];
        }
    }];
}

#pragma mark action method
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        switch (_player.status) {
            case AVPlayerStatusReadyToPlay:
                if (self.status == SEEPlayerStatusPlay) {
                    [_player play];
                    SEELog(@"准备完成播放");
                }
                else {
                    [_player pause];
                    SEELog(@"准备完成暂停");
                }
                break;
            case AVPlayerStatusFailed:
                //avplayer准备失败 重新创建
                SEELog(@"avplayer创建失败 %@",_player.error);
                [_player removeObserver:self forKeyPath:@"status"];
                [_player removeTimeObserver:_timeObserver];
                _timeObserver = nil;
                [self see_initPlayer];
                [self setURL:_currentUrl];
                break;
            default:
                break;
        }
    }
    else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        if (_player.currentItem.playbackLikelyToKeepUp) {
            self.buffing = NO;
        }
    }
    else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        if (_player.currentItem.playbackBufferEmpty) {
            self.buffing = YES;
        }
    }
    else if ([keyPath isEqualToString:@"duration"]) {
        self.duration = [self see_time:_player.currentItem.duration];
    }
    else {
        //do nothing...
    }
}



#pragma mark private method
- (NSTimeInterval)see_time:(CMTime)time {
     NSTimeInterval seconds = time.value / time.timescale;
    return seconds;
}

- (void)see_initPlayer {
    if (_playerLayer) {
        [_playerLayer removeFromSuperlayer];
        _playerLayer = nil;
    }
    if (_player) {
        [self see_clearPlayer];
        _player = nil;
    }
    _resourceLoaderDelegate = [[SEEResourceLoaderDelegate alloc]init];
    _player = [[AVPlayer alloc]init];
    if (@available(iOS 10.0, *)) {
        _player.automaticallyWaitsToMinimizeStalling = NO;
    }
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    [self see_preparePlayer];
    [_player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    __weak typeof(self) weakSelf = self;
    _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        __strong typeof(weakSelf) self = weakSelf;
        self.currentTime = [self see_time:time];
        if (self.currentTime >= self.duration && self.duration != 0) {
            self.status = SEEPlayerStatusComplete;
        }
    }];
}

/**
 准备player
 添加player状态监听
 添加对item监听
 */
- (void)see_preparePlayer {
    AVPlayerItem * item = _player.currentItem;
    if (item == nil) return;
    [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionNew context:nil];
    //如果用户没有手动暂停播放器则初始化播放器后默认播放
    self.status = SEEPlayerStatusPlay;
//    if (self.status != SEEPlayerStatusPause) {
//    }
}

/**
 清除player
 清除player状态监听
 清除对item监听
 */
- (void)see_clearPlayer {
    [_player pause];
    if (_player.currentItem != nil) {
        AVPlayerItem * item = _player.currentItem;
        if (item == nil) return;
        [item removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        [item removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [item removeObserver:self forKeyPath:@"duration"];
        [_player replaceCurrentItemWithPlayerItem:nil];
    }
}

- (void)see_buffingSomeSeconds {
    if (_buffing) {
        [self performSelector:@selector(see_buffingSomeSeconds) withObject:nil afterDelay:2];
    }
    else {
        if (self.status == SEEPlayerStatusPlay) {
            [_player play];
        }
    }
}

#pragma mark getter & setter

- (void)setStatus:(SEEPlayerStatus)status {
    if (status == _status) return;
    if (_status == SEEPlayerStatusComplete && status == SEEPlayerStatusPlay) {
        [self seekToTime:0];
    }
    switch (status) {
        case SEEPlayerStatusPlay:
            SEELog(@"开始播放");
            [_player play];
            break;
        case SEEPlayerStatusPause:
        case SEEPlayerStatusFailed:
        case SEEPlayerStatusUnknow:
        case SEEPlayerStatusComplete:
            SEELog(@"暂停");
            [_player pause];
            break;
    }
    _status = status;
}

- (void)setBuffing:(BOOL)buffing {
    if (buffing == _buffing)return;
    _buffing = buffing;
    if (buffing) {
        SEELog(@"正在缓冲");
        [_player pause];
        [self see_buffingSomeSeconds];
    }
}

@end
