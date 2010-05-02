//
//  ASIDownloadCache.m
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 01/05/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//

#import "ASIDownloadCache.h"
#import "ASIHTTPRequest.h"
#import <CommonCrypto/CommonHMAC.h>

static ASIDownloadCache *sharedCache = nil;

static NSString *sessionCacheFolder = @"SessionStore";
static NSString *permanentCacheFolder = @"PermanentStore";

@interface ASIDownloadCache ()
+ (NSString *)keyForRequest:(ASIHTTPRequest *)request;
+ (NSString *)responseHeader:(NSString *)header fromHeaders:(NSDictionary *)headers;
@end

@implementation ASIDownloadCache

- (id)init
{
	self = [super init];
	[self setDefaultCachePolicy:ASIReloadIfDifferentCachePolicy];
	[self setDefaultCacheStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	[self setAccessLock:[[[NSRecursiveLock alloc] init] autorelease]];
	return self;
}

+ (id)sharedCache
{
	if (!sharedCache) {
		sharedCache = [[self alloc] init];
		[sharedCache setStoragePath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"ASIHTTPRequestCache"]];

	}
	return sharedCache;
}

- (void)dealloc
{
	[storagePath release];
	[accessLock release];
	[super dealloc];
}

- (void)setStoragePath:(NSString *)path
{
	[[self accessLock] lock];
	[self clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	[storagePath release];
	storagePath = [path retain];
	BOOL isDirectory = NO;
	NSArray *directories = [NSArray arrayWithObjects:path,[path stringByAppendingPathComponent:sessionCacheFolder],[path stringByAppendingPathComponent:permanentCacheFolder],nil];
	for (NSString *directory in directories) {
		BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDirectory];
		if (exists && !isDirectory) {
			[NSException raise:@"FileExistsAtCachePath" format:@"Cannot create a directory for the cache at '%@', because a file already exists",directory];
		} else if (!exists) {
			[[NSFileManager defaultManager] createDirectoryAtPath:directory attributes:nil];
			if (![[NSFileManager defaultManager] fileExistsAtPath:directory]) {
				[NSException raise:@"FailedToCreateCacheDirectory" format:@"Failed to create a directory for the cache at '%@'",directory];
			}
		}
	}
	[self clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	[[self accessLock] unlock];
}

- (void)storeResponseForRequest:(ASIHTTPRequest *)request
{
	[[self accessLock] lock];
	
	if ([request error] || ![request responseHeaders] || ([request responseStatusCode] != 200)) {
		[[self accessLock] unlock];
		return;
	}
	
	if ([self shouldRespectCacheHeaders] && ![[self class] serverAllowsResponseCachingForRequest:request]) {
		[[self accessLock] unlock];
		return;
	}
	
	// If the request is set to use the default policy, use this cache's default policy
	ASICachePolicy policy = [request cachePolicy];
	if (policy == ASIDefaultCachePolicy) {
		policy = [self defaultCachePolicy];
	}
	
	if (policy == ASIIgnoreCachePolicy) {
		[[self accessLock] unlock];
		return;
	}
	NSString *path = nil;
	if ([request cacheStoragePolicy] == ASICacheForSessionDurationCacheStoragePolicy) {
		path = [[self storagePath] stringByAppendingPathComponent:sessionCacheFolder];
	} else {
		path = [[self storagePath] stringByAppendingPathComponent:permanentCacheFolder];
	}
	path = [path stringByAppendingPathComponent:[[self class] keyForRequest:request]];
	NSString *metadataPath = [path stringByAppendingPathExtension:@"cachedheaders"];
	NSString *dataPath = [path stringByAppendingPathExtension:@"cacheddata"];
	
	NSMutableDictionary *responseHeaders = [NSMutableDictionary dictionaryWithDictionary:[request responseHeaders]];
	if ([request isResponseCompressed]) {
		[responseHeaders removeObjectForKey:@"Content-Encoding"];
	}
	[responseHeaders writeToFile:metadataPath atomically:NO];
	
	if ([request responseData]) {
		[[request responseData] writeToFile:dataPath atomically:NO];
	} else if ([request downloadDestinationPath]) {
		[[NSFileManager defaultManager] copyPath:[request downloadDestinationPath] toPath:dataPath handler:nil];
	}
	[[self accessLock] unlock];
	
}

- (NSDictionary *)cachedHeadersForRequest:(ASIHTTPRequest *)request
{
	if (![self storagePath]) {
		return nil;
	}
	// Look in the session store
	NSString *path = [[self storagePath] stringByAppendingPathComponent:sessionCacheFolder];
	NSString *dataPath = [path stringByAppendingPathComponent:[[[self class] keyForRequest:request] stringByAppendingPathExtension:@"cachedheaders"]];
	if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
		return [NSDictionary dictionaryWithContentsOfFile:dataPath];
	}
	// Look in the permanent store
	path = [[self storagePath] stringByAppendingPathComponent:permanentCacheFolder];
	dataPath = [path stringByAppendingPathComponent:[[[self class] keyForRequest:request] stringByAppendingPathExtension:@"cachedheaders"]];
	if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
		return [NSDictionary dictionaryWithContentsOfFile:dataPath];
	}
	return nil;
}
							  
- (NSData *)cachedResponseDataForRequest:(ASIHTTPRequest *)request
{
	NSString *path = [self pathToCachedResponseDataForRequest:request];
	if (path) {
		return [NSData dataWithContentsOfFile:path];
	}
	return nil;
}

