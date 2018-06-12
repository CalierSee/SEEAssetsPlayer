//
//  SEEVideoDisplayCell.h
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/6/6.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SEEVideoModel;
@class SEEVideoDisplayCell;
@class SEEPlayerView;
@protocol SEEVideoDisplayCellDelegate <NSObject>

- (SEEPlayerView *)cell:(SEEVideoDisplayCell *)cell playerWithIndexPath:(NSIndexPath *)indexPath;

@end

@interface SEEVideoDisplayCell : UITableViewCell

@property (nonatomic, weak) id <SEEVideoDisplayCellDelegate> delegate;

@property (nonatomic, assign) BOOL playing;

@property (nonatomic, strong) NSIndexPath * indexPath;


- (void)configureWithModel:(SEEVideoModel *)model;

@end
