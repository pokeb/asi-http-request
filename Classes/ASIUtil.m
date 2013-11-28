//
//  ASIUtil.m
//  CloudAtlas
//
//  Created by apple on 13-3-6.
//  Copyright (c) 2013年 apple. All rights reserved.
//

#import "ASIUtil.h"

@implementation ASIUtil

+ (ASIUtil *)sharedManager{
    static ASIUtil *sharedAccountManagerInstance = nil;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        sharedAccountManagerInstance = [[self alloc] init];
    });
    
    return sharedAccountManagerInstance;
}

-(void)destroyRequest{
    if (self!=nil) {
        for (ASIHTTPRequest *asi in _ASIHTTPRequestArray) {
            [asi clearDelegatesAndCancel];
        }
        [_ASIHTTPRequestArray removeAllObjects];
    }
}

-(void)dealloc{
    [_ASIHTTPRequestArray release];
    [super dealloc];
}

-(id)init{
    if (self=[super init]) {
        _ASIHTTPRequestArray=[[NSMutableArray alloc] init];
    }
    return self;
}

+(BOOL)isWifiConn{
    Reachability *reachability = [Reachability reachabilityForLocalWiFi];
    return [reachability isReachableViaWiFi];
}

+ (BOOL)isReachable
{
    Reachability *wifiReach = [Reachability reachabilityForLocalWiFi];
    Reachability *internetReach = [Reachability reachabilityForInternetConnection];
    return ([wifiReach isReachable] || [internetReach isReachable]);
}

+(NSString*)getDataStr:(NSString*)urlStr{
    NSURL *url = [NSURL URLWithString:urlStr];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [[self sharedManager].ASIHTTPRequestArray addObject:request];
    [request setValidatesSecureCertificate:NO];
    [request startSynchronous];
    NSError *error = [request error];
    if (!error) {
        return [request responseString];
    }
    return nil;
}


+(NSData*)getData:(NSString*)urlStr{
    
    NSURL *url = [NSURL URLWithString:urlStr];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [[self sharedManager].ASIHTTPRequestArray addObject:request];
    [request setValidatesSecureCertificate:NO];
    [request startSynchronous];
    NSError *error = [request error];
    if (!error) {
        return [request responseData];
    }
    return nil;
}

+(void)getDataWithBlock:(NSString*)urlStr sender:(id)sender successBlock:(ASIUtilBlock)successBlock failedBlock:(ASIUtilBlock)failedBlock{
    NSURL *url = [NSURL URLWithString:urlStr];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [[self sharedManager].ASIHTTPRequestArray addObject:request];
    [request setValidatesSecureCertificate:NO];
    [request setCompletionBlock:^{
        successBlock(request);
    }];
    [request setFailedBlock:^{
        failedBlock(request);
    }];
    [request startAsynchronous];
}

+(NSString*)getDataStrCache:(NSString*)urlStr{
    NSURL *url = [NSURL URLWithString:urlStr];
    [ASIHTTPRequest setDefaultCache:[ASIDownloadCache sharedCache]];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [[self sharedManager].ASIHTTPRequestArray addObject:request];
    [request setValidatesSecureCertificate:NO];
    [request setDownloadCache:[ASIDownloadCache sharedCache]];
    //[request setSecondsToCache:60*60*24*7];
    [request setCachePolicy:ASIAskServerIfModifiedCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy];
    [request startSynchronous];
    NSError *error = [request error];
    if (!error) {
        return [request responseString];
    }
    return nil;
}

+(NSData*)getDataCache:(NSString*)urlStr{
    NSURL *url = [NSURL URLWithString:urlStr];
    [ASIHTTPRequest setDefaultCache:[ASIDownloadCache sharedCache]];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [[self sharedManager].ASIHTTPRequestArray addObject:request];
    [request setValidatesSecureCertificate:NO];
    [request setDownloadCache:[ASIDownloadCache sharedCache]];
    //[request setSecondsToCache:60*60*24*7];
    [request setCachePolicy:ASIAskServerIfModifiedWhenStaleCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy];
    [request startSynchronous];
    NSError *error = [request error];
    if (!error) {
        return [request responseData];
    }
    return nil;
}

