//
//  WZTwitter.h
//  TwitterDemo
//
//  Created by willonboy zhang on 12-6-26.
//  Copyright (c) 2012年 willonboy.tk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WZTWConfig.h"
#import "WZTWRequest.h"
#import "WZTWUtility.h"
#import <UIKit/UIKit.h>


@protocol WZTwitterDelegate;

@interface WZTwitter : NSObject<UIWebViewDelegate, WZTWRequestDelegate>

@property (nonatomic, assign) id<WZTwitterDelegate>    delegate;
@property (nonatomic, retain) UIWebView             *webview ;

- (BOOL)isLogin;

- (void)authorization:(UIWebView *) webview_ ;

- (void)logout;

- (void)getUserInfo:(NSString *)userId userScreenName:(NSString *) userScreenName;;

- (void)publishNewPhoto:(NSString *)content imgPath:(NSString *) shareImgPath;

- (void)publishNewStatus:(NSString *)content ;

- (void)getFriendInfoList:(NSString *)userId;




@end













@protocol WZTwitterDelegate <NSObject>

- (void)didLoginSuccessOrFailed:(BOOL) isSuccess;

- (void)didLogoutSuccessOrFailed:(BOOL) isSuccess;

- (void)receivedResponseData:(WZTwitter *)sender responseData:(NSString *)data apiMethod:(NSString *) apiMethod;

- (void)requestFailed:(WZTwitter *)sender error:(NSError *)err apiMethod:(NSString *) apiMethod;


@end







