//
//  SEEPlayerView.h
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/5/8.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SEEPlayerViewReturnButtonType) {
    SEEPlayerViewReturnButtonTypeNone,
    SEEPlayerViewReturnButtonTypeReturn,
    SEEPlayerViewReturnButtonTypeClose,
};

@class SEEPlayerView;

@protocol SEEPlayerToolsUIDelegate <NSObject>

@required
/**
 播放器关闭
 */
- (void)playerDidClose;


@optional
/**
 全屏小屏切换
 注意，默认实现了切换。如果实现了以下方法则不再提供全屏小屏切换，需要自己实现
 */
- (void)fullScreen:(SEEPlayerView *)player;
/**
 全屏小屏切换
 注意，默认实现了切换。如果实现了以下方法则不再提供全屏小屏切换，需要自己实现
 */
- (void)smallScreen:(SEEPlayerView *)player;

@end

@interface SEEPlayerView : UIView

@property (weak, nonatomic,readonly)UIPanGestureRecognizer *panGesture;

+ (instancetype)playerView;

- (void)setURL:(NSURL *)url;

- (void)setURL:(NSURL *)url title:(NSString *)title;

@property (nonatomic, assign) SEEPlayerViewReturnButtonType returnType;

@property (nonatomic, assign, readonly, getter = isFullScreen) BOOL fullScreen;

- (void)pause;

- (void)play;

@end
