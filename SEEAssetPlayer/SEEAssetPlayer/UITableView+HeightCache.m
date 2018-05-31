//
//  UITableView+HeightCache.m
//  UITableViewCellHeightCache
//
//  Created by 三只鸟 on 2018/3/5.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import "UITableView+HeightCache.h"
#import <objc/runtime.h>

static BOOL tableViewCacheEnabled = NO;
static void * tableViewRunloopCacheEnabled = "runloopCacheEnabled";
static void * heightCacheKey = @"heightCache";
static void * cellCacheKey = @"cellCache";

void runLoopObserverCallBack (CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    if (activity == kCFRunLoopBeforeWaiting) {
        CFMutableDictionaryRef m_dict = info;
        //获取tableView
        UITableView * tableView = (__bridge UITableView *)CFDictionaryGetValue(m_dict, "tableView");
        //获取当前需要计算的indexPath
        NSInteger section = (NSInteger)CFDictionaryGetValue(m_dict, "section");
        NSInteger row = (NSInteger)CFDictionaryGetValue(m_dict, "row");
#ifdef DEBUG
        NSLog(@"section: %zd,  row:%zd",section,row);
#endif
        if (tableView.dataSource == nil) return;
        if (section < [tableView.dataSource numberOfSectionsInTableView:tableView]) {
            if (row < [tableView.dataSource tableView:tableView numberOfRowsInSection:section]) {
                //获取高度并缓存
                [tableView.delegate tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
                row ++;
            }
            else {
                row = 0;
                section ++;
            }
            //设置下一次需要获取的高度indexPath
            CFDictionarySetValue(m_dict, "section", (const void *)section);
            CFDictionarySetValue(m_dict, "row", (const void *)row);
            //唤醒runloop  目的：在每缓存一行高度之后唤醒runloop处理timer、source等事件防止遍历过程中阻塞主线程
            CFRunLoopWakeUp(CFRunLoopGetCurrent());
        }
        else {
            //高度缓存全部完成 将observer移除
            CFRunLoopRemoveObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopDefaultMode);
            objc_setAssociatedObject(tableView, tableViewRunloopCacheEnabled, @(NO), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

@interface UITableView()

@property (nonatomic, strong) SEETableViewCellHeightCache * heightCache;

@end

@implementation UITableView (HeightCache)


#pragma mark public method

+ (void)cacheEnabled:(BOOL)enabled {
    if (tableViewCacheEnabled == enabled) return;
    tableViewCacheEnabled = enabled;
    //move
    Method m1 = class_getInstanceMethod([self class], @selector(moveRowAtIndexPath:toIndexPath:));
    Method m2 = class_getInstanceMethod([self class], @selector(see_moveRowAtIndexPath:toIndexPath:));
    method_exchangeImplementations(m1, m2);
    m1 = class_getInstanceMethod([self class], @selector(moveSection:toSection:));
    m2 = class_getInstanceMethod([self class], @selector(see_moveSection:toSection:));
    method_exchangeImplementations(m1, m2);
    //delete
    m1 = class_getInstanceMethod([self class], @selector(deleteSections:withRowAnimation:));
    m2 = class_getInstanceMethod([self class], @selector(see_deleteSections:withRowAnimation:));
    method_exchangeImplementations(m1, m2);
    m1 = class_getInstanceMethod([self class], @selector(deleteRowsAtIndexPaths:withRowAnimation:));
    m2 = class_getInstanceMethod([self class], @selector(see_deleteRowsAtIndexPaths:withRowAnimation:));
    method_exchangeImplementations(m1, m2);
    //insert
    m1 = class_getInstanceMethod([self class], @selector(insertRowsAtIndexPaths:withRowAnimation:));
    m2 = class_getInstanceMethod([self class], @selector(see_insertRowsAtIndexPaths:withRowAnimation:));
    method_exchangeImplementations(m1, m2);
    m1 = class_getInstanceMethod([self class], @selector(insertSections:withRowAnimation:));
    m2 = class_getInstanceMethod([self class], @selector(see_insertSections:withRowAnimation:));
    method_exchangeImplementations(m1, m2);
    //reload
    m1 = class_getInstanceMethod([self class], @selector(reloadSections:withRowAnimation:));
    m2 = class_getInstanceMethod([self class], @selector(see_reloadSections:withRowAnimation:));
    method_exchangeImplementations(m1, m2);
    m1 = class_getInstanceMethod([self class], @selector(reloadRowsAtIndexPaths:withRowAnimation:));
    m2 = class_getInstanceMethod([self class], @selector(see_reloadRowsAtIndexPaths:withRowAnimation:));
    method_exchangeImplementations(m1, m2);
    m1 = class_getInstanceMethod([self class], @selector(reloadData));
    m2 = class_getInstanceMethod([self class], @selector(see_reloadData));
    method_exchangeImplementations(m1, m2);
}


    - (CGFloat)heightForCellWithIdentifier:(NSString *)identifier indexPath:(NSIndexPath *)indexPath configuration:(void (^)(__kindof UITableViewCell *))configuration {
        if (!tableViewCacheEnabled) @throw [NSException exceptionWithName:@"高度返回错误" reason:@"无法再未开启缓存的情况下调用该方法 请使用 + (void)cacheEnabled:(BOOL)enabled 并设置enabled为YES" userInfo:nil];
        CGFloat height = 0;
        if (indexPath && identifier.length != 0) {
            //查找缓存
            height = [self.heightCache heightWithSection:indexPath.section row:indexPath.row];
            //缓存没有则计算
            if (height == CGFLOAT_MAX) {
                height = [self see_calculateForCellWithIdentifier:identifier configuration:configuration];
                [self.heightCache setHeight:height section:indexPath.section row:indexPath.row];
                //添加observer 当runloop即将休眠时计算行高
                if (((NSNumber *)objc_getAssociatedObject(self, tableViewRunloopCacheEnabled)).boolValue == NO){
                    objc_setAssociatedObject(self, tableViewRunloopCacheEnabled, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                    //获取当前runloop
                    CFRunLoopRef runloop = CFRunLoopGetCurrent();
                    __weak typeof(self) weakSelf = self;
                    //创建字典 记录当前tableView 以及缓存indexPath
                    CFMutableDictionaryRef m_dict = CFDictionaryCreateMutable(NULL, 3, NULL, NULL);
                    NSInteger section = indexPath.section;
                    NSInteger row = indexPath.row;
                    CFDictionaryAddValue(m_dict, "section", (const void *)section);
                    CFDictionaryAddValue(m_dict, "row", (const void *)row);
                    CFDictionaryAddValue(m_dict, "tableView", (__bridge void *)weakSelf);
                    //创建context
                    CFRunLoopObserverContext context = {.info = m_dict};
                    //创建observer
                    CFRunLoopObserverRef observer = CFRunLoopObserverCreate(NULL, kCFRunLoopBeforeWaiting, YES, 10, &runLoopObserverCallBack, &context);
                    //添加observer 在runloop空闲时计算高度
                    CFRunLoopAddObserver(runloop, observer, kCFRunLoopDefaultMode);
                }
            }
        }
        return height;
    }
#pragma mark private method
//计算高度
- (CGFloat)see_calculateForCellWithIdentifier:(NSString *)identifier configuration:(void(^)(UITableViewCell * cell))configuration {
    //根据identifier获取cell
    UITableViewCell * cell = [self see_cellWithidentifier:identifier];
    if (cell)
        configuration(cell);
    else
        return 0;
    CGFloat width = self.bounds.size.width;
    //根据辅助视图校正width
    if (cell.accessoryView) {
        width -= cell.accessoryView.bounds.size.width + 16;
    }
    else
    {
        static const CGFloat accessoryWidth[] = {
            [UITableViewCellAccessoryNone] = 0,
            [UITableViewCellAccessoryDisclosureIndicator] = 34,
            [UITableViewCellAccessoryDetailDisclosureButton] = 68,
            [UITableViewCellAccessoryCheckmark] = 40,
            [UITableViewCellAccessoryDetailButton] = 48
        };
        width -= accessoryWidth[cell.accessoryType];
    }
    CGFloat height = 0;
    //使用autoLayout计算
    if (width > 0) {
        BOOL autoresizing = cell.contentView.translatesAutoresizingMaskIntoConstraints; cell.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        //为cell的contentView添加宽度约束
        NSLayoutConstraint * constraint = [NSLayoutConstraint constraintWithItem:cell.contentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:width];
        [cell.contentView addConstraint:constraint];
        height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
        [cell.contentView removeConstraint:constraint];
        cell.contentView.translatesAutoresizingMaskIntoConstraints = autoresizing;
    }
    //如果使用autoLayout计算失败则使用autoResizing
    if (height == 0) {
        height = [cell sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)].height;
    }
    //如果使用autoResizing计算失败则返回默认
    if (height == 0) {
        height = 44;
    }
    if (self.separatorStyle != UITableViewCellSeparatorStyleNone) {//如果不为无分割线模式则添加分割线高度
        height += 1.0 /[UIScreen mainScreen].scale;
    }
    return height;
}

//返回用于计算高度的cell
- (__kindof UITableViewCell *)see_cellWithidentifier:(NSString *)identifier {
    //从cell缓存中使用指定identifier获取cell
    NSMutableDictionary * cellCache = objc_getAssociatedObject(self, cellCacheKey);
    if (cellCache == nil) {
        cellCache = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, cellCacheKey, cellCache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UITableViewCell * cell = [cellCache objectForKey:identifier];
    //如果cell缓存中没有 则从重用池中获取 并加入cell缓存
    if (!cell) {
        ////从重用池中取一个cell用来计算，必须以本方式从重用池中取，若以indexPath方式取由于-heightForRowAtIndexPath方法会造成循环
        cell = [self dequeueReusableCellWithIdentifier:identifier];
        [cellCache setObject:cell forKey:identifier];
    }
    return cell;
}

- (void)see_insertSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    [sections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [self.heightCache insertSection:idx];
    }];
    [self see_insertSections:sections withRowAnimation:animation];
}

- (void)see_insertRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    //对indexPath进行升序排序
    NSArray * sortResult = [indexPaths sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *  _Nonnull obj1, NSIndexPath *  _Nonnull obj2) {
        if (obj1.section == obj2.section) {
            if (obj1.row == obj2.row) {
                return NSOrderedSame;
            }
            else if (obj1.row > obj2.row) {
                return NSOrderedDescending;
            }
            else {
                return NSOrderedAscending;
            }
        }
        else if (obj1.section > obj2.section) {
            return NSOrderedDescending;
        }
        else {
            return NSOrderedAscending;
        }
    }];
    [sortResult enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.heightCache insertRow:obj.row inSection:obj.section];
    }];
    [self see_insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)see_deleteSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    //倒序删除对应section
    [sections enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [self.heightCache deleteSection:idx];
    }];
    [self see_deleteSections:sections withRowAnimation:animation];
}