+(void)getDataCacheWithBlock:(NSString*)urlStr sender:(id)sender successBlock:(ASIUtilBlock)successBlock failedBlock:(ASIUtilBlock)failedBlock{
    NSURL *url = [NSURL URLWithString:urlStr];
    [ASIHTTPRequest setDefaultCache:[ASIDownloadCache sharedCache]];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [[self sharedManager].ASIHTTPRequestArray addObject:request];
    [request setValidatesSecureCertificate:NO];
    [request setDownloadCache:[ASIDownloadCache sharedCache]];
    //[request setSecondsToCache:60*60*24*7];
    [request setCachePolicy:ASIAskServerIfModifiedWhenStaleCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy];
    [request setCompletionBlock:^{
        successBlock(request);
    }];
    [request setFailedBlock:^{
        failedBlock(request);
    }];
    [request startAsynchronous];
}

+(NSString*)postDataStr:(NSString*)urlStr valueArr:(NSArray*)valueArr keyArr:(NSArray*)keyArr{
    if ([valueArr count]!=[keyArr count]) {
        return nil;
    }
    NSURL *url = [NSURL URLWithString:urlStr];
    ASIFormDataRequest* request = [ASIFormDataRequest requestWithURL:url];
    [[self sharedManager].ASIHTTPRequestArray addObject:request];
    [request setValidatesSecureCertificate:NO];
    for (int i=0; i<[valueArr count]; i++) {
        if ([[valueArr objectAtIndex:i] class]==[NSData class]) {
            [request setData:[valueArr objectAtIndex:i] forKey:[keyArr objectAtIndex:i]];
        }
        else if([[valueArr objectAtIndex:i] isKindOfClass:[NSURL class]]){
            [request setFile:[NSString stringWithFormat:@"%@",[valueArr objectAtIndex:i]] forKey:[keyArr objectAtIndex:i]];
        }
        else{
            [request setPostValue:[valueArr objectAtIndex:i] forKey:[keyArr objectAtIndex:i]];
        }
    }
    [request startSynchronous];
    NSError *error = [request error];
    if (!error) {
        return [request responseString];
    }
    return nil;
}

+(NSData*)postData:(NSString*)urlStr valueArr:(NSArray*)valueArr keyArr:(NSArray*)keyArr{
    NSURL *url = [NSURL URLWithString:urlStr];
    ASIFormDataRequest* request = [ASIFormDataRequest requestWithURL:url];
    [[self sharedManager].ASIHTTPRequestArray addObject:request];
    [request setValidatesSecureCertificate:NO];
    for (int i=0; i<[valueArr count]; i++) {
        if ([[valueArr objectAtIndex:i] isKindOfClass:[NSData class]]) {
            [request setData:[valueArr objectAtIndex:i] forKey:[keyArr objectAtIndex:i]];
        }
        else if([[valueArr objectAtIndex:i] isKindOfClass:[NSURL class]]){
            [request setFile:[NSString stringWithFormat:@"%@",[valueArr objectAtIndex:i]] forKey:[keyArr objectAtIndex:i]];
        }
        else{
            [request setPostValue:[valueArr objectAtIndex:i] forKey:[keyArr objectAtIndex:i]];
        }
    }
    [request startSynchronous];
    NSError *error = [request error];
    if (!error) {
        return [request responseData];
    }
    return nil;
}

+(void)postDataWithBlock:(NSString*)urlStr valueArr:(NSArray*)valueArr keyArr:(NSArray*)keyArr sender:(id)sender successBlock:(ASIUtilBlock)successBlock failedBlock:(ASIUtilBlock)failedBlock{
    NSURL *url = [NSURL URLWithString:urlStr];
    ASIFormDataRequest* request = [ASIFormDataRequest requestWithURL:url];
    [[self sharedManager].ASIHTTPRequestArray addObject:request];
    [request setValidatesSecureCertificate:NO];
    for (int i=0; i<[valueArr count]; i++) {
        if ([[valueArr objectAtIndex:i] isKindOfClass:[NSData class]]) {
            [request setData:[valueArr objectAtIndex:i] forKey:[keyArr objectAtIndex:i]];
        }
        else if([[valueArr objectAtIndex:i] isKindOfClass:[NSURL class]]){
            [request setFile:[NSString stringWithFormat:@"%@",[valueArr objectAtIndex:i]] forKey:[keyArr objectAtIndex:i]];
        }
        else{
            [request setPostValue:[valueArr objectAtIndex:i] forKey:[keyArr objectAtIndex:i]];
        }
    }
    [request setCompletionBlock:^{
        successBlock(request);
    }];
    [request setFailedBlock:^{
        failedBlock(request);
    }];
    [request startAsynchronous];
}

