//
//  SEEFileManager.m
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/4/16.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import "SEEFileManager.h"
#import <MobileCoreServices/MobileCoreServices.h>
@implementation SEEData

+ (instancetype)dataWithLocation:(long long)location lenght:(NSUInteger)length data:(__kindof NSData *)data {
    SEEData * instance = [[SEEData alloc]init];
    instance.location = location;
    instance.length = length;
    instance.data = data;
    return instance;
}

+ (instancetype)data {
    return [self dataWithLocation:0 lenght:0 data:[NSData data]];
}

+ (instancetype)mutableData {
    return [self dataWithLocation:0 lenght:0 data:[NSMutableData data]];
}

- (id)copy {
    if ([self.data isMemberOfClass:[NSData class]]) {
        return [SEEData dataWithLocation:self.location lenght:self.length data:self.data];
    }
    else {
        return [SEEData dataWithLocation:self.location lenght:self.length data:[NSData dataWithData:self.data]];
    }
}

- (id)mutableCopy {
    if ([self.data isMemberOfClass:[NSData class]]) {
        return [SEEData dataWithLocation:self.location lenght:self.length data:[NSMutableData dataWithData:self.data]];
    }
    else {
        return [SEEData dataWithLocation:self.location lenght:self.length data:self.data];
    }
}

- (BOOL)isEqual:(id)object {
    if ([object isMemberOfClass:[self class]]) {
        SEEData * target = object;
        return self.location == target.location && self.length == target.length && [self.data isEqualToData:target.data];
    }
    else {
        return NO;
    }
}

@end


@interface SEEFileManager ()

@property (nonatomic, weak) id <SEEFileManagerPushDataObjcet> pushDataDelegate;

@property (nonatomic, weak) id <SEEFileManagerBufferDelegate> bufferDelegate;


@end

@implementation SEEFileManager {
    struct {
        int didReceiveData;
        int bufferEmpty;
        int bufferRegular;
        int outOfBuffer;
    }_responder;
    
    /*******数据推送相关*******/
    //定时器
    NSTimer * _pushTimer;
    //待推送数据
    SEEData * _waitingPushData;
    //推送url
    NSURL * _url;
    //推送线程
    NSThread * _pushThread;
    
    /******当存在缓存时推送数据相关******/
    //文件输入流
    NSInputStream * _inputStream;
    
    /*******数据写入相关*******/
    //文件输出流
    NSOutputStream * _outputStream;
    //接收到的数据流是否有间断 （该值为NO时仅仅表示该对象接收到的数据是连续无间断的，并不能说明文件的完整性）
    BOOL _isDataDiscontinuous;
    //数据接收是否完成
    BOOL _isReceiveAll;
    
    //文件管理器
    NSFileManager * _fileManager;
    
    //缓存文件信息
    /*
    {
     "fileAttribute": {
        "MIMEType": "video/mp4",
        "totalSize": 12312,
        "cacheSize": 23,
        "isComplete": NO,
     },
     "file": [
        {
            "path": "file:///cache/fileName",
            "start": 123,
            "end": 23423,
            "length": 234,
        },
     ],
     }
     */
    SEEFileInfo * _fileInfo;
}

- (instancetype)initWithURL:(NSURL *)url bufferdelegate:(nonnull id<SEEFileManagerBufferDelegate>)bufferDelegate pushDataDelegate:(nonnull id<SEEFileManagerPushDataObjcet>)pushDataDelegate{
    if (self = [super init]) {
        self.bufferDelegate = bufferDelegate;
        self.pushDataDelegate = pushDataDelegate;
        _fileManager = [NSFileManager defaultManager];
        _url = url;
        _waitingPushData = [SEEData mutableData];
        _fileInfo = [[SEEFileInfo alloc]initWithURL:_url];
        _MIMEType = _fileInfo.fileAttribute.MIMEType;
        _totalBytes = _fileInfo.fileAttribute.totalBytes;
        [self start];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"dealloc");
}

- (void)writeData:(const SEEData *)data {
    const void * writeData = data.data.bytes;
    NSUInteger writeLength = data.length;
    long long writeStartOffset = data.location;
    if (_isDataDiscontinuous == NO) {
        NSInteger writeByte = [_outputStream write:writeData maxLength:writeLength];
        //磁盘写入错误停止后续磁盘写入
        _isDataDiscontinuous = writeByte <= 0;
    }
    //将下载好的数据拼接到等待推送的数据中
    NSMutableData * waitingData = _waitingPushData.data;
    if (writeStartOffset != _waitingPushData.location + _waitingPushData.length) {
        //当下载的数据与当前等待推送的数据中间缺少数据片段 说明downloadManager的resetOffset方法被调用，此时重置等待推送的数据。
        [waitingData replaceBytesInRange:NSMakeRange(0, waitingData.length) withBytes:writeData length:writeLength];
        _waitingPushData.location = writeStartOffset;
        _waitingPushData.length = writeLength;
        //此时数据片段一定不完整 取消磁盘写入
        _isDataDiscontinuous = YES;
    }
    else {
        [waitingData appendBytes:writeData length:writeLength];
        _waitingPushData.length += writeLength;
    }
    //当等待推送的数据大小超过1M时 暂停下载
    BOOL suspendTask = _waitingPushData.length >= 1048576;
    if (suspendTask && _responder.outOfBuffer) {
        [_bufferDelegate fileManagerOutOfBuffer];
    }
    else {
        //开始数据推送
        [self start];
    }
}

