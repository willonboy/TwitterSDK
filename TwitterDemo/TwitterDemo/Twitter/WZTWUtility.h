


#define TWUploadFileFormBoundary (@"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3")


#import <Foundation/Foundation.h>


@interface WZTWUtility : NSObject

    //解析URL参数
+ (NSDictionary *)parseURLParams:(NSString *)query;

    //使用传入的baseURL地址和参数集合构造含参数的请求URL
+ (NSURL*)generateURL:(NSString*)baseURL params:(NSDictionary*)params;

    //根据指定的参数名，从URL中找出并返回对应的参数值
+ (NSString *)getValueStringFromUrl:(NSString *)url forParam:(NSString *)param;

+ (NSString *)encodedURLParameterString:(NSString *)value;

    //对输入的字符串进行MD5计算并输出MD5值校检码
+ (NSString *)md5HexDigest:(NSString *)input;

    //对输入的字符串进行SHA1计算并输出SHA1值校检码
+ (NSString *)sha1:(NSString *)str;

+ (NSString *)hmac_sha1:(NSString *)key text:(NSString *)text;

    //针对开放平台接口传参需求计算签名
+ (NSString *)generateSignature:(NSMutableDictionary *)paramsDict tokenSecret:(NSString *)tokenSecret
                     requestUrl:(NSString *)requestUrl method:(NSString *)method;

    //对字符串进行URL编码转换
+ (NSString*)encodeString:(NSString*)string urlEncode:(NSStringEncoding)encoding;

    //将日期字符串转换为字符串类型
+ (NSDate *)getDateFromString:(NSString *)dateTime;

+ (NSMutableData *)generatePostBody:(NSDictionary *)_params isUploadFile:(BOOL) isUpload;


@end


