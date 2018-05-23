//
//  SEEDownloader.m
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/4/14.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

    #import "SEEDownloader.h"
    #import "SEEPlayerMacro.h"
    @interface SEEDownloader () <NSURLSessionDataDelegate>

    @end

    @implementation SEEDownloader {
        NSURLSession * _session;
        NSURL * _url;
        
        __weak id <SEEDownloaderDelegate> _delegate;
        
        struct {
            char didReceiveResponse;
            char didCompleteWithError;
            char didReceiveData;
        }_responder;
        
        NSString * _headerRange;
    }

    - (instancetype)initWithURL:(NSURL *)url delegate:(nonnull id<SEEDownloaderDelegate>)delegate {
        if (self = [super init]) {
            _startOffset = -1;
            _endOffset = -1;
            _currentOffset = -1;
            _url = url;
            [self setDelegate:delegate];
        }
        return self;
    }


    #pragma mark public method

    /**
     从指定offset开始下载

     @param startOffset offset
     */
    - (void)resetWithStartOffset:(long long)startOffset  endOffset:(long long)endOffset {
        /* 需要开启下载的情况
         1. 请求起始位置不再当前下载范围之内
         2. 请求起始位置在当前下载的范围内并且比当前下载到的位置大300K 以上
         */
        if (startOffset >= _startOffset && startOffset <= _endOffset){
            if (startOffset <= _currentOffset + 307200) {
                return;
            }
        }
        self.startOffset = startOffset;
        self.currentOffset = startOffset;
        self.endOffset = endOffset;
        [self see_downloadStart];
    }

    - (void)invalidateAndCancel {
        if (_session) {
            [_session invalidateAndCancel];
            _session = nil;
        }
    }

    #pragma mark private method

    - (void)see_downloadStart {
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:_url];
        
        if (self.endOffset == 0) _headerRange = [NSString stringWithFormat:@"bytes=%lld-",self.startOffset];
        else _headerRange = [NSString stringWithFormat:@"bytes=%lld-%lld",self.startOffset,self.endOffset];
        
        [request setValue:_headerRange forHTTPHeaderField:@"Range"];
        
        [self invalidateAndCancel];
        NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue currentQueue]];
        
        NSURLSessionDataTask * task = [_session dataTaskWithRequest:request];
        [task resume];
    }

    #pragma mark delegate
    - (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveResponse:(NSURLResponse *)response
     completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
        NSLog(@"接收到新的请求");
        if (self.endOffset == 0) {
            self.endOffset = response.expectedContentLength - 1;
        }
        if (_responder.didReceiveResponse) {
            [_delegate didReceiveResponse:response];
        }
        completionHandler(NSURLSessionResponseAllow);
    }

    - (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
        didReceiveData:(NSData *)data {
//        NSString * rangeString = dataTask.originalRequest.allHTTPHeaderFields[@"Range"];
//        if (![rangeString isEqualToString:_headerRange]) {
//            NSLog(@"抛弃数据");
//        }
        _currentOffset += data.length;
        if (_responder.didReceiveData) {
            [_delegate didreceiveData:data];
        }
        
    }

    - (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
        if (_responder.didCompleteWithError) {
            [_delegate didCompleteWithError:error];
        }
        //每次下载完成重新调整结束位置，防止由于网络问题导致下载结束后重新请求同段数据时通不过- (void)resetWithStartOffset:(long long)startOffset  endOffset:(long long)endOffset 方法检测。
        if ([task.originalRequest.allHTTPHeaderFields[@"Range"] isEqualToString:_headerRange]) {
            _endOffset = _currentOffset - 1;
        }
    }


    #pragma mark getter & setter
    - (void)setDelegate:(id <SEEDownloaderDelegate>)delegate {
        _delegate = delegate;
        //_responder
        _responder.didReceiveResponse = [delegate respondsToSelector:@selector(didReceiveResponse:)];
        _responder.didCompleteWithError = [delegate respondsToSelector:@selector(didCompleteWithError:)];
        _responder.didReceiveData = [delegate respondsToSelector:@selector(didreceiveData:)];
    }

    @end
