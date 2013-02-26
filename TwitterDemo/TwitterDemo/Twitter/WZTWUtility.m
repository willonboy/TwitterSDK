

#import "WZTWUtility.h"
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonCryptor.h>
#import "JSONKit.h"
#import "WZTWConfig.h"
#import "GTMBase64.h"

@implementation WZTWUtility

- (void)dealloc 
{
    [super dealloc];
}

- (id)init
{
    return nil;
}

    //解析URL参数
+ (NSDictionary *)parseURLParams:(NSString *)query
{
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
	for (NSString *pair in pairs) 
    {
		NSArray *kv = [pair componentsSeparatedByString:@"="];
        if (kv.count == 2) 
        {
            NSString *val =[[kv objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [params setObject:val forKey:[kv objectAtIndex:0]];
        }
	}
    return [params autorelease];
}

    //使用传入的baseURL地址和参数集合构造含参数的请求URL
+ (NSURL*)generateURL:(NSString*)baseURL params:(NSDictionary*)params 
{
    if (params)
    {
        NSMutableArray* pairs = [NSMutableArray array];
        for (NSString* key in params.keyEnumerator) 
        {
            NSString* value = [params objectForKey:key];
            NSString* escaped_value = (NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                          NULL, /* allocator */
                                                                                          (CFStringRef)value,
                                                                                          NULL, /* charactersToLeaveUnescaped */
                                                                                          (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                          kCFStringEncodingUTF8);
            
            [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
            [escaped_value release];
        }
        
        NSString* query = [pairs componentsJoinedByString:@"&"];
        NSString* url = [NSString stringWithFormat:@"%@?%@", baseURL, query];
        
        NSLog(@"generateURL is %@", url);
        return [NSURL URLWithString:url];
    } 
    else 
    {
        return [NSURL URLWithString:baseURL];
    }
}

    //根据指定的参数名，从URL中找出并返回对应的参数值
+ (NSString *)getValueStringFromUrl:(NSString *)url forParam:(NSString *)param
{
    NSString * str = nil;
    NSRange start = [url rangeOfString:[param stringByAppendingString:@"="]];
    
    if (start.location != NSNotFound) 
    {
        NSRange end = [[url substringFromIndex:start.location + start.length] rangeOfString:@"&"];
        NSUInteger offset = start.location+start.length;
        str = end.location == NSNotFound ? [url substringFromIndex:offset] : [url substringWithRange:NSMakeRange(offset, end.location)];
        str = [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    
    return str;
}

+ (NSString *)encodedURLParameterString:(NSString *)value
{
    NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                           (CFStringRef)value,
                                                                           NULL,
                                                                           CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                           kCFStringEncodingUTF8);
	return [result autorelease];
}

    //对输入的字符串进行MD5计算并输出MD5值校检码
+ (NSString *)md5HexDigest:(NSString *)input
{
    const char* str = [input UTF8String];
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5(str, strlen(str), result);
    NSMutableString *returnHashSum = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    
    for (int i=0; i<CC_MD5_DIGEST_LENGTH; i++) 
    {
        [returnHashSum appendFormat:@"%02x", result[i]];
    }
	
	return returnHashSum;
}

    // http://stackoverflow.com/questions/1353771/trying-to-write-nsstring-sha1-function-but-its-returning-null
+ (NSString *)sha1:(NSString *)str
{
	const char *cStr = [str UTF8String];
	unsigned char result[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1(cStr, strlen(cStr), result);
    
	NSMutableString *resultStr = [NSMutableString stringWithCapacity:20];
	for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
    {
		[resultStr appendFormat:@"%02X", result[i]];
	}
	return [resultStr lowercaseString];
}

+ (NSString *)hmac_sha1:(NSString *)key text:(NSString *)text
{
    
    const char *cKey  = [key cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData = [text cStringUsingEncoding:NSUTF8StringEncoding];
    
    char cHMAC[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:CC_SHA1_DIGEST_LENGTH];
    NSString *hash = [GTMBase64 stringByEncodingData:HMAC];    //base64 编码
    [HMAC release];
    return hash;
}


    //https://dev.twitter.com/docs/auth/creating-signature
    //针对Twitter开放平台接口传参需求计算签名 tokenSecret可能为:''  paramsDict必需要包含那个必须的健值对"auth_*"
+ (NSString *)generateSignature:(NSMutableDictionary *)paramsDict tokenSecret:(NSString *)tokenSecret
                     requestUrl:(NSString *)requestUrl method:(NSString *)method
{
	NSArray* keys = [paramsDict.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray *keyValueArr = [NSMutableArray arrayWithCapacity:[keys count]];
        //连接成'key1=value1&key2=value2'的转义后的形式，且key经过了排序
    for (id key in keys)
    {
            //参数健与值都需要URLEncode
        NSString *val = [self encodedURLParameterString:[paramsDict valueForKey:key]];
        [keyValueArr addObject:[NSString stringWithFormat:@"%@=%@", [self encodedURLParameterString:key], val]];
    }
        //连接成'key1=value1&key2=value2'的转义后的形式
    NSString *keyValueStr = [keyValueArr componentsJoinedByString:@"&"];
        //再将query形式的参数字符串再进行URLEncode处理
    keyValueStr = [self encodedURLParameterString:keyValueStr];
        //最后生成签名用的Basestring 格式为:method&request_url&key=value,key=value  (request_url同样需要URLEncode)
    NSMutableString *baseString = [NSMutableString stringWithFormat:@"%@&%@&%@", method, [self encodedURLParameterString:requestUrl], keyValueStr];
    
    NSLog(@"Sig original paras is %@", baseString);
	
        //HMAC-SHA1签名
    NSString *oauth_signature = [self hmac_sha1:[NSString stringWithFormat:@"%@&%@", ConsumerSecret, tokenSecret] text:baseString];
    
    return oauth_signature;
}

    //对字符串进行URL编码转换
+ (NSString*)encodeString:(NSString*)string urlEncode:(NSStringEncoding)encoding 
{
    NSMutableString *escaped = [NSMutableString string];
    [escaped setString:[string stringByAddingPercentEscapesUsingEncoding:encoding]];
    
    [escaped replaceOccurrencesOfString:@"&" withString:@"%26" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"+" withString:@"%2B" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"," withString:@"%2C" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@":" withString:@"%3A" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@";" withString:@"%3B" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"=" withString:@"%3D" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"?" withString:@"%3F" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"@" withString:@"%40" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@" " withString:@"+" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"\t" withString:@"%09" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"#" withString:@"%23" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"<" withString:@"%3C" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@">" withString:@"%3E" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"\"" withString:@"%22" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    [escaped replaceOccurrencesOfString:@"\n" withString:@"%0A" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
    
    return escaped;
}

+ (NSDate *)getDateFromString:(NSString *)dateTime
{
	NSDate *expirationDate =nil;
	if (dateTime != nil) 
    {
		int expVal = [dateTime intValue];
		if (expVal == 0) 
        {
			expirationDate = [NSDate distantFuture];
		} 
        else 
        {
			expirationDate = [NSDate dateWithTimeIntervalSinceNow:expVal];
		} 
	}
	
	return expirationDate;
}

    //_params 中key为media[]的值为UIImage
+ (NSMutableData *)generatePostBody:(NSDictionary *)_params isUploadFile:(BOOL) isUpload
{
	NSMutableData *body = [NSMutableData data];
	NSString *endLine = [NSString stringWithFormat:@"\r\n--%@\r\n", TWUploadFileFormBoundary];
	NSMutableArray *pairs = [NSMutableArray array];
    NSArray* keys = [_params.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    
    if (isUpload) 
    {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", TWUploadFileFormBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        for(NSString *key in [keys objectEnumerator])
        {
            if ([key isEqualToString:@"media[]"])
            {
                continue;
            }
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name = \"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[_params valueForKey:key] dataUsingEncoding:NSUTF8StringEncoding]];
            
            [body appendData:[endLine dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
        
        NSData *_dataParam=[_params valueForKey:@"media[]"];
        NSData *imageData = UIImagePNGRepresentation((UIImage*)_dataParam);
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"media[]\";filename=\"media.png\""] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[endLine dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type:image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]]; 
        
            //add by william 2012-6-15
        NSLog(@"Here is Twitter upload img request body paras %@", [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease]);
        
        [body appendData:imageData];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", TWUploadFileFormBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    else 
    {
        for (NSString* key  in [keys objectEnumerator]) 
        {
            NSString* value = [_params objectForKey:key];
            NSString* value_str = [WZTWUtility encodeString:value urlEncode:NSUTF8StringEncoding];
            [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, value_str]];
        }
        
        NSString* params = [pairs componentsJoinedByString:@"&"];
        [body appendData:[params dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSLog(@"Here is request body paras %@", [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease]);
    }
    return body;
}




@end













