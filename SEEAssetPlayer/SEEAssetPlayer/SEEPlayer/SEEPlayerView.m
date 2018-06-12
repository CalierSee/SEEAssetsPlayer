//
//  SEEPlayerView.m
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/5/8.
//  Copyright © 2018年 景彦铭. All rights reserved.
//


#import "SEEPlayerView.h"
#import "SEEPlayer.h"
#import "UIViewController+Top.h"
#import "SEEPlayerFullScreenSupportViewController.h"
#define kAutoHiddenToolsTime 6

#define kPanGestureScreenWidthTime 180

extern NSString * const cacheRangesChangeNotification;

extern NSString * const exceptFileNameNotification;

@interface SEEPlayerCacheView: UIView

@property (nonatomic, weak) NSArray <NSValue *> * cacheRanges;

@property (nonatomic, assign) long long  totalBytes;

@end

@implementation SEEPlayerCacheView

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

- (void)setCacheRanges:(NSArray<NSValue *> *)cacheRanges {
    _cacheRanges = cacheRanges;
    [self setNeedsDisplay];
}


@end


@interface SEEPlayerView ()

@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;

@property (weak, nonatomic) IBOutlet UILabel *durationLabel;

@property (weak, nonatomic) IBOutlet UISlider *currentTimeProgressView;

@property (weak, nonatomic) IBOutlet UIButton *playOrPauseButton;

@property (weak, nonatomic) IBOutlet UILabel *panGestureCurrentTimeLabel;

@property (nonatomic, assign) CGPoint  panGestureStartPoint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topToolsTopConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomToolsBottomConstraint;

@property (nonatomic, assign) NSTimeInterval hiddenToolsTime;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@property (weak, nonatomic) IBOutlet UIPanGestureRecognizer *panGesture;

@property (weak, nonatomic) IBOutlet SEEPlayerCacheView *cacheRangesView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *closeButtonWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *returnButtonWidthConstraint;

@property (nonatomic, assign) BOOL fullScreen;


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
    [self.currentTimeProgressView setThumbImage:[UIImage imageNamed:@"point"] forState:UIControlStateNormal];
    self.returnType = SEEPlayerViewReturnButtonTypeNone;
    _hiddenToolsTime = kAutoHiddenToolsTime;
    _player = [[SEEPlayer alloc]init];
    [self.layer insertSublayer:_player.playerLayer atIndex:0];
    [_player addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionNew context:nil];
    [_player addObserver:self forKeyPath:@"currentTime" options:NSKeyValueObservingOptionNew context:nil];
    [_player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [_player addObserver:self forKeyPath:@"buffing" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(see_exceptFileNameNotification:) name:exceptFileNameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(see_configureCacheRanges:) name:cacheRangesChangeNotification object:nil];
}

- (void)dealloc {
    [_player removeObserver:self forKeyPath:@"duration"];
    [_player removeObserver:self forKeyPath:@"currentTime"];
    [_player removeObserver:self forKeyPath:@"status"];
    [_player removeObserver:self forKeyPath:@"buffing"];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    [super layoutSublayersOfLayer:layer];
    _player.playerLayer.bounds = layer.bounds;
    _player.playerLayer.position = CGPointMake(layer.bounds.size.width / 2, layer.bounds.size.height / 2);
}

- (void)setURL:(NSURL *)url {
    _stopProgressViewUpdate = YES;
    [_player pause];
    [self.loadingIndicator startAnimating];
    [self see_initTools];
    [self see_showTools];
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        [self->_player setURL:url];
        self->_stopProgressViewUpdate = NO;
    });
}

- (void)setURL:(NSURL *)url title:(NSString *)title {
    [self setURL:url];
    self.titleLabel.text = title;
}

- (void)pause {
    [_player pause];
}

- (void)play {
    [_player play];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"currentTime"]) {
        if (_stopProgressViewUpdate || _expectTime == _player.currentTime) return;
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
            case SEEPlayerStatusComplete:
                [self see_showTools];
            default:
                self.playOrPauseButton.selected = NO;
                break;
        }
    }
    else if ([keyPath isEqualToString:@"buffing"]) {
        if (_player.isBuffing) {
            [self.loadingIndicator startAnimating];
        }
        else {
            [self.loadingIndicator stopAnimating];
        }
    }
    else if ([keyPath isEqualToString:@"duration"]) {
        if (_player.duration < kPanGestureScreenWidthTime / 2) {
            self.panGesture.enabled = NO;
        }
        self.durationLabel.text = [self see_timeString:_player.duration];
    }
}

