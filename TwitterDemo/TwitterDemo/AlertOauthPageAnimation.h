//
//  AlertOauthPageAnimation.h
//  WeiboBox_Demo
//
//  Created by willonboy zhang on 12-7-4.
//  Copyright (c) 2012年 willonboy.tk. All rights reserved.
//


/*******
 
 引用方式
 
 AlertOauthPageAnimation *oauthPageAnimation = [[AlertOauthPageAnimation alloc] init];
 [oauthPageAnimation show:_webView];
 [oauthPageAnimation release];
 
 在登录成功或失败的地方调用实例隐藏方法释放掉对象
 
 [oauthPageAnimation hide];
 oauthPageAnimation = nil;
 
 
 ******/


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AlertOauthPageAnimation : NSObject
{
    UIView      *_baseView;
    UIView      *_containerView;
    UIWebView   *_webView;
    UIButton    *_closeBtn;
    
    UIInterfaceOrientation previousOrientation;
}

- (void) show:(UIWebView *)webView;

- (void) hide;

@end
