//
//  SEEPlayerFullScreenSupportViewController.h
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/5/25.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SEEPlayerView;
@class SEEPlayerFullScreenSupportViewController;

@protocol SEEPlayerFullScreenSupportViewControllerDelegate <NSObject>

/**
 全屏视图支持的旋转方向

 @param vc 控制器
 @return 支持的旋转方向
 */
- (UIInterfaceOrientationMask)fullScreenSupportedInterfaceOrientations:(SEEPlayerFullScreenSupportViewController *)vc;

//- (void)present

@end


@interface SEEPlayerFullScreenSupportViewController : UIViewController

- (instancetype)initWithPlayer:(SEEPlayerView *)player;



@property (nonatomic, assign) id <SEEPlayerFullScreenSupportViewControllerDelegate> delegate;


@end
