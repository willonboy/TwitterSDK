//
//  WZTwitter.m
//  TwitterDemo
//
//  Created by willonboy zhang on 12-6-26.
//  Copyright (c) 2012年 willonboy.tk. All rights reserved.
//

    //介绍文章: http://www.keakon.net/2010/06/18/TwitterAPI开发与OAuth介绍
    //授权流程:https://dev.twitter.com/docs/auth/implementing-sign-twitter




    //授权及api相关  所有API请求均要带Authorization 详细说明:https://dev.twitter.com/docs/auth/authorizing-request
    //Twitter REST API SERVER URL
#define TWAPI_1_1_ServerBaseUrl                 (@"https://api.twitter.com/1.1/")
    //第一步:先取得OAuth Request Token  [POST]
#define TWOauth1_0A_Request_Token_Url           (@"https://api.twitter.com/oauth/request_token")


    //第二步用取得的OAuth Request Token去访问用户授权界面 [GET]
#define TWOauth1_0A_Authorize_Url               (@"https://api.twitter.com/oauth/authorize?oauth_token=")//oauth_token是第一步取得的OAuth Request Token
    //#define TWOauth1_0_Access_Token_Url            (@"https://api.twitter.com/oauth/authenticate?oauth_token=")//oauth_token是第一步取得的request_token



    //第三步:用户点击allow后，Service Provider确认请求，将用户重定向回callback URL，并返回oauth_token(还是OAuth Request Token)和oauth_verifier。因此第三步就是拿到oauth_verifier，oauth_token(即:OAuth Request Token 此时要把它放在HTTPHeader->Authorization中) 换取 OAuth Access Token
    //[POST]
#define TWOauth1_0A_Exchange_Access_Token_Url   (@"https://api.twitter.com/oauth/access_token")

/* oauth/access_token的POST数据结构
 
POST /oauth/access_token HTTP/1.1
User-Agent: themattharris' HTTP Client
Host: api.twitter.com
Authorization: OAuth oauth_consumer_key="cChZNFj6T5R0TigYB9yd1w",
          oauth_nonce="a9900fe68e2573b27a37f10fbad6a755",
          oauth_signature="39cipBtIOHEEnybAR4sATQTpl2I%3D",
          oauth_signature_method="HMAC-SHA1",
          oauth_timestamp="1318467427",
          oauth_token="NPcudxy0yU5T3tBzho7iCotZ3cnetKwcTIRlX0iwRl0",
          oauth_version="1.0"
Content-Length: 57
Content-Type: application/x-www-form-urlencoded
          
oauth_verifier=uw7NjWHT6OJ1MpJOXsHfNxoAhPKpgI8BlYDhxEjIBY

*/


/* oauth/access_token请求成功后返回数据结构
 
HTTP/1.1 200 OK
Date: Thu, 13 Oct 2011 00:57:08 GMT
Status: 200 OK
Content-Type: text/html; charset=utf-8
Content-Length: 157
Pragma: no-cache
Expires: Tue, 31 Mar 1981 05:00:00 GMT
Cache-Control: no-cache, no-store, must-revalidate, pre-check=0, post-check=0
Vary: Accept-Encoding
Server: tfe

oauth_token=7588892-kagSNqWge8gB1WwE3plnFsJHAZVfxWD7Vb57p0b4&
oauth_token_secret=PbKfYqSryyeKDWz4ebtY3o5ogNLG11WJuZBc9fQrQo&user_id=123234&screen_name=xxxx

*/






#define WZTW_Access_Token               (@"TWAccessToken")
#define WZTW_Token_Secret               (@"TWTokenSecret")
#define WZTW_Current_Login_UserId       (@"TWCurrentLoginUserId")
#define WZTW_Current_Login_User_Name    (@"TWCurrentLoginUserName")
#define WZTW_Oauth_Version              (@"1.0")
#define WZTW_Oauth_Signature_Method     (@"HMAC-SHA1")


#import "WZTwitter.h"
#import <UIKit/UIKit.h>
#import "JSONKit.h"

@interface WZTwitter()
{
    WZTWRequest     *_request;
    NSString        *_requestToken;
    NSString        *_requestTokenSecret;
    NSString        *_accessToken;
    NSString        *_accessTokenSecret;
    NSString        *_userId;
    NSString        *_userScreenName;
}

- (NSMutableDictionary *)AuthorizationHeaderDictionary;

- (NSString *)AuthorizationHeaderValue:(NSDictionary *)requestParas requestUrl:(NSString *)requestUrl method:(NSString *)method;