- (void)see_deleteRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    //对indexPath进行升序排序
    NSArray * sortResult = [indexPaths sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *  _Nonnull obj1, NSIndexPath *  _Nonnull obj2) {
        if (obj1.section == obj2.section) {
            if (obj1.row == obj2.row) {
                return NSOrderedSame;
            }
            else if (obj1.row > obj2.row) {
                return NSOrderedDescending;
            }
            else {
                return NSOrderedAscending;
            }
        }
        else if (obj1.section > obj2.section) {
            return NSOrderedDescending;
        }
        else {
            return NSOrderedAscending;
        }
    }];
    //倒序删除对应indexPath数据
    [sortResult enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSIndexPath *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.heightCache deleteRow:obj.row inSection:obj.section];
    }];
    [self see_deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)see_reloadRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.heightCache reloadRow:obj.row inSection:obj.section];
    }];
    [self see_reloadRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)see_reloadSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    [sections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [self.heightCache reloadSection:idx];
    }];
    [self see_reloadSections:sections withRowAnimation:animation];
}

- (void)see_reloadData {
    [self.heightCache reloadAll];
    [self see_reloadData];
}

- (void)see_moveSection:(NSInteger)section toSection:(NSInteger)newSection {
    [self.heightCache moveSection:section toSection:newSection];
    [self see_moveSection:section toSection:newSection];
}

- (void)see_moveRowAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath {
    [self.heightCache moveRow:indexPath.row inSection:indexPath.section toRow:newIndexPath.row inSection:newIndexPath.section];
    [self see_moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
}

#pragma mark getter & setter

- (SEETableViewCellHeightCache *)heightCache {
    if (objc_getAssociatedObject(self, heightCacheKey) == nil) {
        SEETableViewCellHeightCache * cache = [[SEETableViewCellHeightCache alloc]init];
        objc_setAssociatedObject(self, heightCacheKey, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return objc_getAssociatedObject(self, heightCacheKey);
}



@end
