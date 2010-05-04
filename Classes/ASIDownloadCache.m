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
static NSDateFormatter *rfc1123DateFormatter = nil;

@interface ASIDownloadCache ()
+ (NSString *)keyForRequest:(ASIHTTPRequest *)request;
@end

@implementation ASIDownloadCache

+ (void)initialize
{
	if (self == [ASIDownloadCache class]) {
		rfc1123DateFormatter = [[NSDateFormatter alloc] init];
		[rfc1123DateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease]];
		[rfc1123DateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
		[rfc1123DateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss 'GMT'"];
	}
}

- (id)init
{
	self = [super init];
	[self setShouldRespectCacheControlHeaders:YES];
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
	
	if ([self shouldRespectCacheControlHeaders] && ![[self class] serverAllowsResponseCachingForRequest:request]) {
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
	// We use this special key to help expire the request when we get a max-age header
	[responseHeaders setObject:[rfc1123DateFormatter stringFromDate:[NSDate date]] forKey:@"X-ASIHTTPRequest-Fetch-date"];
	[responseHeaders writeToFile:metadataPath atomically:NO];
	
	if ([request responseData]) {
		[[request responseData] writeToFile:dataPath atomically:NO];
	} else if ([request downloadDestinationPath]) {
		NSError *error = nil;
		[[NSFileManager defaultManager] copyItemAtPath:[request downloadDestinationPath] toPath:dataPath error:&error];
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
	// If the Etag or Last-Modified date are different from the one we have, fetch the document again
	NSArray *headersToCompare = [NSArray arrayWithObjects:@"Etag",@"Last-Modified",nil];
	for (NSString *header in headersToCompare) {
		if (![[[request responseHeaders] objectForKey:header] isEqualToString:[cachedHeaders objectForKey:header]]) {
			return NO;
		}
	}
	if (![self shouldRespectCacheControlHeaders]) {
		return YES;
	}
	// Look for an Expires header to see if the content is out of data
	NSString *expires = [cachedHeaders objectForKey:@"Expires"];
	if (expires) {
		if ([[ASIHTTPRequest dateFromRFC1123String:expires] timeIntervalSinceNow] < 0) {
			return NO;
		}
	}
	// Look for a max-age header
	NSString *cacheControl = [[cachedHeaders objectForKey:@"Cache-Control"] lowercaseString];
	if (cacheControl) {
		NSScanner *scanner = [NSScanner scannerWithString:cacheControl];
		if ([scanner scanString:@"max-age" intoString:NULL]) {
			[scanner scanString:@"=" intoString:NULL];
			NSTimeInterval maxAge = 0;
			[scanner scanDouble:&maxAge];
			NSDate *fetchDate = [ASIHTTPRequest dateFromRFC1123String:[cachedHeaders objectForKey:@"X-ASIHTTPRequest-Fetch-date"]];
			
#if (TARGET_OS_IPHONE && (!defined(__IPHONE_4_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_4_0)) || !defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6
			NSDate *expiryDate = [fetchDate addTimeInterval:maxAge];
#else
			NSDate *expiryDate = [fetchDate dateByAddingTimeInterval:maxAge];
#endif
			
			if ([expiryDate timeIntervalSinceNow] < 0) {
				return NO;
			}
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
	NSString *cacheControl = [[[request responseHeaders] objectForKey:@"Cache-Control"] lowercaseString];
	if (cacheControl) {
		if ([cacheControl isEqualToString:@"no-cache"] || [cacheControl isEqualToString:@"no-store"]) {
			return NO;
		}
	}
	NSString *pragma = [[[request responseHeaders] objectForKey:@"Pragma"] lowercaseString];
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


@synthesize storagePath;
@synthesize defaultCachePolicy;
@synthesize defaultCacheStoragePolicy;
@synthesize accessLock;
@synthesize shouldRespectCacheControlHeaders;
@end