@end


@implementation WZTwitter
@synthesize delegate;
@synthesize webview;

- (void)dealloc 
{
    self.delegate = nil;
    
    if (_request)
    {
        _request.delegate = nil;
        [_request release];
        _request = nil;
    }
    
    if (self.webview)
    {
        self.webview = nil;
    }
    
    if (_requestToken)
    {
        [_requestToken release];
        _requestToken = nil;
    }
    
    if (_requestTokenSecret)
    {
        [_requestTokenSecret release];
        _requestTokenSecret = nil;
    }
    
    if (_accessToken)
    {
        [_accessToken release];
        _accessToken = nil;
    }
    
    if (_accessTokenSecret)
    {
        [_accessTokenSecret release];
        _accessTokenSecret = nil;
    }
    
    if (_userId)
    {
        [_userId release];
        _userId = nil;
    }
    
    if (_userScreenName)
    {
        [_userScreenName release];
        _userScreenName = nil;
    }
    
    [super dealloc];
}

- (id)init 
{
    self = [super init];
    if (self) 
    {
        if (!_request)
        {
            _request = [[WZTWRequest alloc] init];
            _request.delegate = self;
        }
    }
    return self;
}

- (BOOL)isLogin;
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString    *accessToken    = [userDefault valueForKey:WZTW_Access_Token];
    NSString    *tokenSecret  = [userDefault valueForKey:WZTW_Token_Secret];
    
    if (accessToken && accessToken.length > 0 && ![accessToken isEqualToString:@"(null)"]) 
    {
        if (tokenSecret && tokenSecret.length > 0 && ![tokenSecret isEqualToString:@"(null)"])
        {
            _accessToken        = [accessToken retain];
            _accessTokenSecret  = [tokenSecret retain];
            
            _userId             = [[userDefault valueForKey:WZTW_Current_Login_UserId] retain];
            _userScreenName     = [[userDefault valueForKey:WZTW_Current_Login_User_Name] retain];
            return YES;
        }
    }
    
    return NO;
}


    //这里将重设传入的webview.delegate值
- (void)authorization:(UIWebView *) webview_ ;
{
    if (webview_)
    {
        self.webview = nil;
        self.webview = webview_;
    }
    else if(!self.webview)
    {
        NSLog(@"Twitter 没有传入登录时载入网页的webview");
        return;
    }
    
    
    /*
     POST /oauth/request_token HTTP/1.1
     User-Agent: themattharris' HTTP Client
     Host: api.twitter.com
     Accept: *\/*
     Authorization:
     OAuth oauth_callback="http%3A%2F%2Flocalhost%2Fsign-in-with-twitter%2F",
     oauth_consumer_key="cChZNFj6T5R0TigYB9yd1w",
     oauth_nonce="ea9ec8429b68d6b77cd5600adbbb0456",
     oauth_signature="F1Li3tvehgcraF8DMJ7OyxO4w9Y%3D",
     oauth_signature_method="HMAC-SHA1",
     oauth_timestamp="1318467427",
     oauth_version="1.0"
     */
    NSMutableURLRequest* requestTokenRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:TWOauth1_0A_Request_Token_Url]];
    requestTokenRequest.HTTPMethod = @"POST";
    NSDictionary *postParasDic = [NSDictionary dictionaryWithObject:WZTW_Redirect_URL forKey:@"oauth_callback"];
    
    NSString *authorizationStr = [self AuthorizationHeaderValue:postParasDic requestUrl:TWOauth1_0A_Request_Token_Url method:@"POST"];
    [requestTokenRequest addValue:authorizationStr forHTTPHeaderField:@"Authorization"];
    
    
    NSHTTPURLResponse* response = nil;
    NSError *error = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:requestTokenRequest
                                         returningResponse:&response
                                                     error:&error];
    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([response statusCode] != 200)
    {
        NSLog(@"responseString %@", responseString);
            //出错了
        if (self.delegate && [self.delegate respondsToSelector:@selector(didLoginSuccessOrFailed:)])
        {
            [self.delegate didLoginSuccessOrFailed:NO];
                //self.webview.hidden = YES;
        }
        return;
    }
    else
    {
        NSDictionary *paras = [WZTWUtility parseURLParams:responseString];
        NSLog(@"response paras %@", paras);
            // 成功的话会有oauth_callback_confirmed=true，没有的话说明失败了
        if ([(NSString *)[paras objectForKey:@"oauth_callback_confirmed"] isEqualToString:@"true"])
        {
            if ([paras.allKeys containsObject:@"oauth_token"])
            {
                _requestToken = [paras objectForKey:@"oauth_token"];
                [_requestToken retain];
            }
            
            if ([paras.allKeys containsObject:@"oauth_token_secret"])
            {
                _requestTokenSecret = [paras objectForKey:@"oauth_token_secret"];
                [_requestTokenSecret retain];
            }
        }
        else
        {
                //出错了
            if (self.delegate && [self.delegate respondsToSelector:@selector(didLoginSuccessOrFailed:)])
            {
                [self.delegate didLoginSuccessOrFailed:NO];
                self.webview.hidden = YES;
            }
            return;
        }
    }

    
    
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityView.center = self.webview.center;
    [self.webview addSubview:activityView];
    [activityView startAnimating];
    [activityView release];
    
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", TWOauth1_0A_Authorize_Url, _requestToken]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    
    webview_.delegate = self;
    [webview_ loadRequest:request];
}

