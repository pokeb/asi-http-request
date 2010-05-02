//
//  ASICacheDelegate.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 01/05/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ASIHTTPRequest;

typedef enum _ASICachePolicy {
	ASIDefaultCachePolicy = 0,
	ASIIgnoreCachePolicy = 1,
	ASIReloadIfDifferentCachePolicy = 2,
	ASIOnlyLoadIfNotCachedCachePolicy = 3,
	ASIUseCacheIfLoadFailsCachePolicy = 4
} ASICachePolicy;

typedef enum _ASICacheStoragePolicy {
	ASICacheForSessionDurationCacheStoragePolicy = 0,
	ASICachePermanentlyCacheStoragePolicy = 1
} ASICacheStoragePolicy;


@protocol ASICacheDelegate <NSObject>

@required
- (ASICachePolicy)defaultCachePolicy;
- (void)storeResponseForRequest:(ASIHTTPRequest *)request;
- (NSDictionary *)cachedHeadersForRequest:(ASIHTTPRequest *)request;
- (NSData *)cachedResponseDataForRequest:(ASIHTTPRequest *)request;
- (NSString *)pathToCachedResponseDataForRequest:(ASIHTTPRequest *)request;
- (void)clearCachedResponsesForStoragePolicy:(ASICacheStoragePolicy)cachePolicy;
@end
