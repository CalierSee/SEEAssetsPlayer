//
//  SEETableViewCellHeightCache.h
//  UITableViewCellHeightCache
//
//  Created by 三只鸟 on 2018/3/7.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSNumber (CGFLoatValue)

- (CGFloat)CGFloatValue;

@end

@interface SEETableViewCellHeightCache : NSObject

//竖屏状态缓存
@property (nonatomic, strong) NSMutableDictionary * heightV;

//横屏状态缓存
@property (nonatomic, strong) NSMutableDictionary * heightH;

//返回当前屏幕状态对应的缓存
- (NSMutableDictionary *)currentHeight;

/**
 查找缓存
 @return 如果没有缓存返回 CGFLOAT_MAX
 */
- (CGFloat)heightWithSection:(NSInteger)section row:(NSInteger)row;

/**
 设置缓存
 */
- (void)setHeight:(CGFloat)height section:(NSInteger)section row:(NSInteger)row;

- (void)insertSection:(NSInteger)section;
- (void)insertRow:(NSInteger)row inSection:(NSInteger)section;

- (void)deleteSection:(NSInteger)section;
- (void)deleteRow:(NSInteger)row inSection:(NSInteger)section;

- (void)reloadSection:(NSInteger)section;
- (void)reloadRow:(NSInteger)row inSection:(NSInteger)section;
- (void)reloadAll;

- (void)moveSection:(NSInteger)section toSection:(NSInteger)tSection;
- (void)moveRow:(NSInteger)row inSection:(NSInteger)section toRow:(NSInteger)tRow inSection:(NSInteger)tSection;

@end