- (void)logout;
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault removeObjectForKey:WZTW_Access_Token];
    [userDefault removeObjectForKey:WZTW_Token_Secret];
    [userDefault removeObjectForKey:WZTW_Current_Login_UserId];
    [userDefault removeObjectForKey:WZTW_Current_Login_User_Name];
    [userDefault synchronize];
    
    for (NSHTTPCookie * cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) 
    {
        NSLog(@"cookie.domain %@", cookie.domain);
        if ([cookie isSessionOnly] && ([cookie.domain rangeOfString:@"twitter.com"].location > 0) )
        {
            NSLog(@"Delete cookie.domain %@", cookie.domain);
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didLogoutSuccessOrFailed:)])
    {
        [self.delegate didLogoutSuccessOrFailed:YES];
    }
    
}

- (void)getUserInfo:(NSString *)userId userScreenName:(NSString *) userScreenName;
{
    NSString *api = @"users/show.json" ;
    NSString *requestUrlStr = [NSString stringWithFormat:@"%@%@", TWAPI_1_1_ServerBaseUrl, api];
    NSMutableDictionary *queryParas = [NSMutableDictionary dictionary];
    
   
    [queryParas setValue:((userId.length > 0) ? userId : _userId) forKey:@"user_id"];
    [queryParas setValue:((userScreenName.length > 0) ? userScreenName : _userScreenName) forKey:@"screen_name"];
        
    NSString *authorizationStr = [self AuthorizationHeaderValue:queryParas requestUrl:requestUrlStr method:@"GET"];
    NSMutableDictionary *headers = [[[NSMutableDictionary alloc] init] autorelease];
    [headers setValue:authorizationStr forKey:@"Authorization"];
    NSURL *requestUrl = [WZTWUtility generateURL:requestUrlStr params:queryParas];
    
    [_request sendRequest:requestUrl.absoluteString method:@"GET" apiMethod:api allHeaderField:headers httpBody:nil];
}

    //根据这篇文章所说:https://dev.twitter.com/discussions/13390 当采用multipart/form-data; POST方式而非Content-Type: x-www-form-urlencoded方式时body中的参数不加入签名!!!
