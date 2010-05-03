//
//  ASIDownloadCache.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 01/05/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASICacheDelegate.h"

@interface ASIDownloadCache : NSObject <ASICacheDelegate> {
	ASICachePolicy defaultCachePolicy;
	ASICacheStoragePolicy defaultCacheStoragePolicy;
	NSString *storagePath;
	NSRecursiveLock *accessLock;
	BOOL shouldRespectCacheControlHeaders;
}
+ (id)sharedCache;
+ (BOOL)serverAllowsResponseCachingForRequest:(ASIHTTPRequest *)request;

@property (assign) ASICachePolicy defaultCachePolicy;
@property (assign) ASICacheStoragePolicy defaultCacheStoragePolicy;
@property (retain) NSString *storagePath;
@property (retain) NSRecursiveLock *accessLock;
@property (assign) BOOL shouldRespectCacheControlHeaders;
@end
