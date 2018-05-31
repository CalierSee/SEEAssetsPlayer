//
//  SEETableViewCellHeightCache.m
//  UITableViewCellHeightCache
//
//  Created by 三只鸟 on 2018/3/7.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import "SEETableViewCellHeightCache.h"

@implementation NSNumber (CGFLoatValue)

- (CGFloat)CGFloatValue {
    if ([self is64bit]) {
        return self.doubleValue;
    }
    else {
        return self.floatValue;
    }
}

///64位判断
- (BOOL)is64bit
{
#if defined(__LP64__) && __LP64__
    return YES;
#else
    return NO;
#endif
}

@end
//返回指定 cache 中 指定 section row 的缓存值
#define cacheValue(t_cache,t_section,t_row) [[t_cache objectForKey:@(t_section).description] objectForKey:@(t_row).description]
//返回指定缓存中的 index值  index标识当前已缓存的下标
#define currentIndex(dictionary) ((NSNumber *)[dictionary objectForKey:@"-1"]).integerValue
//设置index值
#define setCurrentIndex(dictionary,index) [dictionary setObject:@(index) forKey:@"-1"]

#define key(t_index) @(t_index).description

@implementation SEETableViewCellHeightCache

#pragma mark public method

- (CGFloat)heightWithSection:(NSInteger)section row:(NSInteger)row {
    NSNumber * height = cacheValue(self.currentHeight,section, row);
    //返回缓存高度
    if (height) {
#ifdef DEBUG
        NSLog(@"%zd-%zd缓存:%lf",section,row,height.CGFloatValue);
#endif
        return height.CGFloatValue;
    }
    else {
        return CGFLOAT_MAX;
    }
}

//外界设置缓存值唯一方法
- (void)setHeight:(CGFloat)height section:(NSInteger)section row:(NSInteger)row {
    //取对应组的缓存
    NSMutableDictionary * sectionCache = [self.currentHeight objectForKey:key(section)];
    //如果没有取到则初始化一组
    if (sectionCache == nil) {
        sectionCache = [self see_initSection:section];
    }
    //初始化一行
    [self see_initRow:row cache:sectionCache];
    [sectionCache setObject:@(height) forKey:key(row)];
}

- (void)insertSection:(NSInteger)section {
    [self see_insertIndex:section cache:self.heightH];
    [self see_insertIndex:section cache:self.heightV];
}

- (void)insertRow:(NSInteger)row inSection:(NSInteger)section {
    [self see_insertIndex:row cache:[self.heightV objectForKey:key(section)]];
    [self see_insertIndex:row cache:[self.heightH objectForKey:key(section)]];
}

- (void)deleteSection:(NSInteger)section {
    [self see_deleteIndex:section cache:self.heightH];
    [self see_deleteIndex:section cache:self.heightV];
}

- (void)deleteRow:(NSInteger)row inSection:(NSInteger)section {
    [self see_deleteIndex:row cache:[self.heightV objectForKey:key(section)]];
    [self see_deleteIndex:row cache:[self.heightH objectForKey:key(section)]];
}

- (void)reloadSection:(NSInteger)section {
    [self see_reloadIndex:section cache:self.heightV];
    [self see_reloadIndex:section cache:self.heightH];
}

- (void)reloadRow:(NSInteger)row inSection:(NSInteger)section {
    [self see_reloadIndex:row cache:[self.heightV objectForKey:key(section)]];
    [self see_reloadIndex:row cache:[self.heightH objectForKey:key(section)]];
}

- (void)reloadAll {
    [self see_reloadIndex:NSIntegerMax cache:self.heightV];
    [self see_reloadIndex:NSIntegerMax cache:self.heightH];
}

- (void)moveSection:(NSInteger)section toSection:(NSInteger)tSection {
    [self see_moveIndex:section toIndex:tSection cache:self.heightH];
    [self see_moveIndex:section toIndex:tSection cache:self.heightV];
}

- (void)moveRow:(NSInteger)row inSection:(NSInteger)section toRow:(NSInteger)tRow inSection:(NSInteger)tSection {
    if (section == tSection) {
        //组内交换
        [self see_moveIndex:row toIndex:tRow cache:[self.heightH objectForKey:key(section)]];
        [self see_moveIndex:row toIndex:tRow cache:[self.heightV objectForKey:key(section)]];
    }
    else {
        //组外交换
        NSNumber * tempH = [[self.heightH objectForKey:key(section)] objectForKey:key(row)];
        NSNumber * tempV = [[self.heightV objectForKey:key(section)] objectForKey:key(row)];
        //1.将目标缓存删除
        [self deleteRow:row inSection:section];
        //2.在目标组中插入一行
        [self insertRow:tRow inSection:tSection];
        //3.赋值
        [[self.heightH objectForKey:key(tSection)] setObject:tempH forKey:key(tRow)];
        [[self.heightV objectForKey:key(tSection)] setObject:tempV forKey:key(tRow)];
        
    }
}