- (void)publishNewPhoto:(NSString *)content imgPath:(NSString *) shareImgPath;
{
    NSString *api = @"statuses/update_with_media.json" ;
    NSString *requestUrlStr = [NSString stringWithFormat:@"%@%@", TWAPI_1_1_ServerBaseUrl, api];
    NSMutableDictionary *queryParas = [NSMutableDictionary dictionary];
    [queryParas setValue:content forKey:@"status"];
    NSString *authorizationStr = [self AuthorizationHeaderValue:queryParas requestUrl:requestUrlStr method:@"POST"];
    NSMutableDictionary *bodyParas = [NSMutableDictionary dictionary];
        //twitter 内容
    [bodyParas setValue:content forKey:@"status"];
    [bodyParas setValue:[UIImage imageWithContentsOfFile:shareImgPath] forKey:@"media[]"];
    
    NSMutableDictionary *headers = [[[NSMutableDictionary alloc] init] autorelease];
    [headers setValue:authorizationStr forKey:@"Authorization"];
    [headers setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", TWUploadFileFormBoundary] forKey:@"Content-Type"];
    
    
    NSMutableData *bodyData = [WZTWUtility generatePostBody:bodyParas isUploadFile:YES];
        //Fuck Twitter API Doc!!!https://dev.twitter.com/docs/api/1.1/post/statuses/update_with_media
    NSURL *requestUrl = [WZTWUtility generateURL:requestUrlStr params:queryParas];
    [_request sendRequest:requestUrl.absoluteString method:@"POST" apiMethod:api allHeaderField:headers httpBody:bodyData];
}

- (void)publishNewStatus:(NSString *)content;
{
    NSString *api = @"statuses/update.json" ;
    NSString *requestUrlStr = [NSString stringWithFormat:@"%@%@", TWAPI_1_1_ServerBaseUrl, api];
    NSMutableDictionary *bodyParas = [NSMutableDictionary dictionary];
        //twitter 内容
    [bodyParas setValue:content forKey:@"status"];
    NSString *authorizationStr = [self AuthorizationHeaderValue:bodyParas requestUrl:requestUrlStr method:@"POST"];
        
    NSMutableData *bodyData = [WZTWUtility generatePostBody:bodyParas isUploadFile:NO];
    
    NSMutableDictionary *headers = [[[NSMutableDictionary alloc] init] autorelease];
    [headers setValue:authorizationStr forKey:@"Authorization"];
    
    [_request sendRequest:requestUrlStr method:@"POST" apiMethod:api allHeaderField:headers httpBody:bodyData];
}

    //获取当前用户关注的人的列表
- (NSArray *)userFriendsIdsWithCompletition:(NSString *)userId;
{
    userId = (userId.length > 0) ? userId : _userId;
    NSString *api = @"friends/ids.json";
    NSString *requestUrlStr = [NSString stringWithFormat:@"%@%@", TWAPI_1_1_ServerBaseUrl, api];
    NSString *urlStr = [NSString stringWithFormat:@"%@?user_id=%@", requestUrlStr, userId];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:7.0f];
    [request setHTTPMethod:@"GET"];
    
    NSMutableDictionary *queryParas = [NSMutableDictionary dictionary];
    [queryParas setValue:((userId.length > 0) ? userId : _userId) forKey:@"user_id"];
    
    NSString *authorizationStr = [self AuthorizationHeaderValue:queryParas requestUrl:requestUrlStr method:@"GET"];
    [request addValue:authorizationStr forHTTPHeaderField:@"Authorization"];
    
    NSHTTPURLResponse* response = nil;
    NSError *error = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
    NSString *resultData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if ([response statusCode] == 200)
    {
        NSDictionary *returnDic = [resultData objectFromJSONString];
        NSArray *friendIds = [returnDic objectForKey:@"ids"];
        return friendIds;
    }
    return nil;
}

- (void)getFriendInfoList:(NSString *)userId;
{
    NSArray *friendIds = [self userFriendsIdsWithCompletition:userId];
    NSString *parsStr = [friendIds componentsJoinedByString:@","];
    NSString *api = @"users/lookup.json";
    NSString *requestUrlStr = [NSString stringWithFormat:@"%@%@", TWAPI_1_1_ServerBaseUrl, api];
    NSMutableDictionary *queryParas = [NSMutableDictionary dictionary];
    
    [queryParas setValue:parsStr forKey:@"user_id"];
    
    NSString *authorizationStr = [self AuthorizationHeaderValue:queryParas requestUrl:requestUrlStr method:@"GET"];
    NSMutableDictionary *headers = [[[NSMutableDictionary alloc] init] autorelease];
    [headers setValue:authorizationStr forKey:@"Authorization"];
    NSURL *requestUrl = [WZTWUtility generateURL:requestUrlStr params:queryParas];
    
    [_request sendRequest:requestUrl.absoluteString method:@"GET" apiMethod:api allHeaderField:headers httpBody:nil];
}






/*
 所有API的请求都要包含下面的HTTP Header Authorization
 Authorization:
 OAuth oauth_callback="http%3A%2F%2Flocalhost%2Fsign-in-with-twitter%2F",  //[仅request token时包含]
 oauth_consumer_key="cChZNFj6T5R0TigYB9yd1w",
 oauth_nonce="ea9ec8429b68d6b77cd5600adbbb0456",
 oauth_signature="F1Li3tvehgcraF8DMJ7OyxO4w9Y%3D",
 oauth_signature_method="HMAC-SHA1",
 oauth_timestamp="1318467427",
 oauth_version="1.0",
 oauth_token="xxxx" //[仅授权成功取得request/aceess token时包含]
 */

