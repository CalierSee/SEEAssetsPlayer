//
//  SEEDownloader.h
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/4/14.
//  Copyright © 2018年 景彦铭. All rights reserved.
/*
 负责数据的下载
 */

    #import <Foundation/Foundation.h>

    NS_ASSUME_NONNULL_BEGIN

    @protocol SEEDownloaderDelegate <NSObject>

    @optional

    /**
     接收到响应

     @param response 响应体对象
     */
    - (void)didReceiveResponse:(NSURLResponse *)response;

    /**
     传输完成

     @param error 错误信息，如果传输正常完成该项为nil
     */
    - (void)didCompleteWithError:(NSError * _Nullable)error;

    /**
     接收数据

     @param data 数据
     */
    - (void)didreceiveData:(NSData *)data;

    @end


    @interface SEEDownloader : NSObject

    @property (nonatomic, assign) long long startOffset;

    @property (nonatomic, assign) long long currentOffset;

    @property (nonatomic, assign) long long endOffset;

    //初始化
    - (instancetype)initWithURL:(NSURL *)url delegate:(id<SEEDownloaderDelegate>)delegate;

    /**
     从 offset 位置开始重新请求文件

     @param offset 起始 offset
     */
    - (void)resetWithStartOffset:(long long)offset endOffset:(long long)endOffset;

    //取消下载，清除资源
    - (void)invalidateAndCancel;

    @end

    NS_ASSUME_NONNULL_END