#pragma mark action method

- (IBAction)see_changeScreenAction:(UIButton *)sender {
    [self see_showTools];
    sender.selected = !sender.selected;
    self.fullScreen = sender.selected;
    if (sender.selected) {
        UIViewController * topViewController = [UIViewController topViewController];
        SEEPlayerFullScreenSupportViewController * vc = [[SEEPlayerFullScreenSupportViewController alloc]initWithPlayer:self];
        [topViewController presentViewController:vc animated:YES completion:nil];
    }
}

- (IBAction)see_beginSeek:(UISlider *)sender {
    [self see_showTools];
    _stopProgressViewUpdate = YES;
}

- (IBAction)see_seekToTimeAction:(UISlider *)sender {
    [_player seekToTime:sender.value * _player.duration];
    dispatch_async(dispatch_get_main_queue(), ^{
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
            [self see_beginSeek:self.currentTimeProgressView];
            _panGestureStartPoint = [sender locationInView:sender.view];

            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint endPoint = [sender locationInView:sender.view];

            CGFloat distance = endPoint.x - _panGestureStartPoint.x;

            CGFloat width = self.bounds.size.width;
            //一个屏幕宽度为kPanGestureScreenWidthTime s 并且 视频时长小于 kPanGestureScreenWidthTime 的二分之一 不提供拖动手势

            NSTimeInterval distanceTime = (distance / width) * kPanGestureScreenWidthTime;

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
    if (self.topToolsTopConstraint.constant == -44) {
        [self see_showTools];
    }
    else {
        [self see_hiddenTools];
    }
}

- (IBAction)see_playOrPauseAction:(UIButton *)sender {
    [self see_showTools];
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

- (void)see_configureCacheRanges:(NSNotification *)noti {
    if (_stopProgressViewUpdate) return;
    self.cacheRangesView.totalBytes = ((NSNumber *)noti.userInfo[@"total"]).longLongValue;
    self.cacheRangesView.cacheRanges = noti.userInfo[@"ranges"];
}

#pragma mark private method
- (void)see_exceptFileNameNotification:(NSNotification *)noti {
    if (self.titleLabel.text.length != 0) return;
    self.titleLabel.text = noti.userInfo[@"exceptFileName"];
}

- (void)see_initTools {
    self.currentTimeProgressView.value = 0;
    [self see_progressChanged:self.currentTimeProgressView];
    self.durationLabel.text = @"00:00";
    self.cacheRangesView.cacheRanges = nil;
    self.titleLabel.text = @"";
}


- (void)see_showTools {
    if (self.topToolsTopConstraint.constant == -44) {
        self.topToolsTopConstraint.constant = 0;
        self.bottomToolsBottomConstraint.constant = 0;
    }
    self.hiddenToolsTime = kAutoHiddenToolsTime;
}

- (void)see_hiddenTools {
    if (self.topToolsTopConstraint.constant == 0) {
        self.topToolsTopConstraint.constant = -44;
        self.bottomToolsBottomConstraint.constant = -44;
    }
    self.hiddenToolsTime = 0;
}

- (void)see_changeCurrentTime {
    NSString * timeString = [self see_timeString:_expectTime];
    self.currentTimeLabel.text = timeString;
    self.panGestureCurrentTimeLabel.text = timeString;
}

- (NSString *)see_timeString:(NSInteger)time {
    return [NSString stringWithFormat:@"%02zd:%02zd",time / 60,time % 60];
}

#pragma mark getter & setter

- (void)setReturnType:(SEEPlayerViewReturnButtonType)returnType {
    _returnType = returnType;
    switch (returnType) {
        case SEEPlayerViewReturnButtonTypeNone:
        case SEEPlayerViewReturnButtonTypeReturn:
            self.closeButtonWidthConstraint.constant = 0;
            if (returnType == SEEPlayerViewReturnButtonTypeReturn) {
                self.returnButtonWidthConstraint.constant = 24;
                break;
            }
        case SEEPlayerViewReturnButtonTypeClose:
            self.returnButtonWidthConstraint.constant = 0;
            if (returnType == SEEPlayerViewReturnButtonTypeClose) {
                self.closeButtonWidthConstraint.constant = 24;
            }
    }
}


@end
