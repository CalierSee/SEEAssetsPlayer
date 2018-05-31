//
//  UITableView+HeightCache.h
//  UITableViewCellHeightCache
//
//  Created by 三只鸟 on 2018/3/5.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SEETableViewCellHeightCache.h"

@interface UITableView (HeightCache)


@property (nonatomic, strong,readonly) SEETableViewCellHeightCache * heightCache;

+ (void)cacheEnabled:(BOOL)enabled;

- (CGFloat)heightForCellWithIdentifier:(NSString *)identifier indexPath:(NSIndexPath *)indexPath configuration:(void(^)(__kindof UITableViewCell * cell))configuration;

@end
