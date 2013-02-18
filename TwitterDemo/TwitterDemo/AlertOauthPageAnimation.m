//
//  AlertOauthPageAnimation.m
//  WeiboBox_Demo
//
//  Created by willonboy zhang on 12-7-4.
//  Copyright (c) 2012年 willonboy.tk. All rights reserved.
//

#define STATUS_HEIGHT               (20)

    //_containerView.frame属性值
#define IPAD_CON_VIEW_WIDTH         (440)   //ipad竖屏时宽;margin-left   164 横屏时:margin-left   XXX
#define IPAD_CON_VIEW_HEIGHT        (560)   //ipad竖屏时高;margin-top    232 横屏时:margin-left   XXX

#define IPAD_CON_VIEW_MRG_HORIZONTAL    (164)
#define IPAD_CON_VIEW_MRG_VERTICAL      (232)

#define IPHONE_CON_VIEW_WIDTH       (300)   //iphone竖屏时宽
#define IPHONE_CON_VIEW_HEIGHT      (420)   //iphone竖屏时高
#define IPHONE5_CON_VIEW_HEIGHT     (450)   //iphone5竖屏时高

#define IPHONE_CON_VIEW_MRG_HORIZONTAL  (10)
#define IPHONE_CON_VIEW_MRG_VERTICAL    (30)
#define IPHONE5_CON_VIEW_MRG_VERTICAL   (60)


    //_webView.frame属性值
#define IPAD_WEB_VIEW_WIDTH         (420)   //ipad竖屏时宽
#define IPAD_WEB_VIEW_HEIGHT        (530)   //ipad竖屏时高

#define IPHONE_WEB_VIEW_WIDTH       (280)   //iphone竖屏时宽
#define IPHONE_WEB_VIEW_HEIGHT      (390)   //iphone竖屏时高
#define IPHONE5_WEB_VIEW_HEIGHT     (420)   //iphone5竖屏时高

#define WEB_VIEW_MRG_HORIZONTAL     (10)
#define WEB_VIEW_MRG_VERTICAL       (15)


#import "AlertOauthPageAnimation.h"
#import <QuartzCore/QuartzCore.h> 


@interface AlertOauthPageAnimation()

- (void) hideAndCleanUp;

- (void) scalAnimation;


@end


@implementation AlertOauthPageAnimation


- (id)init
{
    self = [super init];
    if (self)
    {
            //important 必须添加一个全屏的_baseView 用来来执行转屏动画, 并将其他view加在它上面(因为keywindow的方向改变时Frame有时不确定)
        _baseView = [[UIView alloc] init];
        [_baseView setBackgroundColor:[UIColor clearColor]];
        [_baseView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        
        _containerView = [[UIView alloc] init];
        [_containerView setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.55]];
        [[_containerView layer] setMasksToBounds:NO]; 
        [[_containerView layer] setCornerRadius:10.0]; 
        
        [_baseView addSubview:_containerView];
    }
    
    return self;
}

- (void)dealloc
{
    _webView = nil;
    
    if (_containerView)
    {
        [_containerView release];
        _containerView = nil;
    }
    
    if (_baseView)
    {
        [_baseView release];
        _baseView = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

- (void)addObservers
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceOrientationDidChange:)
												 name:@"UIDeviceOrientationDidChangeNotification" object:nil];
}

#pragma mark - UIDeviceOrientationDidChangeNotification Methods
    //判断需不需要转屏
- (BOOL) shouldRotateToOrientation:(UIInterfaceOrientation)orientation
{
    if (orientation == previousOrientation)
    {
		return NO;
	}
    
    return YES;
    
}

    //转屏动画
- (CGAffineTransform)transformForOrientation:(UIInterfaceOrientation)orientation
{  
	if (orientation == UIInterfaceOrientationLandscapeLeft)
    {
		return CGAffineTransformMakeRotation(-M_PI / 2);
	}
    else if (orientation == UIInterfaceOrientationLandscapeRight)
    {
		return CGAffineTransformMakeRotation(M_PI / 2);
	}
    else if (orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
		return CGAffineTransformMakeRotation(-M_PI);
	}
    else
    {
		return CGAffineTransformIdentity;
	}
}


