//
//  SEEResourceLoader.h
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/4/14.
//  Copyright © 2018年 景彦铭. All rights reserved.
/*
 向播放器填充数据
 */

#import <Foundation/Foundation.h>
@class AVURLAsset;

NS_ASSUME_NONNULL_BEGIN

@interface SEEResourceLoaderDelegate : NSObject

- (AVURLAsset *)assetWithURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
