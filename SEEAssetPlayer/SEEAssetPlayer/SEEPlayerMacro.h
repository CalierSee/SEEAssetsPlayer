//
//  SEEPlayerMacro.h
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/4/16.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#ifndef SEEPlayerMacro_h
#define SEEPlayerMacro_h

#ifdef DEBUG

#define Thread NSLog(@"currentThread %@",[NSThread currentThread])
#define SEELog(format, ...) if ([format hasPrefix:@"  "]) NSLog(format,##__VA_ARGS__)

#else

#define Thread
#define SEELog(format, ...)

#endif

#endif /* SEEPlayerMacro_h */
