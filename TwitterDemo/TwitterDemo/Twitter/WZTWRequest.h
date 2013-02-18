//
//  WZTWRequest.h
//  TwitterDemo
//
//  Created by willonboy zhang on 12-6-26.
//  Copyright (c) 2012年 willonboy.tk. All rights reserved.
//

#define WZTWRequestTimeout    (30)

#import <Foundation/Foundation.h>
#import "JSONKit.h"
#import "WZTWConfig.h"




@protocol WZTWRequestDelegate;

@interface WZTWRequest : NSObject
{
	NSURLConnection *_connection;
	NSMutableData	*_responseData;
    
    NSString        *_requestUrl;
    NSString        *_api;
}
@property (nonatomic, assign) id<WZTWRequestDelegate> delegate;
@property (nonatomic, readonly) NSString *requestUrl;
@property (nonatomic, readonly) NSString *api;

- (void)sendRequest:(NSString *)url method:(NSString *)method apiMethod:(NSString *)apiMethod allHeaderField:(NSDictionary *)headerField httpBody:(NSData *)postBody;


@end





@protocol WZTWRequestDelegate <NSObject>

- (void)requestFailed:(WZTWRequest *) request error:(NSError *)err;

- (void)receiveResponseData:(WZTWRequest *) request responseData:(id) data;

@end