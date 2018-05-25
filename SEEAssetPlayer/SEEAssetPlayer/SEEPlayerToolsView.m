//
//  SEEPlayerToolsView.m
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/5/8.
//  Copyright © 2018年 景彦铭. All rights reserved.
//


#import "SEEPlayerToolsView.h"

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


@interface SEEPlayerToolsView ()

@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;

@property (weak, nonatomic) IBOutlet UILabel *durationLabel;

@property (weak, nonatomic) IBOutlet UISlider *currentTimeProgressView;

@property (weak, nonatomic) IBOutlet UIButton *playOrPauseButton;

@property (weak, nonatomic) IBOutlet UILabel *panGestureCurrentTimeLabel;

@property (nonatomic, assign) CGPoint  panGestureStartPoint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *showAreaHeightConstaint;

@end

@implementation SEEPlayerToolsView {
    struct {
        int playOrPause;
        int seekToTime;
        int close;
    }_responder;
    
    BOOL _stopProgressViewUpdate;
    
    NSTimeInterval _duration;
    
    NSTimeInterval _currentTime;
}

+ (instancetype)playerToolsView {
    return [[NSBundle mainBundle]loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil].firstObject;
}

- (void)setDuration:(NSTimeInterval)duration {
    _duration = duration;
    self.durationLabel.text = [self see_timeString:duration];
}

- (void)setCurrentTime:(NSTimeInterval)time {
    if (_stopProgressViewUpdate) return;
    _currentTime = time;
    self.currentTimeProgressView.value = _currentTime / _duration;
    [self see_progressChanged:self.currentTimeProgressView];
}



- (void)playOrPause:(BOOL)isPlay {
    self.playOrPauseButton.selected = isPlay;
}

#pragma mark action method

- (IBAction)see_beginSeek:(UISlider *)sender {
    _stopProgressViewUpdate = YES;
}

- (IBAction)see_seekToTimeAction:(UISlider *)sender {
    if (_responder.seekToTime) {
        [_delegate seekToTime:sender.value];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self->_stopProgressViewUpdate = NO;
    });
}

- (IBAction)see_progressChanged:(UISlider *)sender {
    NSString * timeString = [self see_timeString:sender.value * _duration];
    self.currentTimeLabel.text = timeString;
    self.panGestureCurrentTimeLabel.text = timeString;
}


- (IBAction)panGestureAction:(UIPanGestureRecognizer *)sender {
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
            //一个屏幕宽度为三分钟 60s * 3m = 180s
            
            NSTimeInterval distanceTime = (distance / width) * 180;
            
            _currentTime += distanceTime;
            
            if (_currentTime < 0) _currentTime = 0;
            
            if (_currentTime > _duration) _currentTime = _duration;
            
            self.currentTimeProgressView.value = _currentTime / _duration;
            
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



- (IBAction)showOrHiddenTools:(UITapGestureRecognizer *)sender {
    if (self.showAreaHeightConstaint.constant == 0) {
        self.showAreaHeightConstaint.constant = -88;
    }
    else {
        self.showAreaHeightConstaint.constant = 0;
    }
}

- (IBAction)playOrPauseAction:(UIButton *)sender {
    if (_responder.playOrPause) {
        sender.selected = [self.delegate playOrPause:!sender.selected];
    }
}

- (IBAction)see_closeAction:(UIButton *)sender {
    if (_responder.close) {
        [_delegate close];
    }
}

#pragma mark private method


- (NSString *)see_timeString:(NSInteger)time {
    return [NSString stringWithFormat:@"%02zd:%02zd",time / 60,time % 60];
}

#pragma mark getter & setter
- (void)setDelegate:(id<SEEPlayerToolsViewDelegate>)delegate {
    _delegate = delegate;
    _responder.playOrPause = [delegate respondsToSelector:@selector(playOrPause:)];
    _responder.seekToTime = [delegate respondsToSelector:@selector(seekToTime:)];
    _responder.close = [delegate respondsToSelector:@selector(close)];
}

@end
