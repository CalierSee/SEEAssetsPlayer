//
//  SEEResourceLoader.m
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/4/14.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import "SEEResourceLoaderDelegate.h"
#import "SEEDataManager.h"
#import <AVFoundation/AVFoundation.h>
#import "SEEPlayerMacro.h"
@interface SEEResourceLoaderDelegate () <AVAssetResourceLoaderDelegate,SEEDataManagerDelegate>

@property (nonatomic, strong) NSMutableArray * loadingRequests;


@end

@implementation SEEResourceLoaderDelegate {
    SEEDataManager * _dataManager;
    NSURL * _url;
    dispatch_queue_t _queue;
}

- (AVURLAsset *)assetWithURL:(NSURL *)url {
    if (_dataManager) {
        [_dataManager stop];
        _dataManager = nil;
    }
    _url = url;
    NSURLComponents * components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
    //替换scheme
    components.scheme = @"seeplayer";
    NSURL * target = [components URL];
    //使用替换后的url创建AVURLAssets
    AVURLAsset * asset = [AVURLAsset assetWithURL:target];
    //为了防止阻塞主线程，我们新建一个串行队列来接收代理回调
    [asset.resourceLoader setDelegate:self queue:self.queue];
    //创建下载器
    _dataManager = [[SEEDataManager alloc]initWithURL:url delegate:self];
    return asset;
}

- (void)dealloc {
    [_dataManager stop];
    _dataManager = nil;
}

#pragma mark private method
- (long long)see_expectOffset {
    //获取最新的loadingRequest的currentOffset即可
    if (self.loadingRequests.count != 0) {
        return ((AVAssetResourceLoadingRequest *)self.loadingRequests.lastObject).dataRequest.currentOffset;
    }
    return 0;
}


#pragma mark AVAssetResourceLoaderDelegate
//接收到数据请求
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    //    Thread; //子线程
    //将request添加进数组记录，得到数据后进行填充
    [self.loadingRequests addObject:loadingRequest];
    SEELog(@"接收到loadingRequest  %p\n requestOffset = %lld  requestLength = %lu",loadingRequest,loadingRequest.dataRequest.requestedOffset,loadingRequest.dataRequest.requestedLength);
    //dataManager开始准备推送数据
    [_dataManager begin];
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    //移除被取消的loadingRequest
    [self.loadingRequests removeObject:loadingRequest];
    SEELog(@"移除loadingRequest %p \n requestOffset = %lld  requestLength = %lu  currentOffset = %lld",&loadingRequest,loadingRequest.dataRequest.requestedOffset,loadingRequest.dataRequest.requestedLength,loadingRequest.dataRequest.currentOffset);
    
}


#pragma mark SEEDataManagerDelegate

//接收数据填充
- (long long)didReceiveData:(SEEData *)data {
    long long startOffset = data.location;
    NSUInteger length = data.length;
    long long endOffset = data.end;
    NSMutableData * targetData = data.data;
    //已经填充完成的request
    NSMutableSet * finishRequest = [NSMutableSet set];
    [self.loadingRequests enumerateObjectsUsingBlock:^(AVAssetResourceLoadingRequest *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        long long requestCurrentOffset = obj.dataRequest.currentOffset;
        long long requestEndOffset = obj.dataRequest.requestedOffset + obj.dataRequest.requestedLength;
        //如果当前请求数据起始位置在本次提供数据之后/之前则不做处理
        if (requestCurrentOffset > startOffset + length || requestCurrentOffset < startOffset) {
            return;
        }
        //请求中剩余期望长度起始位置位于本次提供数据片段中相对于起始位置的偏移量
        long long acceptOffset = requestCurrentOffset - startOffset;
        //请求中数据包含期望数据的长度
        NSUInteger acceptLength = 0;
        BOOL hadFinish = NO;
        if (requestEndOffset <= endOffset) {
            //如果请求结束位置在本次数据片段之内
            acceptLength = (NSUInteger)requestEndOffset - (NSUInteger)requestCurrentOffset;
            hadFinish = YES;
        }
        else {
            acceptLength = (NSUInteger)endOffset - (NSUInteger)requestCurrentOffset;
        }
        if (acceptLength) {
            NSData * subData = [targetData subdataWithRange:NSMakeRange((NSUInteger)acceptOffset, acceptLength)];
            [obj.dataRequest respondWithData:subData];
            SEELog(@"填充loadingRequest  %lu \n requestOffset = %lld  requestLength = %lu  currentOffset = %lld",acceptLength,obj.dataRequest.requestedOffset,obj.dataRequest.requestedLength,obj.dataRequest.currentOffset);
        }
        if (obj.contentInformationRequest) {
            obj.contentInformationRequest.contentType = self->_dataManager.MIMEType;
            //========这里的长度指的是文件的总长度=========//
            obj.contentInformationRequest.contentLength = self->_dataManager.totalBytes;
            obj.contentInformationRequest.byteRangeAccessSupported = YES;
        }
        if (hadFinish) {
            [finishRequest addObject:obj];
        }
    }];
    //将填充完成的请求结束
    [finishRequest enumerateObjectsUsingBlock:^(AVAssetResourceLoadingRequest *  _Nonnull obj, BOOL * _Nonnull stop) {
        [obj finishLoading];
        [self.loadingRequests removeObject:obj];
        SEELog(@"完成loadingRequest\n requestOffset = %lld  requestLength = %lu  currentOffset = %lld",obj.dataRequest.requestedOffset,obj.dataRequest.requestedLength,obj.dataRequest.currentOffset);
    }];
    
    return [self see_expectOffset];
}

#pragma mark getter & setter

/**
 串行队列
 
 @return 这个队列用于执行接收播放器发出的resourceLoader、下载器接收回调、文件管理器推送数据
 */
- (dispatch_queue_t)queue {
    if (_queue) {
        return _queue;
    }
    _queue = dispatch_queue_create("player", DISPATCH_QUEUE_SERIAL);
    return _queue;
}

- (NSMutableArray *)loadingRequests {
    if (_loadingRequests == nil) {
        _loadingRequests = [NSMutableArray array];
    }
    return _loadingRequests;
}

@end
