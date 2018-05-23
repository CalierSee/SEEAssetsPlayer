//
//  SEEFileInfo.h
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/5/8.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject(dictionary)

- (NSDictionary *)dictionary;

@end

    @interface SEEFileAttribute: NSObject
    //MIME类型
    @property (nonatomic, copy) NSString * MIMEType;
    //总数据量
    @property (nonatomic, assign) long long  totalBytes;
    //已经下载的数据总量
    @property (nonatomic, assign) long long cacheBytes;
    //缓存是否完成  isComplete = totalBytes == cacheBytes
    @property (nonatomic, assign) BOOL isComplete;
    //文件名
    @property (nonatomic, copy) NSString * exceptFileName;

    @end

    @interface SEEFile: NSObject
    //缓存文件名
    @property (nonatomic, copy) NSString * path;
    //缓存文件起始位置
    @property (nonatomic, assign) long long  startOffset;
    //缓存文件结束位置
    @property (nonatomic, assign) long long  endOffset;
    //缓存文件长度
    @property (nonatomic, assign) NSUInteger  length;

    @end

    @interface SEEFileInfo: NSObject

    @property (nonatomic, strong, readonly) SEEFileAttribute * fileAttribute;

    @property (nonatomic, strong, readonly) NSMutableArray <SEEFile *> * files;

    - (instancetype)initWithURL:(NSURL *)url;

    - (void)save;

    - (SEEFile *)fileForOffset:(long long)offset;

    //可以接受当前下载请求获得的数据的文件（即当前下载的数据可以拼接在哪个文件的末尾）
    - (SEEFile *)acceptableFileForDownloadOffset:(long long)offset;

    /**
     当每一次执行 fileForOffset:offset 方法时，如果查找文件失败，则当前参数会被设置为缓存中缺少片段的结束偏移量
     Range:bytes=offset-missingEndOffset
     */
    @property (nonatomic, assign) long long missingEndOffset;


    @end