- (NSMutableDictionary *)AuthorizationHeaderDictionary;
{
    int myRandom = random();
	NSString *oauth_nonce = [WZTWUtility sha1:[NSString stringWithFormat:@"%ld%d", time(NULL), myRandom]];
    
    NSMutableDictionary *globalParas = [[[NSMutableDictionary alloc] init] autorelease];
    [globalParas setValue:ConsumerKey forKey:@"oauth_consumer_key"];
    [globalParas setValue:oauth_nonce forKey:@"oauth_nonce"];
    [globalParas setValue:WZTW_Oauth_Signature_Method forKey:@"oauth_signature_method"];
    [globalParas setValue:[NSString stringWithFormat:@"%ld", time(NULL)] forKey:@"oauth_timestamp"];
    [globalParas setValue:WZTW_Oauth_Version forKey:@"oauth_version"];
    
        //如果已经登录就要带上_accessToken参数
    if(_accessToken.length > 0)
    {
        [globalParas setValue:_accessToken forKey:@"oauth_token"];
    }
        //如果未登录那么在用_requestToken换取_accessToken时就要带上_requestToken参数
    else if (_requestToken.length > 0)
    {
        [globalParas setValue:_requestToken forKey:@"oauth_token"];
    }
    
    return globalParas;
}


- (NSString *)AuthorizationHeaderValue:(NSDictionary *)requestParas requestUrl:(NSString *)requestUrl method:(NSString *)method;
{
        //所有请求的签名都必须要包含"oauth_*"健值对在内
    NSMutableDictionary *globalParas = [self AuthorizationHeaderDictionary];
    
    if (requestParas)
    {
        [globalParas addEntriesFromDictionary:requestParas];
    }
    
    NSArray* keys = [globalParas.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray *arr = [NSMutableArray array];
    for (NSString *key in keys)
    {
        NSString *val = [WZTWUtility encodedURLParameterString:[globalParas valueForKey:key]];
        [arr addObject:[NSString stringWithFormat:@"%@=\"%@\"", key, val]];
    }
    
    NSString *signature  = [WZTWUtility generateSignature:globalParas tokenSecret:(_accessTokenSecret ? _accessTokenSecret : @"") requestUrl:requestUrl method:method];
    [globalParas setValue:signature forKey:@"oauth_signature"];
    
    [arr addObject:[NSString stringWithFormat:@"%@=\"%@\"", @"oauth_signature", [WZTWUtility encodedURLParameterString:signature]]];
    NSLog(@"arr %@", arr);
    
    NSString *result = [NSString stringWithFormat:@"OAuth %@", [arr componentsJoinedByString:@", "]];
    NSLog(@"result %@", result);
    
    return result;
}



- (void)hideActivityIndicatorView:(UIView *)view
{
    for (UIView *subView in view.subviews)
    {
        if ([subView isKindOfClass:[UIActivityIndicatorView class]])
        {
            [(UIActivityIndicatorView *)subView stopAnimating];
            [subView removeFromSuperview];
        }
    }
}


#pragma mark - UIWebViewDelegate Method

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"Twitter OAuth1.0A request.URL is %@", request.URL);
    
    NSURL *url = request.URL;
    if (![url.absoluteString hasPrefix:WZTW_Redirect_URL])
    {
        if (navigationType == UIWebViewNavigationTypeLinkClicked)/*点击链接*/
        {
            BOOL userDidCancel = YES;
            if(userDidCancel)
            {
                if (self.delegate && [self.delegate respondsToSelector:@selector(didLoginSuccessOrFailed:)])
                {
                    [self.delegate didLoginSuccessOrFailed:NO];
                    self.webview.hidden = YES;
                }
            }
            else
            {
                [[UIApplication sharedApplication] openURL:request.URL];
            }
            return NO;
        }
        return YES;
    }
    else
    {
        NSString *query = [[url.absoluteString componentsSeparatedByString:@"?"] objectAtIndex:1]; // url中＃字符后面的部分。
        if (!query)
        {
            query = [url query];
        }
        
        NSDictionary *params = [WZTWUtility parseURLParams:query];
        NSString *oauthVerifier = [params objectForKey:@"oauth_verifier"];
        
        if(nil == oauthVerifier)
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(didLoginSuccessOrFailed:)])
            {
                [self.delegate didLoginSuccessOrFailed:NO];
                self.webview.hidden = YES;
            }
            return NO;
        }
        else
        {
            NSMutableURLRequest* requestTokenRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:TWOauth1_0A_Exchange_Access_Token_Url]];
            requestTokenRequest.HTTPMethod = @"POST";
            NSMutableDictionary *postParasDic = [NSMutableDictionary dictionaryWithObject:oauthVerifier forKey:@"oauth_verifier"];
            
            NSString *authorizationStr = [self AuthorizationHeaderValue:postParasDic requestUrl:TWOauth1_0A_Exchange_Access_Token_Url method:@"POST"];
            [requestTokenRequest addValue:authorizationStr forHTTPHeaderField:@"Authorization"];
            
            requestTokenRequest.HTTPBody = [WZTWUtility generatePostBody:postParasDic isUploadFile:NO];
            
            NSHTTPURLResponse* response = nil;
            NSError *error = nil;
            
            NSData *data = [NSURLConnection sendSynchronousRequest:requestTokenRequest
                                                 returningResponse:&response
                                                             error:&error];
            NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if ([response statusCode] != 200)
            {
                NSLog(@"responseString %@", responseString);
                    //出错了
                if (self.delegate && [self.delegate respondsToSelector:@selector(didLoginSuccessOrFailed:)])
                {
                    [self.delegate didLoginSuccessOrFailed:NO];
                    self.webview.hidden = YES;
                }
                return NO;
            }
            else
            {
                NSDictionary *paras = [WZTWUtility parseURLParams:responseString];
                NSLog(@"response paras %@", paras);
                if ([paras.allKeys containsObject:@"oauth_token"])
                {
                    _accessToken = [paras objectForKey:@"oauth_token"];
                    [_accessToken retain];
                    [[NSUserDefaults standardUserDefaults] setObject:_accessToken forKey:WZTW_Access_Token];
                }
                
                if ([paras.allKeys containsObject:@"oauth_token_secret"])
                {
                    _accessTokenSecret = [paras objectForKey:@"oauth_token_secret"];
                    [_accessTokenSecret retain];
                    [[NSUserDefaults standardUserDefaults] setObject:_accessTokenSecret forKey:WZTW_Token_Secret];
                }
                
                if ([paras.allKeys containsObject:@"screen_name"])
                {
                    _userScreenName = [paras objectForKey:@"screen_name"];
                    [_userScreenName retain];
                    [[NSUserDefaults standardUserDefaults] setObject:_userScreenName forKey:WZTW_Current_Login_User_Name];
                }
                
                if ([paras.allKeys containsObject:@"user_id"])
                {
                    _userId = [paras objectForKey:@"user_id"];
                    [_userId retain];
                    [[NSUserDefaults standardUserDefaults] setObject:_userId forKey:WZTW_Current_Login_UserId];
                }
                
                if (_accessToken.length > 0 && _accessTokenSecret.length > 0)
                {
                    if (self.delegate && [self.delegate respondsToSelector:@selector(didLoginSuccessOrFailed:)])
                    {
                        [self.delegate didLoginSuccessOrFailed:YES];
                    }
                    self.webview.hidden = YES;
                    
                    return NO;
                }
            }
        }
    }
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self hideActivityIndicatorView:webView];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self hideActivityIndicatorView:webView];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didLoginSuccessOrFailed:)])
    {
        [self.delegate didLoginSuccessOrFailed:NO];
    }
}