//- (void)cache {
//    _isReceiveAll = YES;
//    if (_outputStream) {
//        [_outputStream close];
//        _outputStream = nil;
//    }
//    if (!_isDataDiscontinuous) {
//        NSString * cachePath = [self see_cachePath];
//        NSString * tempPath = [self see_tempPath];
//        [_fileManager moveItemAtURL:[NSURL URLWithString:tempPath] toURL:[NSURL URLWithString:cachePath] error:nil];
//    }
//    [_fileManager removeItemAtPath:[self see_tempPath] error:nil];
//}
//
//- (void)cancel {
//    if (_outputStream) {
//        [_outputStream close];
//        _outputStream = nil;
//    }
//    NSString * tempPath = [self see_tempPath];
//    if ([_fileManager fileExistsAtPath:tempPath])
//    [_fileManager removeItemAtPath:[self see_tempPath] error:nil];
//}


- (void)suspend {
    if (_pushTimer == nil)return;
    [_pushTimer invalidate];
    _pushTimer = nil;
    _pushThread = nil;
}

- (void)start {
    if (_pushTimer) return;
    _pushTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(see_pushData) userInfo:nil repeats:YES];
    _pushThread = [[NSThread alloc]initWithTarget:self selector:@selector(see_pushThread) object:nil];
    [_pushThread start];
}

#pragma mark action method
- (void)see_pushData {
    long long finishOffset = _waitingPushData.location;
    if (_responder.didReceiveData) {
        finishOffset = [_pushDataDelegate didReceiveData:_waitingPushData];
    }
    //单次推送数据量超过100K时清除待推送缓存中的数据
    if (finishOffset - _waitingPushData.location >= 102400) {
        NSUInteger invalideLength = (NSUInteger)finishOffset - (NSUInteger)_waitingPushData.location;
        _waitingPushData.length -= invalideLength;
        _waitingPushData.location = finishOffset;
        [(NSMutableData *)_waitingPushData.data replaceBytesInRange:NSMakeRange(0, invalideLength) withBytes:NULL length:0];
    }
    if (_waitingPushData.location + _waitingPushData.length == finishOffset) {
        if (_inputStream) {
            //读取 256K 数据
            uint8_t buffer[262144] = {};
            NSInteger readBytes = [_inputStream read:buffer maxLength:262144];
            if (readBytes <= 0){
                [self suspend];
                SEELog(@"缓存推送完成 readBytes %d", readBytes);
                [_inputStream close];
                
            }
            else {
                _waitingPushData.location = finishOffset;
                _waitingPushData.length = readBytes;
                NSMutableData * data = _waitingPushData.data;
                [data replaceBytesInRange:NSMakeRange(0, data.length) withBytes:buffer length:readBytes];
            }
        }
        else {
            if (_isReceiveAll) {
                SEELog(@"下载推送完成");
                [self suspend];
            }
            else {
                if (_responder.bufferEmpty) {
                    [_bufferDelegate fileManagerBufferEmpty];
                }
            }
        }
    }
    //当缓存由溢出状态减少到512K时缓存状态更改为正常
    if (_waitingPushData.data.length < 524288 && _responder.bufferRegular) {
        [_bufferDelegate fileManagerBufferRegular];
    }
}

#pragma mark private method
- (void)see_pushThread {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"player_timer"];
        [[NSRunLoop currentRunLoop] addTimer:_pushTimer forMode:NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop] run];
    }
}

- (NSString *)see_cachePath:(NSInteger)index {
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:_url.path.lastPathComponent] stringByAppendingString:@(index).description];
}



#pragma mark getter & setter
- (void)setPushDataDelegate:(__strong id<SEEFileManagerPushDataObjcet>)delegate {
    _pushDataDelegate = delegate;
    _responder.didReceiveData = [delegate respondsToSelector:@selector(didReceiveData:)];
}

- (void)setBufferDelegate:(id<SEEFileManagerBufferDelegate>)delegate {
    _bufferDelegate = delegate;
    _responder.bufferEmpty = [delegate respondsToSelector:@selector(fileManagerBufferEmpty)];
    _responder.outOfBuffer = [delegate respondsToSelector:@selector(fileManagerOutOfBuffer)];
    _responder.bufferRegular = [delegate respondsToSelector:@selector(fileManagerBufferRegular)];
}

- (void)setMIMEType:(NSString *)MIMEType {
    _MIMEType = MIMEType;
    _fileInfo.fileAttribute.MIMEType = MIMEType;
}

- (void)setTotalBytes:(long long)totalBytes {
    _totalBytes = totalBytes;
    _fileInfo.fileAttribute.totalBytes = totalBytes;
}



@end
