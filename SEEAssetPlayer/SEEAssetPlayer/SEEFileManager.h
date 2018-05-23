//
//  SEEFileManager.h
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/4/16.
//  Copyright © 2018年 景彦铭. All rights reserved.
/*
 1.负责数据写入文件以及文件切片存储
 2.负责定时定速将文件中数据推送至接收者
 */

#import <Foundation/Foundation.h>
#import "SEEPlayerMacro.h"
#import "SEEFileInfo.h"
NS_ASSUME_NONNULL_BEGIN

@interface SEEData: NSObject

@property (nonatomic, assign) long long location;

@property (nonatomic, assign) NSUInteger  length;

@property (nonatomic, strong) __kindof NSData * data;

+ (instancetype)dataWithLocation:(long long)location lenght:(NSUInteger)length data:(__kindof NSData *)data;

+ (instancetype)data;

+ (instancetype)mutableData;

- (id)copy;

- (id)mutableCopy;

- (BOOL)isEqual:(id)object;

@end

@protocol SEEFileManagerPushDataObjcet <NSObject>

@optional

/**
 接收数据

 @param data 推送数据以及数据范围
 @return 下一次需要接收的数据起始位置
 */
- (long long)didReceiveData:(const SEEData *)data;

@end

@protocol SEEFileManagerBufferDelegate <NSObject>

/**
 数据缓冲区空
 */
- (void)fileManagerBufferEmpty;

/**
 缓冲区由 空/溢出 转入到正常状态
 */
- (void)fileManagerBufferRegular;

/**
 数据缓冲区溢出
 */
- (void)fileManagerOutOfBuffer;

@end

@interface SEEFileManager : NSObject



- (instancetype)initWithURL:(NSURL *)url bufferdelegate:(id <SEEFileManagerBufferDelegate>)bufferDelegate pushDataDelegate:(id <SEEFileManagerPushDataObjcet>)pushDataDelegate;

@property (nonatomic, copy) NSString * MIMEType;

@property (nonatomic, assign) long long totalBytes;


/**
 将数据写入缓存

 @param data 需要写入的数据
 */
- (void)writeData:(const SEEData *)data;

/**
 写入完成 将文件移动至缓存目录
 */
- (void)cache;

/**
 取消指定url文件的写入
 */
- (void)cancel;

/**
 暂停数据推送
 */
- (void)suspend;

/**
 开始数据推送
 */
- (void)start;

@end

NS_ASSUME_NONNULL_END
