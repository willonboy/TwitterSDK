//
//  MainViewController.m
//  TwitterDemo
//
//  Created by zhangtao on 13-1-30.
//  Copyright (c) 2013年 willonboy.tk. All rights reserved.
//




#import "MainViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    if (_twitter)
    {
        [_twitter release];
        _twitter.delegate = nil;
        _twitter = nil;
    }
    if (_webview)
    {
        [_webview release];
        _webview = nil;
    }
    
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _twitter = [[WZTwitter alloc] init];
    _twitter.delegate = self;
    
    if (![_twitter isLogin])
            //if (YES)
    {
        
        if (!_webview)
        {
            _webview = [[UIWebView alloc] init];
            _webview.userInteractionEnabled = YES;
        }
        _oauthPageAnimation = [[AlertOauthPageAnimation alloc] init];
        [_oauthPageAnimation show:_webview];
        [_oauthPageAnimation release];
        
        [_twitter authorization:_webview];
        
    }
    else
    {
        [self addBtns];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


- (void)addBtns
{
    UIButton *userInfoBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    userInfoBtn.frame = CGRectMake(50, 100, 200, 30);
    [userInfoBtn setTitle:@"User Info" forState:UIControlStateNormal];
    [userInfoBtn addTarget:self action:@selector(handleBtnsClicked:) forControlEvents:UIControlEventTouchUpInside];
    userInfoBtn.tag = 100;
    [self.view addSubview:userInfoBtn];
    
    UIButton *statusBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    statusBtn.frame = CGRectMake(50, 150, 200, 30);
    [statusBtn setTitle:@"Send Msg" forState:UIControlStateNormal];
    [statusBtn addTarget:self action:@selector(handleBtnsClicked:) forControlEvents:UIControlEventTouchUpInside];
    statusBtn.tag = 101;
    [self.view addSubview:statusBtn];
    
    UIButton *photoBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    photoBtn.frame = CGRectMake(50, 200, 200, 30);
    [photoBtn setTitle:@"Send Photo" forState:UIControlStateNormal];
    [photoBtn addTarget:self action:@selector(handleBtnsClicked:) forControlEvents:UIControlEventTouchUpInside];
    photoBtn.tag = 102;
    [self.view addSubview:photoBtn];
    
}

- (void)handleBtnsClicked:(id)sender
{
    switch (((UIButton *)sender).tag)
    {
        case 100:
            [_twitter getUserInfo:nil userScreenName:nil];
            break;
            
        case 101:
                //[_twitter getFriendInfoList:nil];
            [_twitter publishNewStatus:@"this is test "];
            break;
            
        case 102:
            [_twitter publishNewPhoto:@"this is test from twitter" imgPath:[[NSBundle mainBundle] pathForResource:@"Default" ofType:@"png"]];
            break;
            
        default:
            break;
    }
}


#pragma mark - WZTwitterDelegate

- (void)didLoginSuccessOrFailed:(BOOL) isSuccess;
{
    if (isSuccess)
    {
        NSLog(@"登陆成功");
        [self addBtns];
        
        [_oauthPageAnimation hide];
        _oauthPageAnimation = nil;
    }
}

- (void)didLogoutSuccessOrFailed:(BOOL) isSuccess;
{
    
}

- (void)receivedResponseData:(WZTwitter *)sender responseData:(NSString *)data apiMethod:(NSString *)apiMethod;
{
    NSLog(@"发布成功");
}

- (void)requestFailed:(WZTwitter *)sender error:(NSError *)err apiMethod:(NSString *)apiMethod;
{
    
}

@end







