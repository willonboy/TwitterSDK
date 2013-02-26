//
//  WZTWRequest.m
//  TwitterDemo
//
//  Created by willonboy zhang on 12-6-26.
//  Copyright (c) 2012年 willonboy.tk. All rights reserved.
//

#import "WZTWRequest.h"

@interface WZTWRequest()

- (void) handleResponseData:(NSData *)data;

@end













@implementation WZTWRequest
@synthesize delegate;
@synthesize requestUrl;
@synthesize api = _api;

- (void)dealloc
{
    [_requestUrl release];
    [_api release];
	
	[super dealloc];
}

- (void)sendRequest:(NSString *)url method:(NSString *)method apiMethod:(NSString *)apiMethod allHeaderField:(NSDictionary *)headerField httpBody:(NSData *)postBody
{
    if (!url)
    {
        NSLog(@"URL OR MEHTOD CAN NOT EMPTY!");
        return;
    }
        //默值为GET方式
    method = !method ? @"GET" : method;
    
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:WZTWRequestTimeout];
	[request setAllHTTPHeaderFields:headerField];
	[request setHTTPMethod:method];
	[request setHTTPBody:postBody];
    
    _requestUrl = [url copy];
    _api = [apiMethod copy];
    
		//send request asynch
	_connection = [NSURLConnection connectionWithRequest:request delegate:self];
	
}

#pragma mark -
#pragma mark NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
{
    if (_connection != connection)
    {
        return;
    }
    
	if (_responseData == nil)
	{
		_responseData = [[NSMutableData alloc] init];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
    if (_connection != connection)
    {
        return;
    }
    
	[_responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
    if (_connection != connection)
    {
        return;
    }
    
	[self handleResponseData:_responseData];
	
	[_responseData release];
	_responseData = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
    if (_connection != connection)
    {
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestFailed:error:)]) 
    {
        [self.delegate performSelector:@selector(requestFailed:error:) withObject:self withObject:error];
    }
    
	[_responseData release];
	_responseData = nil;
}


    //返回错误信息似乎未能一致 (错误信息有可能是XML格式数据)
- (void) handleResponseData:(NSData *)data;
{
    NSString *errorCode = nil;
    NSString *errorMsg  = nil;
    NSString *responseStr = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSLog(@"handleResponseData %@", responseStr);
        //NSLog(@"data is %@ ", data);
    id<NSObject> responseData = [data objectFromJSONData];
    
    if ([responseData isKindOfClass:[NSDictionary class]])
    {
            //{"errors":[{"message":"Error processing your OAuth request: Read-only application cannot POST","code":89}]}
        NSArray *errs = [(NSDictionary *)responseData objectForKey:@"errors"];
        if (errs && [errs count] > 0)
        {
            NSDictionary *firstErr = [errs objectAtIndex:0];
            errorCode = [firstErr objectForKey:@"code"];
            errorMsg = [firstErr objectForKey:@"message"];
        }
    }
    
    if (errorCode)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(requestFailed:error:)]) 
        {
            NSError *err = [NSError errorWithDomain:@"error.twitter.com" code:[errorCode integerValue] userInfo:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:errorCode, errorMsg, nil] forKeys:[NSArray arrayWithObjects:@"error_code", @"error_msg", nil]]];
            [self.delegate performSelector:@selector(requestFailed:error:) withObject:self withObject:err];
        }
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(receiveResponseData:responseData:)]) 
    {
        [self.delegate performSelector:@selector(receiveResponseData:responseData:) withObject:self withObject:responseStr];
    }
}



@end