#pragma mark private method
- (NSMutableDictionary *)see_initSection:(NSInteger)section {
    //创建组
    NSMutableDictionary * newSection = [NSMutableDictionary dictionaryWithObjectsAndKeys:@(-1),@"-1", nil];
    [self.currentHeight setObject:newSection forKey:key(section)];
    //如果组号大于当前记录的最大值 则修改最大值
    NSInteger sectionLastIndex = currentIndex(self.currentHeight);
    if (sectionLastIndex < section) {
        setCurrentIndex(self.currentHeight, section);
    }
    return newSection;
}

- (void)see_initRow:(NSInteger)row cache:(NSMutableDictionary *)cache {
    //如果行号大于当前记录的最大值 则修改最大值
    NSInteger rowLastIndex = currentIndex(cache);
    if (rowLastIndex < row) {
        setCurrentIndex(cache, row);
    }
}

- (void)see_moveIndex:(NSInteger)index toIndex:(NSInteger)tIndex cache:(NSMutableDictionary *)cache {
    BOOL dir = tIndex > index;
    for (NSInteger i = index; i != tIndex; dir ? i++ : i--) {
        [self see_exchangeIndex:i withIndex:dir ? (i + 1) : (i - 1) cache:cache];
    }
}

- (void)see_reloadIndex:(NSInteger)index cache:(NSMutableDictionary *)cache {
    if (index == NSIntegerMax) {//删除全部缓存
        [cache removeAllObjects];
        setCurrentIndex(cache, -1);
    }
    else {//删除对应index的缓存并重新设置section/row最大值
        [cache removeObjectForKey:key(index)];
        NSArray * keys = [cache.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *  _Nonnull obj1, NSString *  _Nonnull obj2) {
            if (obj1.integerValue > obj2.integerValue) {
                return NSOrderedDescending;
            }
            else if (obj1.integerValue < obj2.integerValue) {
                return NSOrderedSame;
            }
            else {
                return NSOrderedSame;
            }
        }];
        setCurrentIndex(cache, ((NSString *)keys.lastObject).integerValue);
    }
}

- (void)see_deleteIndex:(NSInteger)index cache:(NSMutableDictionary *)cache {
    NSInteger lastIndex = currentIndex(cache);
    if (lastIndex < 0) return;
    //将指定index的数据移动到末尾
    [self see_moveIndex:index toIndex:lastIndex cache:cache];
    //将末尾数据删除
    [cache removeObjectForKey:key(lastIndex)];
    //更新index最大值
    NSArray * keys = [cache.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *  _Nonnull obj1, NSString *  _Nonnull obj2) {
        if (obj1.integerValue > obj2.integerValue) {
            return NSOrderedDescending;
        }
        else if (obj1.integerValue < obj2.integerValue) {
            return NSOrderedSame;
        }
        else {
            return NSOrderedSame;
        }
    }];
    setCurrentIndex(cache, ((NSString *)keys.lastObject).integerValue);
}

- (void)see_insertIndex:(NSInteger)index cache:(NSMutableDictionary *)cache {
    NSInteger lastIndex = currentIndex(cache);
    if (lastIndex < 0) return;
    for (NSInteger i = lastIndex; i >= index; i--) {
        [self see_exchangeIndex:i withIndex:i + 1 cache:cache];
    }
    //如果section/row小于当前缓存坐标 则 坐标+1  如果大于则等待设置缓存值初始化组时设置
    if (lastIndex >= index) {
        setCurrentIndex(cache, lastIndex + 1);
        [cache removeObjectForKey:key(index)];
    }
}


/**
 交换
 @param cache 存储交换的两个元素的缓存字典
 */
- (void)see_exchangeIndex:(NSInteger)index withIndex:(NSInteger)wIndex cache:(NSMutableDictionary *)cache {
    NSMutableDictionary * from = [cache objectForKey:key(index)];
    NSMutableDictionary * to = [cache objectForKey:key(wIndex)];
    //如果交换的数据同时为空不进行任何操作
    if (!(from && to)) return;
    if (from) {
        [cache setObject:from forKey:key(wIndex)];
    }
    else {
        [cache removeObjectForKey:key(wIndex)];
    }
    if (to) {
        [cache setObject:to forKey:key(index)];
    }
    else {
        [cache removeObjectForKey:key(index)];
    }
}

#pragma mark getter & setter
- (NSMutableDictionary *)heightH {
    if (_heightH == nil) {
        _heightH = [NSMutableDictionary dictionary];
        [_heightH setObject:@(-1) forKey:@"-1"];
    }
    return _heightH;
}

- (NSMutableDictionary *)heightV {
    if (_heightV == nil) {
        _heightV = [NSMutableDictionary dictionary];
        [_heightV setObject:@(-1) forKey: @"-1"];
    }
    return _heightV;
}

- (NSMutableDictionary *)currentHeight {
    return UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation) ? self.heightV : self.heightH;
}

@end