- (void)modifyViewFrame:(UIInterfaceOrientation) orientation
{
    CGRect baseViewFrame   = CGRectZero;
    CGRect containerFrame  = CGRectZero;
    CGRect webViewFrame    = CGRectZero;
    BOOL isiPad = [[UIDevice currentDevice].model hasPrefix:@"iPad"] ;
    
        //是否是横屏
    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        if (isiPad) 
        {
            baseViewFrame = CGRectMake(0, 0, 1024, 768);
            containerFrame = CGRectMake((1024 - IPAD_CON_VIEW_HEIGHT) / 2, (768 - IPAD_CON_VIEW_WIDTH) / 2, IPAD_CON_VIEW_HEIGHT, IPAD_CON_VIEW_WIDTH);
            webViewFrame = CGRectMake(WEB_VIEW_MRG_VERTICAL, WEB_VIEW_MRG_HORIZONTAL, IPAD_WEB_VIEW_HEIGHT, IPAD_WEB_VIEW_WIDTH);
        }
        else
        {
            baseViewFrame = CGRectMake(0, 0, 480, 320);
            containerFrame = CGRectMake((480 - IPHONE_CON_VIEW_HEIGHT) / 2, (320 - IPHONE_CON_VIEW_WIDTH) / 2 + STATUS_HEIGHT,
                                        IPHONE_CON_VIEW_HEIGHT, IPHONE_CON_VIEW_WIDTH - STATUS_HEIGHT);
            webViewFrame = CGRectMake(WEB_VIEW_MRG_VERTICAL, WEB_VIEW_MRG_HORIZONTAL, IPHONE_WEB_VIEW_HEIGHT, IPHONE_WEB_VIEW_WIDTH - STATUS_HEIGHT);
        }
        
        [_baseView setFrame:baseViewFrame];
        [_containerView setFrame:containerFrame];
        [_webView setFrame:webViewFrame];
        
    }
    else
    {
        if (isiPad) 
        {
            baseViewFrame = CGRectMake(0, 0, 768, 1024);
            containerFrame = CGRectMake(IPAD_CON_VIEW_MRG_HORIZONTAL, IPAD_CON_VIEW_MRG_VERTICAL, IPAD_CON_VIEW_WIDTH, IPAD_CON_VIEW_HEIGHT);
            webViewFrame = CGRectMake(WEB_VIEW_MRG_HORIZONTAL, WEB_VIEW_MRG_VERTICAL, IPAD_WEB_VIEW_WIDTH, IPAD_WEB_VIEW_HEIGHT);
        }
        else
        {
            if ((int)[UIScreen mainScreen].bounds.size.height % 568 == 0)
            {
                baseViewFrame = CGRectMake(0, 0, 320, 568);
                containerFrame = CGRectMake(IPHONE_CON_VIEW_MRG_HORIZONTAL, IPHONE5_CON_VIEW_MRG_VERTICAL, IPHONE_CON_VIEW_WIDTH, IPHONE5_CON_VIEW_HEIGHT);
                webViewFrame = CGRectMake(WEB_VIEW_MRG_HORIZONTAL, WEB_VIEW_MRG_VERTICAL, IPHONE_WEB_VIEW_WIDTH, IPHONE5_WEB_VIEW_HEIGHT);
            }
            else
            {
                baseViewFrame = CGRectMake(0, 0, 320, 480);
                containerFrame = CGRectMake(IPHONE_CON_VIEW_MRG_HORIZONTAL, IPHONE_CON_VIEW_MRG_VERTICAL, IPHONE_CON_VIEW_WIDTH, IPHONE_CON_VIEW_HEIGHT);
                webViewFrame = CGRectMake(WEB_VIEW_MRG_HORIZONTAL, WEB_VIEW_MRG_VERTICAL, IPHONE_WEB_VIEW_WIDTH, IPHONE_WEB_VIEW_HEIGHT);
            }
        }
        
        [_baseView setFrame:baseViewFrame];
        [_containerView setFrame:containerFrame];
        [_webView setFrame:webViewFrame];
        
    }
    
        //important 屏幕中心点不区分横竖屏的情况
    if (isiPad) 
    {
        [_baseView setCenter:CGPointMake(768 / 2.0f, 1024 / 2.0f)];
    }
    else
    {
        
        if ((int)[UIScreen mainScreen].bounds.size.height % 568 == 0)
        {
            [_baseView setCenter:CGPointMake(320 / 2.0f, 568 / 2.0f)];
        }
        else
        {
            [_baseView setCenter:CGPointMake(320 / 2.0f, 480 / 2.0f)];
        }
    }
    
    float closeBtnWidth = 13;
    _closeBtn.frame = CGRectMake(_containerView.frame.size.width - closeBtnWidth - 2, 1, closeBtnWidth, closeBtnWidth);
}

    //根据当前屏幕转向调整frame
