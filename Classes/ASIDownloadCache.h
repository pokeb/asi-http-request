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
	NSLock *accessLock;
	BOOL shouldRespectCacheHeaders;
}
+ (id)sharedCache;
+ (BOOL)serverAllowsResponseCachingForRequest:(ASIHTTPRequest *)request;

@property (assign) ASICachePolicy defaultCachePolicy;
@property (assign) ASICacheStoragePolicy defaultCacheStoragePolicy;
@property (retain) NSString *storagePath;
@property (retain) NSLock *accessLock;
@property (assign) BOOL shouldRespectCacheHeaders;
@end
