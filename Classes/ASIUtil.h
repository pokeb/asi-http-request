//
//  ASIUtil.h
//  CloudAtlas
//
//  Created by apple on 13-3-6.
//  Copyright (c) 2013年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"
#import "ASIDownloadCache.h"
#import "ASIFormDataRequest.h"
#import "Reachability.h"

typedef void(^ASIUtilBlock)(ASIHTTPRequest *request);

@interface ASIUtil : NSObject

@property(nonatomic,retain)NSMutableArray *ASIHTTPRequestArray;

+ (ASIUtil *)sharedManager ;

-(void)destroyRequest;

//判断网络是否存在
+(BOOL)isReachable;
//判断网络是否是wifi
+(BOOL)isWifiConn;

//get方式
//无缓存机制
+(NSString*)getDataStr:(NSString*)urlStr;
+(NSData*)getData:(NSString*)urlStr;
+(void)getDataWithBlock:(NSString*)urlStr sender:(id)sender successBlock:(ASIUtilBlock)successBlock failedBlock:(ASIUtilBlock)failedBlock;

//有缓存机制
+(NSString*)getDataStrCache:(NSString*)urlStr;
+(NSData*)getDataCache:(NSString*)urlStr;
+(void)getDataCacheWithBlock:(NSString*)urlStr sender:(id)sender successBlock:(ASIUtilBlock)successBlock failedBlock:(ASIUtilBlock)failedBlock;

//post key value方式
//无缓存机制
+(NSString*)postDataStr:(NSString*)urlStr valueArr:(NSArray*)valueArr keyArr:(NSArray*)keyArr;
+(NSData*)postData:(NSString*)urlStr valueArr:(NSArray*)valueArr keyArr:(NSArray*)keyArr;
+(void)postDataWithBlock:(NSString*)urlStr valueArr:(NSArray*)valueArr keyArr:(NSArray*)keyArr sender:(id)sender successBlock:(ASIUtilBlock)successBlock failedBlock:(ASIUtilBlock)failedBlock;

//有缓存机制
+(NSString*)postDataStrCache:(NSString*)urlStr valueArr:(NSArray*)valueArr keyArr:(NSArray*)keyArr;
+(NSData*)postDataCache:(NSString*)urlStr valueArr:(NSArray*)valueArr keyArr:(NSArray*)keyArr;
+(void)postDataCacheWithBlock:(NSString*)urlStr valueArr:(NSArray*)valueArr keyArr:(NSArray*)keyArr sender:(id)sender successBlock:(ASIUtilBlock)successBlock failedBlock:(ASIUtilBlock)failedBlock;

//post body方式
//无缓存机制
+(NSString*)postBodyDataStr:(NSString*)urlStr bodyStr:(NSString*)bodyStr;
+(NSData*)postBodyData:(NSString*)urlStr bodyStr:(NSString*)bodyStr;
+(void)postBodyDataWithBlock:(NSString*)urlStr bodyStr:(NSString*)bodyStr sender:(id)sender successBlock:(ASIUtilBlock)successBlock failedBlock:(ASIUtilBlock)failedBlock;

//有缓存机制
+(NSString*)postBodyDataStrCache:(NSString*)urlStr bodyStr:(NSString*)bodyStr;
+(NSData*)postBodyDataCache:(NSString*)urlStr bodyStr:(NSString*)bodyStr;
+(void)postBodyDataCacheWithBlock:(NSString*)urlStr bodyStr:(NSString*)bodyStr sender:(id)sender successBlock:(ASIUtilBlock)successBlock failedBlock:(ASIUtilBlock)failedBlock;

@end
