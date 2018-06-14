//
//  SEEFileInfo.m
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/5/8.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import "SEEFileInfo.h"
#import <objc/runtime.h>

NSString * const exceptFileNameNotification = @"exceptFileNameNotification";

@implementation NSObject(dictionary)

- (NSDictionary *)dictionary {
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    Class c = [self class];
    while (c && c != [NSObject class]) {
        unsigned int outCount = 0;
        objc_property_t * propertys = class_copyPropertyList(c, &outCount);
        for (int i = 0; i < outCount; i++) {
            NSString * propertyName = [NSString stringWithUTF8String:property_getName(propertys[i])];
            NSString * attribute = [NSString stringWithUTF8String:property_getAttributes(propertys[i])];
            id value = [self valueForKey:propertyName];
            if ([attribute hasPrefix:@"T@"]) {
                if ([attribute containsString:@"Array"]) {
                    NSMutableArray * array = [NSMutableArray array];
                    [((NSArray *)[self valueForKey:propertyName]) enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        [array addObject:[obj dictionary]];
                    }];
                    value = array.copy;
                }
                else if (![attribute hasPrefix:@"T@\"NS"]) {
                    value = [value dictionary];
                }
            }
            if (value) {
                [dict setObject:value forKey:propertyName];                
            }
        }
        c = c.superclass;
    }
    return dict.copy;
}

@end

@implementation SEEFileAttribute

- (void)setCacheBytes:(long long)cacheBytes {
    _cacheBytes = cacheBytes;
    _isComplete = cacheBytes == _totalBytes;
}

- (void)setExceptFileName:(NSString *)exceptFileName {
    if ([_exceptFileName isEqualToString:exceptFileName]) return;
    _exceptFileName = exceptFileName;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]postNotificationName:exceptFileNameNotification object:nil userInfo:@{@"exceptFileName": exceptFileName}];
    });
}

@end

@implementation SEEFile

- (void)setLength:(NSUInteger)length {
    _length = length;
    _endOffset = length + _startOffset;
}

- (NSString *)description {
    return [NSString stringWithFormat:@" start: %lld  \n end:%lld  \n length:%lu", self.startOffset, self.endOffset, self.length];
}

@end

@interface SEEFileInfo ()

@property (nonatomic, strong) SEEFileAttribute * fileAttribute;

@property (nonatomic, strong) NSMutableArray <SEEFile *> * files;

@end

@implementation SEEFileInfo {
    NSString * _path;
}

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        self.fileAttribute = [[SEEFileAttribute alloc]init];
        self.files = [NSMutableArray array];
        NSDictionary * dictionary = [NSDictionary dictionaryWithContentsOfFile:[self see_fileInfoPath:url]];
        if (dictionary) {
            [self setValuesForKeysWithDictionary:dictionary];
        }
        [_fileAttribute addObserver:self forKeyPath:@"isComplete" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc {
    [self save];
    [_fileAttribute removeObserver:self forKeyPath:@"isComplete"];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"fileAttribute"]) {
        [self.fileAttribute setValuesForKeysWithDictionary:value];
    }
    if ([key isEqualToString:@"files"]) {
        [((NSArray *)value) enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            SEEFile * file = [[SEEFile alloc]init];
            [file setValuesForKeysWithDictionary:obj];
            [self.files addObject:file];
        }];
        [self.files sortUsingComparator:^NSComparisonResult(SEEFile *  _Nonnull obj1, SEEFile *  _Nonnull obj2) {
            if (obj1.startOffset < obj2.startOffset) {
                return NSOrderedAscending;
            }
            else if (obj1.startOffset > obj2.startOffset) {
                return NSOrderedDescending;
            }
            else {
                return NSOrderedSame;
            }
        }];
    }
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"isComplete"]) {
        if (_fileAttribute.isComplete) {
            [self save];
        }
    }
}

#pragma mark public method
- (void)save {
    __block long long cacheSize = 0;
    [self.files enumerateObjectsUsingBlock:^(SEEFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        cacheSize += obj.length;
    }];
    _fileAttribute.cacheBytes = cacheSize;
    NSDictionary * dict = [self dictionary];
    [dict writeToFile:_path atomically:YES];
}

- (SEEFile *)fileForOffset:(long long)offset {
    __block SEEFile * file = nil;
    self.missingEndOffset = self.fileAttribute.totalBytes;
    [self.files enumerateObjectsUsingBlock:^(SEEFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.startOffset <= offset && obj.endOffset > offset) {
            file = obj;
            *stop = YES;
        }
        if (obj.startOffset > offset && obj.startOffset < self.missingEndOffset) {
            self.missingEndOffset = obj.startOffset - 1;
        }
    }];
    return file;
}

- (SEEFile *)acceptableFileForDownloadOffset:(long long)offset {
    __block SEEFile * file = nil;
    [self.files enumerateObjectsUsingBlock:^(SEEFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.endOffset == offset) {
            file = obj;
            *stop = YES;
        }
    }];
    return file;
}

#pragma mark private method

- (NSString *)see_fileInfoPath:(NSURL *)url {
    if (!_path) {
        NSString * path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:url.path.lastPathComponent] ;
        path = [path stringByReplacingOccurrencesOfString:@"." withString:@"_"];
        path = [path stringByAppendingString:@".plist"];
        _path = path;
    }
    return _path;
}

@end
