//
//  SEEDataManager.m
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/5/9.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import "SEEDataManager.h"
#import "SEEFileInfo.h"
#import "SEEDownloader.h"

NSString * const cacheRangesChangeNotification = @"cacheRangesChangeNotification";

    @interface SEEData()

    @property (nonatomic, assign) long long location;

    @property (nonatomic, assign) NSUInteger  length;

    @property (nonatomic, assign) long long end;

    @property (nonatomic, strong) __kindof NSData * data;

    @end

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

    - (void)appendData:(const void *)buffer length:(NSUInteger)length {
        [((NSMutableData *)_data) appendBytes:buffer length:length];
        self.length += length;
    }

    - (void)initOffset:(long long)offset {
        if (offset == _location) return;
        long long initLength = offset - _location;
        _location = offset;
        if (initLength < 0 || initLength > _length) {
            //如果初始化的位置不在当前数据片段内则清除当前全部数据
            [((NSMutableData *)_data) replaceBytesInRange:NSMakeRange(0, _length) withBytes:NULL length:0];
            self.length = 0;
            return;
        }
        //清除指定offset之前的数据
        [((NSMutableData *)_data) replaceBytesInRange:NSMakeRange(0, initLength) withBytes:NULL length:0];
        self.length -= initLength;
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



    - (void)setLength:(NSUInteger)length {
        _length = length;
        _end = _location + _length;
    }

    - (NSString *)description {
        return [NSString stringWithFormat:@"location %lld length %lu end %lld dataLength %lu",_location,_length,_end,_data.length];
    }

    @end

    @implementation SEEInputStream {
        long long _currentOffset;
        NSString * _path;
        NSInputStream * _stream;
    }

    - (void)setFileAtPath:(NSString *)path {
        //关闭之前打开的文件
        [self close];
        _currentOffset = 0;
        _path = path;
        _stream = [[NSInputStream alloc]initWithFileAtPath:path];
        [self open];
    }
    //重新打开当前文件
    - (void)resetStream {
        [self close];
        _stream = [NSInputStream inputStreamWithFileAtPath:_path];
        [self open];
        _currentOffset = 0;
    }

    - (void)open {
        if (!_stream)return;
        [_stream open];
    }

    - (void)close {
        if (!_stream)return;
        [_stream close];
        _stream = nil;
    }
    //从stream中读取数据
    - (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
        NSInteger readBytes = [_stream read:buffer maxLength:len];
        if (readBytes == -1 || readBytes == 0) {
            NSLog(@"%@",_stream.streamError);
        }
        _currentOffset += readBytes;
        return readBytes;
    }
    //读取指定位置数据
    - (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len startOffset:(long long)startOffset {
        if (startOffset < _currentOffset) {
            //如果起始位置小于当前读取到的位置则重新打开stream
            [self resetStream];
            return [self read:buffer maxLength:len startOffset:startOffset];
        }
        else if (startOffset > _currentOffset) {
            //如果读取到的位置小于读取的起始位置则一直读取数据直到startOffset == _currentOffset
            int loopCount = (int)((startOffset - _currentOffset) / len);
            for (int i = 0; i <= loopCount; i++) {
                if (i == loopCount) {
                    NSUInteger bufferLength = (startOffset - _currentOffset) % len;
                    if (bufferLength == 0) break;
                    uint8_t buffer[bufferLength];
                    [self read:buffer maxLength:bufferLength];
                }
                else {
                    uint8_t buffer[len];
                    [self read:buffer maxLength:len];
                }
            }
            return [self read:buffer maxLength:len startOffset:startOffset];
        }
        else {
            //读取数据返回
            return [self read:buffer maxLength:len];
        }
    }

@end

@interface SEEDataManager () <SEEDownloaderDelegate>

@property (nonatomic,strong) NSMutableArray<NSValue *> *cacheRanges;

@end
@implementation SEEDataManager {
    __weak id <SEEDataManagerDelegate> _delegate;
    SEEData * _prepareData;
    NSURL * _url;
    NSTimer * _timer;
    NSThread * _timerThread;
    SEEFileInfo * _fileInfo;
    SEEFile * _inputFile;
    SEEInputStream * _inputStream;
    SEEDownloader * _downloader;
    SEEFile * _outputFile;
    NSOutputStream * _outputStream;
    NSCondition * _condition;
    NSString * _cacheBasePath;
    struct {
        int didReceiveData;
    }_responder;
}

    - (instancetype)initWithURL:(NSURL *)url delegate:(id<SEEDataManagerDelegate>)delegate {
        if (self = [super init]) {
            _prepareData = [SEEData mutableData];
            _url = url;
            _cacheBasePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
            _fileInfo = [[SEEFileInfo alloc]initWithURL:url];
            _totalBytes = _fileInfo.fileAttribute.totalBytes;
            _MIMEType = _fileInfo.fileAttribute.MIMEType;
            _inputStream = [[SEEInputStream alloc]init];
            _inputFile = [_fileInfo fileForOffset:0];
            if (_inputFile)[_inputStream setFileAtPath:[_cacheBasePath stringByAppendingPathComponent:_inputFile.path]];
            _downloader = [[SEEDownloader alloc]initWithURL:url delegate:self];
//            _condition = [[NSCondition alloc] init];
            _cacheRanges = [NSMutableArray array];
            if (_fileInfo.files.count) {
                [_fileInfo.files enumerateObjectsUsingBlock:^(SEEFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSRange range = NSMakeRange((NSUInteger)obj.startOffset,(NSUInteger)obj.endOffset);
                    [self->_cacheRanges addObject:[NSValue valueWithRange:range]];
                }];
            }
            [self see_postRanges];
            [self setDelegate:delegate];
        }
        return self;
    }

- (void)dealloc {
    if (_downloader) {
        [_downloader invalidateAndCancel];
    }
    [self see_closeCurrentOutputFile];
    
}

    - (void)begin {
        if (self.state == SEEDataManagerStateInit) {
            self.state = SEEDataManagerStateBegin;
            _timerThread = [[NSThread alloc]initWithTarget:self selector:@selector(see_timerWithThread) object:nil];
            [_timerThread start];
        }
        
        
            
    }

- (void)stop {
    if (_timer) {
        [_timer invalidate];
        _timerThread = nil;
        self.state = SEEDataManagerStateInit;
    }
}

#pragma mark private method
- (void)see_postRanges {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]postNotificationName:cacheRangesChangeNotification object:nil userInfo:@{
                                                                                                                      @"total": @(self->_fileInfo.fileAttribute.totalBytes),                                                                         @"ranges": self->_cacheRanges}];
    });
}


    - (void)see_timerWithThread {
        @autoreleasepool {
            [[NSThread currentThread] setName:@"player_timer"];
            _timer = [NSTimer timerWithTimeInterval:0.25 target:self selector:@selector(see_pushData:) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
            [[NSRunLoop currentRunLoop] run];
        }
    }

    - (void)see_pushData:(NSTimer *)sender {
        if (!self->_responder.didReceiveData) return;
        long long finishOffset = 0;
        //将数据推送给接收者得到填充完成位置
        finishOffset = [self->_delegate didReceiveData:self->_prepareData];
        
        //清除填充完成的数据 每次清除1M数据
        [self see_clearFinishData:finishOffset];
        
        //检查推送是否完成
        if (finishOffset && finishOffset == self->_fileInfo.fileAttribute.totalBytes) {
            [self stop];
            return;
        }
        
        //查找数据
        if (finishOffset < self->_prepareData.location || finishOffset >= self->_prepareData.end) {
            //如果请求的数据不连续，将不连续的片段清除
            if (finishOffset != _prepareData.end)[_prepareData initOffset:finishOffset];
            [self see_prepareData:finishOffset];
        }
        
        [self see_postRanges];
    }

    - (void)see_clearFinishData:(long long)finishOffset {
        //每完成1M数据推送清除一次内存缓存
        if (finishOffset >= _prepareData.location + 1048576) {
            [_prepareData initOffset:_prepareData.location + 1048576];
        }
    }


    /**
     1. 当本地没有文件缓存时从网络获取数据并存入缓存，等待下一次推送读取。
     2. 当本地有缓存文件时 直接从缓存获取

     @param startOffset 所需数据起始位置
     */
    - (void)see_prepareData:(long long)startOffset {
        //如果当前访问的文件中包含后续数据则在当前文件中读取
        if (_inputFile && _inputFile.endOffset > startOffset && _inputFile.startOffset <= startOffset) {
            [self see_prepareDataFormCache:startOffset];
            return;
        }
        //如果当前访问的文件中不包含后续数据则重新查找对应文件
        _inputFile = [_fileInfo fileForOffset:startOffset];
        if (_inputFile){
            //打开对应的流
            [_inputStream setFileAtPath:[_cacheBasePath stringByAppendingPathComponent:_inputFile.path]];
            [self see_prepareDataFormCache:startOffset];
            return;
        }
        //如果缓存中不包含所需数据则开启下载任务
        [self see_prepareDataFromNetwork:startOffset];
    }

    - (void)see_prepareDataFormCache:(long long)startOffset {
        uint8_t buffer[262144] = {};
        NSInteger readByte = [_inputStream read:buffer maxLength:262144 startOffset:startOffset - _inputFile.startOffset];
        [_prepareData appendData:buffer length:readByte];
    }

- (void)see_prepareDataFromNetwork:(long long)startOffset {
    long long endOffset = _fileInfo.missingEndOffset;
    [_downloader resetWithStartOffset:startOffset endOffset:endOffset];
}

- (NSString *)see_pathForOffset:(long long)offset {
    NSString * lastCompment = [_url lastPathComponent];
    return [_cacheBasePath stringByAppendingFormat:@"/%lld_%@",offset,lastCompment];
}

- (void)see_closeCurrentOutputFile {
    if (_outputStream) {
        [_outputStream close];
        _outputStream = nil;
    }
    if (_outputFile) {
        _outputFile = nil;
    }
}

    /**
     1. 当目前文件中有在offset处结尾的文件，则将下载的文件拼接在该文件之后
     2. 如果当前文件中没有在offset处结尾的文件，则新建文件存储

     @param offset 数据起始位置
     */
    - (void)see_initOutputFile:(long long)offset {
        _outputFile = [_fileInfo acceptableFileForDownloadOffset:offset];
        if (_outputFile == nil){
            _outputFile = [[SEEFile alloc]init];
            _outputFile.startOffset = offset;
            NSString * path = [self see_pathForOffset:offset];
            _outputFile.path = [path lastPathComponent];
            [_fileInfo.files addObject:_outputFile];
            [_cacheRanges addObject:[NSValue valueWithRange:NSMakeRange((NSUInteger)offset, (NSUInteger)offset)]];
        }
        _outputStream = [NSOutputStream outputStreamToFileAtPath:[_cacheBasePath stringByAppendingPathComponent:_outputFile.path] append:YES];
        [_outputStream open];
    }

#pragma mark SEEdownloaderDelegate
    - (void)didReceiveResponse:(NSURLResponse *)response {
        if (self.MIMEType == nil) {
            self.MIMEType = response.MIMEType;
        }
        if (self.totalBytes == 0) {
            self.totalBytes = response.expectedContentLength;
        }
        
        long long startOffset = _downloader.startOffset;
        _fileInfo.fileAttribute.exceptFileName = response.suggestedFilename;
        //关闭当前输出文件
        [self see_closeCurrentOutputFile];
        //初始化输出流
        [self see_initOutputFile:startOffset];
    }

    - (void)didreceiveData:(NSData *)data {
        if (_outputFile) {
            _outputFile.length += data.length;
            NSInteger index = [_fileInfo.files indexOfObject:_outputFile];
            [_cacheRanges replaceObjectAtIndex:index withObject:[NSValue valueWithRange:NSMakeRange((NSUInteger) _outputFile.startOffset, (NSUInteger)_outputFile.endOffset)]];
        }
        if (_outputStream)[_outputStream write:data.bytes maxLength:data.length];
    }

-(void)didCompleteWithError:(NSError *)error {
    if (error == nil) {
        [self see_closeCurrentOutputFile];
    }
    [_fileInfo save];
}

#pragma mark getter & setter
- (void)setDelegate:(id <SEEDataManagerDelegate>)delegate {
    _delegate = delegate;
    _responder.didReceiveData = [delegate respondsToSelector:@selector(didReceiveData:)];
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
