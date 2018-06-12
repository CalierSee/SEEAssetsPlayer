//
//  SEEVideoModel.h
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/6/12.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SEEVideoModel : NSObject

@property (nonatomic, copy) NSString * url;

@property (nonatomic, copy) NSString * name;

@property (nonatomic, assign, getter=isPlaying) BOOL playing;

+ (NSArray *)modelsWithNames:(NSArray *)names urls:(NSArray *)urls;

@end
