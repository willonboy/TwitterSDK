//
//  MainViewController.h
//  TwitterDemo
//
//  Created by zhangtao on 13-1-30.
//  Copyright (c) 2013年 willonboy.tk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WZTwitter.h"
#import "AlertOauthPageAnimation.h"

@interface MainViewController : UIViewController<WZTwitterDelegate>
{
    WZTwitter   *_twitter;
    UIWebView   *_webview;
    AlertOauthPageAnimation     *_oauthPageAnimation;
    
}


- (void) addBtns;

- (void) handleBtnsClicked:(id) sender;






@end






