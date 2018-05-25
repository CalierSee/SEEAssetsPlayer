//
//  SEEPlayerView.m
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/5/8.
//  Copyright © 2018年 景彦铭. All rights reserved.
//


#import "SEEPlayerView.h"
#import "SEEPlayer.h"
extern NSString * const cacheRangesChangeNotification;

@interface SEEPlayerCacheView: UIView

@property (nonatomic, weak) NSArray <NSValue *> * cacheRanges;

@property (nonatomic, assign) long long  totalBytes;



@end

@implementation SEEPlayerCacheView

- (void)awakeFromNib {
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(see_configureCacheRanges:) name:cacheRangesChangeNotification object:nil];
}

- (void)see_configureCacheRanges:(NSNotification *)noti {
    _totalBytes = ((NSNumber *)noti.userInfo[@"total"]).longLongValue;
    _cacheRanges = noti.userInfo[@"ranges"];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (_cacheRanges.count == 0) return;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat width = rect.size.width;
    CGFloat y = rect.size.height / 2;
    CGFloat total = _totalBytes * 1.0;
    
    [_cacheRanges enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSRange range = obj.rangeValue;
        CGFloat start = range.location * 1.0 / total;
        CGFloat end = range.length * 1.0 / total;
        CGContextMoveToPoint(context, start * width, y);
        CGContextAddLineToPoint(context, end * width, y);
    }];
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, rect.size.height);
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:1 alpha:0.5].CGColor);
    CGContextStrokePath(context);
}


@end


@interface SEEPlayerView ()

@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;

@property (weak, nonatomic) IBOutlet UILabel *durationLabel;

@property (weak, nonatomic) IBOutlet UISlider *currentTimeProgressView;

@property (weak, nonatomic) IBOutlet UIButton *playOrPauseButton;

@property (weak, nonatomic) IBOutlet UILabel *panGestureCurrentTimeLabel;

@property (nonatomic, assign) CGPoint  panGestureStartPoint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *showAreaHeightConstaint;

@property (nonatomic, assign) NSTimeInterval hiddenToolsTime;


@end

@implementation SEEPlayerView {
    SEEPlayer * _player;
    BOOL _stopProgressViewUpdate;
    NSTimeInterval _expectTime;
}

+ (instancetype)playerView {
    return [[NSBundle mainBundle]loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil].firstObject;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    _hiddenToolsTime = 10;
    _player = [[SEEPlayer alloc]init];
    [self.layer insertSublayer:_player.playerLayer atIndex:0];
    [_player addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionNew context:nil];
    [_player addObserver:self forKeyPath:@"currentTime" options:NSKeyValueObservingOptionNew context:nil];
    [_player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)dealloc {
    [_player removeObserver:self forKeyPath:@"duration"];
    [_player removeObserver:self forKeyPath:@"currentTime"];
    [_player removeObserver:self forKeyPath:@"status"];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    [super layoutSublayersOfLayer:layer];
    _player.playerLayer.bounds = layer.bounds;
    _player.playerLayer.position = layer.position;
}

- (void)setURL:(NSURL *)url {
    [_player setURL:url];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"currentTime"]) {
        if (_stopProgressViewUpdate) return;
        if (_hiddenToolsTime > 0 && --_hiddenToolsTime == 0) {
            [self see_showOrHiddenTools];
        }
        _expectTime = _player.currentTime;
        self.currentTimeProgressView.value = _expectTime / _player.duration;
        [self see_changeCurrentTime];
    }
    else if ([keyPath isEqualToString:@"status"]) {
        switch (_player.status) {
            case SEEPlayerStatusPlay:
                self.playOrPauseButton.selected = YES;
                break;
                
            default:
                self.playOrPauseButton.selected = NO;
                break;
        }
    }
    else if ([keyPath isEqualToString:@"duration"]) {
        self.durationLabel.text = [self see_timeString:_player.duration];
    }
}

#pragma mark action method

- (IBAction)see_fullScreenAction:(UIButton *)sender {

    
}

- (IBAction)see_beginSeek:(UISlider *)sender {
    _stopProgressViewUpdate = YES;
}

- (IBAction)see_seekToTimeAction:(UISlider *)sender {
    [_player seekToTime:sender.value * _player.duration];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self->_stopProgressViewUpdate = NO;
    });
}

- (IBAction)see_progressChanged:(UISlider *)sender {
    _expectTime = sender.value * _player.duration;
    [self see_changeCurrentTime];
}

- (IBAction)see_panGestureAction:(UIPanGestureRecognizer *)sender {
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:

            _panGestureCurrentTimeLabel.hidden = NO;
            [self see_showTools];
            [self see_beginSeek:self.currentTimeProgressView];
            _panGestureStartPoint = [sender locationInView:sender.view];

            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint endPoint = [sender locationInView:sender.view];

            CGFloat distance = endPoint.x - _panGestureStartPoint.x;

            CGFloat width = self.bounds.size.width;
            //一个屏幕宽度为三分钟 60s * 3m = 180s

            NSTimeInterval distanceTime = (distance / width) * 180;

            _expectTime += distanceTime;

            if (_expectTime < 0) _expectTime = 0;

            if (_expectTime > _player.duration) _expectTime = _player.duration;

            self.currentTimeProgressView.value = _expectTime / _player.duration;

            [self see_progressChanged:self.currentTimeProgressView];

            _panGestureStartPoint = endPoint;
        }
            break;
            case UIGestureRecognizerStateEnded:
            [self see_seekToTimeAction:self.currentTimeProgressView];
            _panGestureCurrentTimeLabel.hidden = YES;
            break;
        default:
            _stopProgressViewUpdate = NO;
            _panGestureCurrentTimeLabel.hidden = YES;
            break;
    }
}

- (IBAction)see_showOrHiddenTools {
    if (self.showAreaHeightConstaint.constant == 0) {
        [self see_showTools];
    }
    else {
        [self see_hiddenTools];
    }
}

- (IBAction)see_playOrPauseAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [_player play];
    }
    else {
        [_player pause];
    }
}

- (IBAction)see_closeAction:(UIButton *)sender {

}

#pragma mark private method
- (void)see_showTools {
    self.showAreaHeightConstaint.constant = -88;
    self.hiddenToolsTime = 10;
}

- (void)see_hiddenTools {
    self.showAreaHeightConstaint.constant = 0;
    self.hiddenToolsTime = 0;
}

- (void)see_changeCurrentTime {
    NSString * timeString = [self see_timeString:_expectTime];
    self.currentTimeLabel.text = timeString;
    self.panGestureCurrentTimeLabel.text = timeString;
}
//
- (NSString *)see_timeString:(NSInteger)time {
    return [NSString stringWithFormat:@"%02zd:%02zd",time / 60,time % 60];
}
//
//#pragma mark getter & setter
//- (void)setDelegate:(id<SEEPlayerToolsViewDelegate>)delegate {
//    _delegate = delegate;
//    _responder.playOrPause = [delegate respondsToSelector:@selector(playOrPause:)];
//    _responder.seekToTime = [delegate respondsToSelector:@selector(seekToTime:)];
//    _responder.close = [delegate respondsToSelector:@selector(close)];
//    _responder.fullScreenOrSmallScreen = [delegate respondsToSelector:@selector(fullScreenOrSmallScreen:)];
//}

@end