#pragma mark -
#pragma mark - WZTWRequestDelegate


- (void)requestFailed:(WZTWRequest *) request error:(NSError *)err;
{
    if ([request.api isEqualToString:@"users/show.json"])
    {
        NSLog(@"获取用户信息失败");
    }
    else if ([request.api isEqualToString:@"statuses/update.json"])
    {
        NSLog(@"发布新状态失败");
    }
    else if ([request.api isEqualToString:@"statuses/update_with_media.json"])
    {
        NSLog(@"发布照片失败");
    }    
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestFailed:error:apiMethod:)])
    {
        [self.delegate requestFailed:self error:err apiMethod:request.api];
    }
}

- (void)receiveResponseData:(WZTWRequest *) request responseData:(id) data;
{
    if ([request.api isEqualToString:@"users/show.json"])
    {
        NSLog(@"获取用户信息成功");
    }
    else if ([request.api isEqualToString:@"statuses/update.json"])
    {
        NSLog(@"发布新状态成功");
    }
    else if ([request.api isEqualToString:@"statuses/update_with_media.json"])
    {
        NSLog(@"发布照片成功");
    } 
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(receivedResponseData:responseData:apiMethod:)])
    {
        [self.delegate receivedResponseData:self responseData:data apiMethod:request.api];
    }
}


@end











