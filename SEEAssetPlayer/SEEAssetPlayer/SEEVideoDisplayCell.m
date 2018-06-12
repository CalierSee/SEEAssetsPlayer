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
    self.playing = model.isPlaying;
}

- (IBAction)playButtonAction:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cell:playerWithIndexPath:)]) {
        self.player = [self.delegate cell:self playerWithIndexPath:self.indexPath];
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.player pause];
    [self.player removeFromSuperview];
    self.player = nil;
    self.playing = NO;
}

- (void)setPlayer:(SEEPlayerView *)player {
    _player = player;
    if (player) {
        [self.playeView addSubview:self.player];
        self.player.frame = self.playeView.bounds;
        [player play];
        _playing = YES;
    }
}

- (void)setPlaying:(BOOL)playing {
    _playing = playing;
    if (playing) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(cell:playerWithIndexPath:)]) {
            self.player = [self.delegate cell:self playerWithIndexPath:self.indexPath];
        }
    }
}

@end