+(NSString*)postDataStrCache:(NSString*)urlStr valueArr:(NSArray*)valueArr keyArr:(NSArray*)keyArr{
    NSURL *url = [NSURL URLWithString:urlStr];
    [ASIHTTPRequest setDefaultCache:[ASIDownloadCache sharedCache]];
    ASIFormDataRequest* request = [ASIFormDataRequest requestWithURL:url];
    [[self sharedManager].ASIHTTPRequestArray addObject:request];
    [request setValidatesSecureCertificate:NO];
    for (int i=0; i<[valueArr count]; i++) {
        if ([[valueArr objectAtIndex:i] class]==[NSData class]) {
            [request setData:[valueArr objectAtIndex:i] forKey:[keyArr objectAtIndex:i]];
        }
        else if([[valueArr objectAtIndex:i] isKindOfClass:[NSURL class]]){
            [request setFile:[NSString stringWithFormat:@"%@",[valueArr objectAtIndex:i]] forKey:[keyArr objectAtIndex:i]];
        }
        else{
            [request setPostValue:[valueArr objectAtIndex:i] forKey:[keyArr objectAtIndex:i]];
        }
    }
    [request setDownloadCache:[ASIDownloadCache sharedCache]];
    [request setCachePolicy:ASIAskServerIfModifiedCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy];
    [request startSynchronous];
    NSError *error = [request error];
    if (!error) {
        return [request responseString];
    }
    return nil;
}

+(NSData*)postDataCache:(NSString*)urlStr valueArr:(NSArray*)valueArr keyArr:(NSArray*)keyArr{
    NSURL *url = [NSURL URLWithString:urlStr];
    [ASIHTTPRequest setDefaultCache:[ASIDownloadCache sharedCache]];
    ASIFormDataRequest* request = [ASIFormDataRequest requestWithURL:url];
    [[self sharedManager].ASIHTTPRequestArray addObject:request];
    [request setValidatesSecureCertificate:NO];
    for (int i=0; i<[valueArr count]; i++) {
        if ([[valueArr objectAtIndex:i] class]==[NSData class]) {
            [request setData:[valueArr objectAtIndex:i] forKey:[keyArr objectAtIndex:i]];
        }
        else if([[valueArr objectAtIndex:i] isKindOfClass:[NSURL class]]){
            [request setFile:[NSString stringWithFormat:@"%@",[valueArr objectAtIndex:i]] forKey:[keyArr objectAtIndex:i]];
        }
        else{
            [request setPostValue:[valueArr objectAtIndex:i] forKey:[keyArr objectAtIndex:i]];
        }
    }
    [request setDownloadCache:[ASIDownloadCache sharedCache]];
    [request setCachePolicy:ASIAskServerIfModifiedWhenStaleCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy];
    [request startSynchronous];
    NSError *error = [request error];
    if (!error) {
        return [request responseData];
    }
    return nil;
}

+(void)postDataCacheWithBlock:(NSString*)urlStr valueArr:(NSArray*)valueArr keyArr:(NSArray*)keyArr sender:(id)sender successBlock:(ASIUtilBlock)successBlock failedBlock:(ASIUtilBlock)failedBlock{
    NSURL *url = [NSURL URLWithString:urlStr];
    [ASIHTTPRequest setDefaultCache:[ASIDownloadCache sharedCache]];
    ASIFormDataRequest* request = [ASIFormDataRequest requestWithURL:url];
    [[self sharedManager].ASIHTTPRequestArray addObject:request];
    [request setValidatesSecureCertificate:NO];
    for (int i=0; i<[valueArr count]; i++) {
        if ([[valueArr objectAtIndex:i] class]==[NSData class]) {
            [request setData:[valueArr objectAtIndex:i] forKey:[keyArr objectAtIndex:i]];
        }
        else if([[valueArr objectAtIndex:i] isKindOfClass:[NSURL class]]){
            [request setFile:[NSString stringWithFormat:@"%@",[valueArr objectAtIndex:i]] forKey:[keyArr objectAtIndex:i]];
        }
        else{
            [request setPostValue:[valueArr objectAtIndex:i] forKey:[keyArr objectAtIndex:i]];
        }
    }
    [request setDownloadCache:[ASIDownloadCache sharedCache]];
    [request setCachePolicy:ASIAskServerIfModifiedWhenStaleCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy];
    [request setCompletionBlock:^{
        successBlock(request);
    }];
    [request setFailedBlock:^{
        failedBlock(request);
    }];
    [request startAsynchronous];

}

