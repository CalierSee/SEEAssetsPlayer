//
//  SEEPlayerFullScreenSupportViewController.m
//  SEEAssetPlayer
//
//  Created by 三只鸟 on 2018/5/25.
//  Copyright © 2018年 景彦铭. All rights reserved.
//

#import "SEEPlayerFullScreenSupportViewController.h"
#import "SEEPlayerView.h"
#import "UIDevice+InterfaceOrientation.h"
@interface SEEPlayerFullScreenSupportViewController () <UIViewControllerTransitioningDelegate,UIViewControllerAnimatedTransitioning>

@property (nonatomic, strong) SEEPlayerView * player;

@property (nonatomic, assign) CGRect animationStartFrame;

@property (nonatomic, assign) CGRect originalViewFrame;

@property (nonatomic, weak) UIView * originalView;






@end

@implementation SEEPlayerFullScreenSupportViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.transitioningDelegate = self;
        self.modalPresentationStyle = UIModalPresentationCustom;
    }
    return self;
}

- (instancetype)initWithPlayer:(SEEPlayerView *)player {
    if (self = [super init]) {
        self.player = player;
        self.originalView = player.superview;
        self.originalViewFrame = player.frame;
        [player removeFromSuperview];
        self.animationStartFrame = [self.originalView convertRect:self.originalViewFrame toView:[UIApplication sharedApplication].keyWindow];
        [self.view addSubview:player];
        [player addObserver:self forKeyPath:@"fullScreen" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.player.frame = self.view.bounds;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [self.player removeObserver:self forKeyPath:@"fullScreen"];
}

#pragma mark action method
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"fullScreen"]) {
        if (!self.player.isFullScreen) {
            [UIDevice switchNewOrientation:UIInterfaceOrientationPortrait];
            [self dismissViewControllerAnimated:YES completion:^{
                [self.player removeFromSuperview];
                [self.originalView addSubview:self.player];
            }];
        }
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark delegate
- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return self;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.25;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIView * container = [transitionContext containerView];
    UIView * fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView * toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    if (fromView) {
        //dismiss
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            fromView.frame = self.animationStartFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
    else {
        //present
        toView.frame = self.animationStartFrame;
        [container addSubview:toView];
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            toView.frame = [UIApplication sharedApplication].keyWindow.bounds;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}



@end
