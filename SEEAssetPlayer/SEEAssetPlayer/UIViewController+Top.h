//
//  UIViewController+Top.h
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/5/31.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Top)

/**
 返回当前正在展示的控制器

 @return 正在展示的控制器
 */
+ (UIViewController *)topViewController;

@end