- (void)sizeToFitOrientation:(UIInterfaceOrientation)orientation
{
    [_baseView setTransform:CGAffineTransformIdentity];
    
    [self modifyViewFrame:orientation];
    
    [_baseView setTransform:[self transformForOrientation:orientation]];
    
    previousOrientation = orientation;
}

    //判断并执行调用转屏动画
- (void)deviceOrientationDidChange:(NSNotification *)notification
{
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
	if ([self shouldRotateToOrientation:orientation])
    {
        NSTimeInterval duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
        
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:duration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[self sizeToFitOrientation:orientation];
		[UIView commitAnimations];
	}
}




- (void) show:(UIWebView *)webView;
{
    if (!webView) 
    {
        return;
    }
    
        // important
    [self retain];    
    
    _webView = webView;
    
        // important 如果当前动作在非ModelView模式View中被执行就要加下面这句(因为弹出ModelView时实际上也执行了下面的方法)
    [[UIApplication sharedApplication].keyWindow makeKeyAndVisible];
    UIWindow *window = [UIApplication sharedApplication].keyWindow ;
    
    _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_containerView addSubview:webView];
    
    _closeBtn.showsTouchWhenHighlighted = YES;
    [_closeBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"close" ofType:@"png"]] forState:UIControlStateNormal];
    [_closeBtn addTarget:self action:@selector(handleClickCloseBtn) forControlEvents:UIControlEventTouchUpInside];
    [_containerView addSubview:_closeBtn];
    
    [window addSubview:_baseView];
    [self sizeToFitOrientation:[UIApplication sharedApplication].statusBarOrientation];
    
    
    _containerView.alpha = 0.0f;
    CGAffineTransform transform = CGAffineTransformIdentity;
    _containerView.transform = CGAffineTransformScale(transform, 0.3, 0.3);
    [UIView setAnimationDuration:0.2];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(scalAnimation)];
    _containerView.alpha = 1.0f;
    _containerView.transform = CGAffineTransformScale(transform, 1.1, 1.1);
    [UIView commitAnimations];
    
    [self addObservers];
}



- (void) scalAnimation;
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    _containerView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
    _containerView.alpha = 1.0f;
    [UIView commitAnimations];
}

- (void) hide;
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(hideAndCleanUp)];
    [UIView setAnimationDuration:0.3];
    CGAffineTransform transform = CGAffineTransformIdentity;
    _containerView.transform = CGAffineTransformScale(transform, 0.3, 0.3);
    _containerView.alpha = 0.0f;
    [UIView commitAnimations];
}


- (void)handleClickCloseBtn
{
    [self hide];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SNS_Clicked_Cancel_Btn object:nil];
}

- (void) hideAndCleanUp;
{
    [_baseView removeFromSuperview];
    [self release];
}


@end
