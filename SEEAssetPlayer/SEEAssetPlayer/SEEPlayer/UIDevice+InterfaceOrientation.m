//
//  UIDevice+InterfaceOrientation.m
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/6/5.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import "UIDevice+InterfaceOrientation.h"

@implementation UIDevice (InterfaceOrientation)

+ (void)switchNewOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    
    NSNumber *resetOrientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationUnknown];
    
    [[UIDevice currentDevice] setValue:resetOrientationTarget forKey:@"orientation"];
    
    NSNumber *orientationTarget = [NSNumber numberWithInt:interfaceOrientation];
    
    [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
    
}

@end
