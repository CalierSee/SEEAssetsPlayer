//
//  SEEDataManager.h
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/5/9.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const cacheRangesChangeNotification;

    @interface SEEData: NSObject
    //数据起始位置
    @property (nonatomic, assign, readonly) long long location;
    //数据长度
    @property (nonatomic, assign, readonly) NSUInteger  length;
    //数据结束位置
    @property (nonatomic, assign, readonly) long long end;
    //数据
    @property (nonatomic, strong, readonly) __kindof NSData * data;

    + (instancetype)dataWithLocation:(long long)location lenght:(NSUInteger)length data:(__kindof NSData *)data;


    /**
     拼接数据
     只有通过mutableData创建的对象可以使用该方法
     @param data 数据
     @param length 长度
     */
    - (void)appendData:(const void *)data length:(NSUInteger)length;

    /**
     初始化指定offset之前的数据
     只有通过mutableData创建的对象可以使用该方法
     @param offset offset
     */
    - (void)initOffset:(long long)offset;

    + (instancetype)data;

    + (instancetype)mutableData;

    - (id)copy;

    - (id)mutableCopy;

    - (BOOL)isEqual:(id)object;

    @end

@interface SEEInputStream: NSObject

- (void)setFileAtPath:(NSString *)path;

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len startOffset:(long long)startOffset;

@end

typedef NS_ENUM(NSUInteger, SEEDataManagerState) {
    SEEDataManagerStateInit,
    SEEDataManagerStateBegin,
};

@protocol SEEDataManagerDelegate <NSObject>

- (long long)didReceiveData:(SEEData *)data;

@end

@interface SEEDataManager : NSObject

@property (nonatomic, assign) long long  totalBytes;

@property (nonatomic, copy) NSString * MIMEType;

@property (nonatomic, assign) SEEDataManagerState state;


- (instancetype)initWithURL:(NSURL *)url delegate:(id <SEEDataManagerDelegate>)delegate;


/**
 磁盘缓存文件对应的数据范围
 NSRange
 */
@property (nonatomic,strong,readonly) NSMutableArray<NSValue *> *cacheRanges;

/**
 开始推送
 */
- (void)begin;

/**
 结束推送
 */
- (void)stop;

@end
