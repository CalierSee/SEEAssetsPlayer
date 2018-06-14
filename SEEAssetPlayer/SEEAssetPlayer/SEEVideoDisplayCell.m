//
//  SEEVideoDisplayCell.m
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/6/6.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import "SEEVideoDisplayCell.h"
#import "SEEVideoModel.h"
#import "SEEPlayerView.h"
@interface SEEVideoDisplayCell ()

@property (weak, nonatomic) IBOutlet UILabel *urlLabel;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (weak, nonatomic) IBOutlet UIView *playeView;

@property (nonatomic, weak) SEEPlayerView * player;

@property (weak, nonatomic) IBOutlet UIButton *playButton;

@end

@implementation SEEVideoDisplayCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    // Initialization code
}

- (void)configureWithModel:(SEEVideoModel *)model {
    self.urlLabel.text = model.url;
    self.nameLabel.text = model.name;
    if (model.isPlaying) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(cell:playerWithIndexPath:)]) {
            self.player = [self.delegate cell:self playerWithIndexPath:self.indexPath];
        }
        self.playButton.hidden = YES;
    }
    else {
        self.playButton.hidden = NO;
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self clearPlayer];
}

- (void)clearPlayer {
    if (self.player) {
        [self.player pause];
        [self.player removeFromSuperview];
        self.player = nil;
        self.playButton.hidden = NO;
    }
}

- (IBAction)playButtonAction:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cell:playerWithIndexPath:)]) {
        sender.hidden = YES;
        self.player = [self.delegate cell:self playerWithIndexPath:self.indexPath];
    }
}


- (void)setPlayer:(SEEPlayerView *)player {
    _player = player;
    if (player) {
        [self.playeView addSubview:self.player];
        self.player.frame = self.playeView.bounds;
        [player play];
    }
}

@end