+(NSString*)postBodyDataStr:(NSString*)urlStr bodyStr:(NSString*)bodyStr{
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlStr]];
    [[self sharedManager].ASIHTTPRequestArray addObject:request];
    [request setValidatesSecureCertificate:NO];
    [request appendPostData:[bodyStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]];
    [request setRequestMethod:@"POST"];
    [request startSynchronous];
    NSError *error = [request error];
    if (!error) {
        return [request responseString];
    }
    return nil;
}
+(NSData*)postBodyData:(NSString*)urlStr bodyStr:(NSString*)bodyStr{
    if (![self isReachable]) {
        @throw [NSException exceptionWithName:[xgt_Error getErrorStr:@"10001"] reason:@"10001" userInfo:nil];
    }
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlStr]];
    [[self sharedManager].ASIHTTPRequestArray addObject:request];
    [request setValidatesSecureCertificate:NO];
    [request appendPostData:[bodyStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]];
    [request setRequestMethod:@"POST"];
    [request startSynchronous];
    
    NSError *error = [request error];
    if (!error) {
        return [request responseData];
    }
    return nil;
    
}

+(void)postBodyDataWithBlock:(NSString*)urlStr bodyStr:(NSString*)bodyStr sender:(id)sender successBlock:(ASIUtilBlock)successBlock failedBlock:(ASIUtilBlock)failedBlock{
    if (![self isReachable]) {
        @throw [NSException exceptionWithName:[xgt_Error getErrorStr:@"10001"] reason:@"10001" userInfo:nil];
    }
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlStr]];
    [[self sharedManager].ASIHTTPRequestArray addObject:request];
    [request setValidatesSecureCertificate:NO];
    [request appendPostData:[bodyStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]];
    [request setRequestMethod:@"POST"];
    [request setCompletionBlock:^{
        successBlock(request);
    }];
    [request setFailedBlock:^{
        failedBlock(request);
    }];
    [request startAsynchronous];
}

+(NSString*)postBodyDataStrCache:(NSString*)urlStr bodyStr:(NSString*)bodyStr{
    [ASIHTTPRequest setDefaultCache:[ASIDownloadCache sharedCache]];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlStr]];
    [[self sharedManager].ASIHTTPRequestArray addObject:request];
    [request setValidatesSecureCertificate:NO];
    [request setDownloadCache:[ASIDownloadCache sharedCache]];
    [request setCachePolicy:ASIAskServerIfModifiedWhenStaleCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy];
    [request appendPostData:[bodyStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]];
    [request setRequestMethod:@"POST"];
    [request startSynchronous];
    
    NSError *error = [request error];
    if (!error) {
        return [request responseString];
    }
    return nil;
}
+(NSData*)postBodyDataCache:(NSString*)urlStr bodyStr:(NSString*)bodyStr{
    if (![self isReachable]) {
        @throw [NSException exceptionWithName:[xgt_Error getErrorStr:@"10001"] reason:@"10001" userInfo:nil];
    }
    
    [ASIHTTPRequest setDefaultCache:[ASIDownloadCache sharedCache]];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlStr]];
    [[self sharedManager].ASIHTTPRequestArray addObject:request];
    [request setValidatesSecureCertificate:NO];
    [request setDownloadCache:[ASIDownloadCache sharedCache]];
    [request setCachePolicy:ASIAskServerIfModifiedWhenStaleCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy];
    [request appendPostData:[bodyStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]];
    [request setRequestMethod:@"POST"];
    [request startSynchronous];
    
    NSError *error = [request error];
    if (!error) {
        return [request responseData];
    }
    return nil;
}

+(void)postBodyDataCacheWithBlock:(NSString*)urlStr bodyStr:(NSString*)bodyStr sender:(id)sender successBlock:(ASIUtilBlock)successBlock failedBlock:(ASIUtilBlock)failedBlock{
    if (![self isReachable]) {
        @throw [NSException exceptionWithName:[xgt_Error getErrorStr:@"10001"] reason:@"10001" userInfo:nil];
    }
    
    [ASIHTTPRequest setDefaultCache:[ASIDownloadCache sharedCache]];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlStr]];
    [[self sharedManager].ASIHTTPRequestArray addObject:request];
    [request setValidatesSecureCertificate:NO];
    [request setDownloadCache:[ASIDownloadCache sharedCache]];
    [request setCachePolicy:ASIAskServerIfModifiedWhenStaleCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy];
    [request appendPostData:[bodyStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]];
    [request setRequestMethod:@"POST"];
    [request setCompletionBlock:^{
        successBlock(request);
    }];
    [request setFailedBlock:^{
        failedBlock(request);
    }];
    [request startAsynchronous];
}

@end
