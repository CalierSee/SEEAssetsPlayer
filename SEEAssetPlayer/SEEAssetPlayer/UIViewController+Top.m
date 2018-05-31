//
//  UIViewController+Top.m
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/5/31.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import "UIViewController+Top.h"

@implementation UIViewController (Top)

    + (UIViewController *)topViewController {
        //找到根视图
        UIViewController * rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        return [rootVC see_topViewController];
    }

    - (UIViewController *)see_topViewController {
        //首先查询当前控制器是否模态出了另一个控制器，如果有则使用模态出的控制器查询
        if (self.presentedViewController) {
            return [self.presentedViewController see_topViewController];
        }
        //如果当前控制器是TabBarController则使用当前选中的控制器查询
        else if ([self isKindOfClass:[UITabBarController class]]) {
            return [((UITabBarController *)self).selectedViewController see_topViewController];
        }
        //如果当前控制器是NavigationController则使用栈顶的控制器来查询
        else if ([self isKindOfClass:[UINavigationController class]]) {
            /*关于visibleViewController和topViewController
             visibleViewcontroller 当前可见的控制器，可能是由topViewController模态出的控制器
             topViewController 栈顶控制器
            */
            return [((UINavigationController *)self).topViewController see_topViewController];
        }
        else {
                return self;
        }
    }

@end
