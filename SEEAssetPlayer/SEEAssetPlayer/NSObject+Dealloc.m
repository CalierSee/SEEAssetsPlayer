//
//  NSObject+Dealloc.m
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/5/15.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import "NSObject+Dealloc.h"
#import <objc/runtime.h>
@implementation NSObject (Dealloc)

+ (void)load {
    SEL dealloc = NSSelectorFromString(@"dealloc");
    Method m1 = class_getInstanceMethod(self, dealloc);
    Method m2 = class_getInstanceMethod(self, @selector(see_dealloc));
    method_exchangeImplementations(m1, m2);
}

- (void)see_dealloc {
    if ([NSStringFromClass([self class]) hasPrefix:@"SEE"]) {
//        NSLog(@"dealloc %@",NSStringFromClass([self class]));
    }
    [self see_dealloc];
}


@end
