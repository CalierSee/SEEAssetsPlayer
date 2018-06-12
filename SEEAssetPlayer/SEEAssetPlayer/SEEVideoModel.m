//
//  SEEVideoModel.m
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/6/12.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import "SEEVideoModel.h"

@implementation SEEVideoModel

+ (NSArray *)modelsWithNames:(NSArray *)names urls:(NSArray *)urls {
    NSMutableArray * arrayM = [NSMutableArray array];
    for (NSInteger i = 0; i < urls.count; i ++) {
        SEEVideoModel * model = [[self alloc]init];
        [arrayM addObject:model];
        model.url = urls[i];
        model.name = names[i];
    }
    return arrayM.copy;
}

@end