- (NSString *)pathToCachedResponseDataForRequest:(ASIHTTPRequest *)request
{
	if (![self storagePath]) {
		return nil;
	}
	// Look in the session store
	NSString *path = [[self storagePath] stringByAppendingPathComponent:sessionCacheFolder];
	NSString *dataPath = [path stringByAppendingPathComponent:[[[self class] keyForRequest:request] stringByAppendingPathExtension:@"cacheddata"]];
	if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
		return dataPath;
	}
	// Look in the permanent store
	path = [[self storagePath] stringByAppendingPathComponent:permanentCacheFolder];
	dataPath = [path stringByAppendingPathComponent:[[[self class] keyForRequest:request] stringByAppendingPathExtension:@"cacheddata"]];
	if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
		return dataPath;
	}
	return nil;
}

- (BOOL)isCachedDataCurrentForRequest:(ASIHTTPRequest *)request
{
	if (![self storagePath]) {
		return NO;
	}
	NSDictionary *cachedHeaders = [self cachedHeadersForRequest:request];
	if (!cachedHeaders) {
		return NO;
	}
	NSString *dataPath = [self pathToCachedResponseDataForRequest:request];
	if (!dataPath) {
		return NO;
	}
	NSArray *headersToCompare = [NSArray arrayWithObjects:@"etag",@"last-modified",nil];
	for (NSString *header in headersToCompare) {
		if (![[[self class] responseHeader:header fromHeaders:[request responseHeaders]] isEqualToString:[[self class] responseHeader:header fromHeaders:cachedHeaders]]) {
			return NO;
		}
	}
	return YES;
}


- (void)setDefaultCachePolicy:(ASICachePolicy)cachePolicy
{
	[[self accessLock] lock];
	if (cachePolicy == ASIDefaultCachePolicy) {
		defaultCachePolicy = ASIReloadIfDifferentCachePolicy;
	}  else {
		defaultCachePolicy = cachePolicy;	
	}
	[[self accessLock] unlock];
}


- (void)setDefaultCacheStoragePolicy:(ASICacheStoragePolicy)storagePolicy
{
	[[self accessLock] lock];
	defaultCacheStoragePolicy = storagePolicy;
	[[self accessLock] unlock];
}


- (void)clearCachedResponsesForStoragePolicy:(ASICacheStoragePolicy)storagePolicy
{
	[[self accessLock] lock];
	if (![self storagePath]) {
		[[self accessLock] unlock];
		return;
	}
	NSString *path;
	if (storagePolicy == ASICacheForSessionDurationCacheStoragePolicy) {
		path = [[self storagePath] stringByAppendingPathComponent:sessionCacheFolder];
	} else if (storagePolicy == ASICachePermanentlyCacheStoragePolicy) {
		path = [[self storagePath] stringByAppendingPathComponent:permanentCacheFolder];
	}
	BOOL isDirectory = NO;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
	if (exists && !isDirectory || !exists) {
		return;
	}
	NSError *error = nil;
	NSArray *cacheFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
	if (error) {
		[NSException raise:@"FailedToTraverseCacheDirectory" format:@"Listing cache directory failed at path '%@'",path];	
	}
	for (NSString *file in cacheFiles) {
		NSString *extension = [file pathExtension];
		if ([extension isEqualToString:@"cacheddata"] || [extension isEqualToString:@"cachedheaders"]) {
			[[NSFileManager defaultManager] removeItemAtPath:[path stringByAppendingPathComponent:file] error:&error];
			if (error) {
				[NSException raise:@"FailedToRemoveCacheFile" format:@"Failed to remove cached data at path '%@'",path];	
			}
		}
	}
	[[self accessLock] unlock];
}

+ (BOOL)serverAllowsResponseCachingForRequest:(ASIHTTPRequest *)request
{
	NSString *cacheControl = [[[self class] responseHeader:@"cache-control" fromHeaders:[request responseHeaders]] lowercaseString];
	if (cacheControl) {
		if ([cacheControl isEqualToString:@"no-cache"] || [cacheControl isEqualToString:@"no-store"]) {
			return NO;
		}
	}
	NSString *pragma = [[[self class] responseHeader:@"pragma" fromHeaders:[request responseHeaders]] lowercaseString];
	if (pragma) {
		if ([pragma isEqualToString:@"no-cache"]) {
			return NO;
		}
	}
	return YES;
}

// Borrowed from: http://stackoverflow.com/questions/652300/using-md5-hash-on-a-string-in-cocoa
+ (NSString *)keyForRequest:(ASIHTTPRequest *)request
{
	const char *cStr = [[[request url] absoluteString] UTF8String];
	unsigned char result[16];
	CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
	return [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],result[8], result[9], result[10], result[11],result[12], result[13], result[14], result[15]]; 	
}

+ (NSString *)responseHeader:(NSString *)header fromHeaders:(NSDictionary *)headers
{
	for (NSString *responseHeader in headers) {
		if ([[responseHeader lowercaseString] isEqualToString:header]) {
			return [headers objectForKey:responseHeader];
		}
	}
	return nil;
}

@synthesize storagePath;
@synthesize defaultCachePolicy;
@synthesize defaultCacheStoragePolicy;
@synthesize accessLock;
@synthesize shouldRespectCacheHeaders;
@end
