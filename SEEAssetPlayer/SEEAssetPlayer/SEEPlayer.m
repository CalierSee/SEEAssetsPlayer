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

@interface SEEPlayer () <SEEPlayerToolsViewDelegate>

@property (nonatomic, assign) SEEPlayerStatus status;

@property (nonatomic, assign, getter = isBuffing) BOOL buffing;

@end

@implementation SEEPlayer {
    NSURL * _currentUrl;
    int _loadCount;
    SEEResourceLoaderDelegate * _resourceLoaderDelegate;
    AVPlayer * _player;
    AVPlayerItem * _playerItem;
    AVPlayerLayer * _playerLayer;
    SEEPlayerToolsView * _toolsView;
    id _timeObserver;
    NSTimeInterval _duration;
    
    struct {
        int didClose;
    }_responder;
}

@synthesize player = _player;
@synthesize playerItem = _playerItem;
@synthesize playerLayer = _playerLayer;
@synthesize currentUrl = _currentUrl;
@synthesize toolsView = _toolsView;

#pragma mark life circle
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor blackColor];
        //创建resourceLoader在整个播放器生命周期中 resourceLoader 不变
        [self see_initPlayer];
        _toolsView = [SEEPlayerToolsView playerToolsView];
        _toolsView.delegate = self;
        [self addSubview:_toolsView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _toolsView.frame = self.frame;
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    [super layoutSublayersOfLayer:layer];
    _playerLayer.bounds = layer.bounds;
    _playerLayer.position = layer.position;
}

- (void)dealloc {
    //清除播放器
    [self see_clearPlayer];
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
    //1 播放状态重置
    self.status = SEEPlayerStatusUnknow;
    //2 重新设置item
    AVPlayerItem * newItem = [AVPlayerItem playerItemWithAsset:[_resourceLoaderDelegate assetWithURL:url] automaticallyLoadedAssetKeys:@[@"duration",@"preferredRate",@"preferredVolume",@"preferredTransform"]];
    //3 播放器播放新url之前清除上一次的监听等
    [self see_clearPlayer];
    //4 设置新的item
    [_player replaceCurrentItemWithPlayerItem:newItem];
    //5 添加对播放器的监听
    [self see_preparePlayer];
}

- (void)play {
    self.status = SEEPlayerStatusPlay;
}

- (void)pause {
    self.status = SEEPlayerStatusPause;
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
        _duration = [self see_time:_player.currentItem.duration];
        [self.toolsView setDuration:_duration];
    }
    else {
        //do nothing...
    }
}

#pragma mark SEEPlayerToolsViewDelegate
- (BOOL)playOrPause:(BOOL)isPlay {
    if (isPlay) {
        self.status = SEEPlayerStatusPlay;
    }
    else {
        self.status = SEEPlayerStatusPause;
    }
    return isPlay;
}


- (void)seekToTime:(CGFloat)progress {
    if (_duration == 0) return;
    switch (self.status) {
        case SEEPlayerStatusPlay:
            [_player pause];
            break;
        case SEEPlayerStatusComplete:
            _status = SEEPlayerStatusPause;
            break;
        case SEEPlayerStatusUnknow:
            return;
            break;
            
        default:
            break;
    }
    CMTime newTime = CMTimeMake(_player.currentItem.duration.value * progress, _player.currentItem.duration.timescale);
    __weak typeof(self) weakSelf = self;
    [_player seekToTime:newTime completionHandler:^(BOOL finished) {
        __strong typeof(weakSelf) self = weakSelf;
        if (finished && self.status == SEEPlayerStatusPlay) {
            [self->_player play];
        }
    }];
}

- (void)close {
    if (_responder.didClose) {
        [self.UIDelegate playerDidClose];
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
    [self.layer addSublayer:_playerLayer];
    [self see_preparePlayer];
}

/**
 准备player
 添加player状态监听
 添加对item监听
 */
- (void)see_preparePlayer {
    [_player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    AVPlayerItem * item = _player.currentItem;
    if (item == nil) return;
    [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionNew context:nil];
    //如果用户没有手动暂停播放器则初始化播放器后默认播放
    if (self.status != SEEPlayerStatusPause) {
        self.status = SEEPlayerStatusPlay;
    }
    __weak typeof(self) weakSelf = self;
    _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        __strong typeof(weakSelf) self = weakSelf;
        NSTimeInterval currentTime = [self see_time:time];
        [self.toolsView setCurrentTime:currentTime];
        if (currentTime >= self->_duration && self->_duration != 0) {
            self.status = SEEPlayerStatusComplete;
        }
    }];
}

/**
 清除player
 清除player状态监听
 清除对item监听
 */
- (void)see_clearPlayer {
    if (_player) {
        [_player pause];
        [_player removeObserver:self forKeyPath:@"status"];
        [_player removeTimeObserver:_timeObserver];
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
    if (_status == SEEPlayerStatusComplete) {
        [self seekToTime:0];
    }
    switch (status) {
        case SEEPlayerStatusPlay:
            SEELog(@"开始播放");
            [_player play];
            [_toolsView playOrPause:YES];
            break;
        case SEEPlayerStatusPause:
        case SEEPlayerStatusFailed:
        case SEEPlayerStatusUnknow:
        case SEEPlayerStatusComplete:
            SEELog(@"暂停");
            [_player pause];
            [_toolsView playOrPause:NO];
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

- (void)setUIDelegate:(id<SEEPlayerUIDelegate>)UIDelegate {
    _UIDelegate = UIDelegate;
    _responder.didClose = [UIDelegate respondsToSelector:@selector(playerDidClose)];
}

@end
