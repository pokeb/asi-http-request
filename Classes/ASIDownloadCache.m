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
+ (NSString *)keyForURL:(NSURL *)url;
@end

@implementation ASIDownloadCache



#pragma mark Singleton

+ (ASIDownloadCache*) sharedCache{
    return sharedCache;
}


//called by atexit on exit, to ensure all resources are freed properly (not just memory)  
static void singleton_remover()
{
    //free resources here
}

// see initialize in docs:
//http://developer.apple.com/library/mac/#DOCUMENTATION/Cocoa/Reference/Foundation/Classes/NSObject_Class/Reference/Reference.html
+ (void)initialize {
    if (self == [ASIDownloadCache class]) {
        //initialization
        sharedCache = [[super allocWithZone:NULL] init];        
        [sharedCache setStoragePath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"ASIHTTPRequestCache"]];
        //atexit( singleton_remover );    
    }
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedCache];   
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;    
}

- (id)retain
{
    return self;    
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released  
}

- (void)release
{
    //do nothing    
}

- (id)autorelease
{
    return self;    
}

#pragma mark -

- (id)init
{
	self = [super init];
	[self setShouldRespectCacheControlHeaders:YES];
	[self setDefaultCachePolicy:ASIUseDefaultCachePolicy];
	[self setAccessLock:[[[NSRecursiveLock alloc] init] autorelease]];
	return self;
}

- (void)dealloc
{
	[storagePath release];
	[accessLock release];
	[super dealloc];
}

- (NSString *)storagePath
{
    @try {
        
        [[self accessLock] lock];
        return [[storagePath retain] autorelease];        
    }        
    @finally {
       	[[self accessLock] unlock]; 
    }

}


- (void)setStoragePath:(NSString *)path
{
    @try {
        
        [[self accessLock] lock];
        [self clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
        [storagePath release];
        storagePath = [path retain];
        
        NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
        
        BOOL isDirectory = NO;
        NSArray *directories = [NSArray arrayWithObjects:path,[path stringByAppendingPathComponent:sessionCacheFolder],[path stringByAppendingPathComponent:permanentCacheFolder],nil];
        for (NSString *directory in directories) {
            BOOL exists = [fileManager fileExistsAtPath:directory isDirectory:&isDirectory];
            if (exists && !isDirectory) {
                [NSException raise:@"FileExistsAtCachePath" format:@"Cannot create a directory for the cache at '%@', because a file already exists",directory];
            } else if (!exists) {
                [fileManager createDirectoryAtPath:directory withIntermediateDirectories:NO attributes:nil error:nil];
                if (![fileManager fileExistsAtPath:directory]) {
                    [NSException raise:@"FailedToCreateCacheDirectory" format:@"Failed to create a directory for the cache at '%@'",directory];
                }
            }
        }
        [self clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];      
        
    }        
    @finally {
       	[[self accessLock] unlock]; 
    }
}

- (void)storeResponseForRequest:(ASIHTTPRequest *)request maxAge:(NSTimeInterval)maxAge
{
    
    @try {
        [[self accessLock] lock];
        
        if ([request error] || ![request responseHeaders] || ([request responseStatusCode] != 200) || ([request cachePolicy] & ASIDoNotWriteToCacheCachePolicy)) {
            return;
        }
        
        if ([self shouldRespectCacheControlHeaders] && ![[self class] serverAllowsResponseCachingForRequest:request]) {
            return;
        }
        
        NSString *headerPath = [self pathToStoreCachedResponseHeadersForRequest:request];
        NSString *dataPath = [self pathToStoreCachedResponseDataForRequest:request];
        
        NSMutableDictionary *responseHeaders = [NSMutableDictionary dictionaryWithDictionary:[request responseHeaders]];
        if ([request isResponseCompressed]) {
            [responseHeaders removeObjectForKey:@"Content-Encoding"];
        }
        if (maxAge != 0) {
            [responseHeaders removeObjectForKey:@"Expires"];
            [responseHeaders setObject:[NSString stringWithFormat:@"max-age=%i",(int)maxAge] forKey:@"Cache-Control"];
        }
        // We use this special key to help expire the request when we get a max-age header
        [responseHeaders setObject:[[[self class] rfc1123DateFormatter] stringFromDate:[NSDate date]] forKey:@"X-ASIHTTPRequest-Fetch-date"];
        [responseHeaders writeToFile:headerPath atomically:NO];
        
        if ([request responseData]) {
            [[request responseData] writeToFile:dataPath atomically:NO];
        } else if ([request downloadDestinationPath] && ![[request downloadDestinationPath] isEqualToString:dataPath]) {
            NSError *error = nil;
            [[[[NSFileManager alloc] init] autorelease] copyItemAtPath:[request downloadDestinationPath] toPath:dataPath error:&error];
        }
        
    }        
    @finally {
       	[[self accessLock] unlock]; 
    }

}

- (NSDictionary *)cachedResponseHeadersForURL:(NSURL *)url
{
	NSString *path = [self pathToCachedResponseHeadersForURL:url];
	if (path) {
		return [NSDictionary dictionaryWithContentsOfFile:path];
	}
	return nil;
}

- (NSData *)cachedResponseDataForURL:(NSURL *)url
{
	NSString *path = [self pathToCachedResponseDataForURL:url];
	if (path) {
		return [NSData dataWithContentsOfFile:path];
	}
	return nil;
}

- (NSString *)pathToCachedResponseDataForURL:(NSURL *)url
{
    @try {
        
        [[self accessLock] lock];
        if (![self storagePath]) {
            return nil;
        }
        // Grab the file extension, if there is one. We do this so we can save the cached response with the same file extension - this is important if you want to display locally cached data in a web view 
        NSString *extension = [[url path] pathExtension];
        if (![extension length]) {
            extension = @"html";
        }
        
        NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
        
        // Look in the session store
        NSString *path = [[self storagePath] stringByAppendingPathComponent:sessionCacheFolder];
        NSString *dataPath = [path stringByAppendingPathComponent:[[[self class] keyForURL:url] stringByAppendingPathExtension:extension]];
        if ([fileManager fileExistsAtPath:dataPath]) {
            return dataPath;
        }
        // Look in the permanent store
        path = [[self storagePath] stringByAppendingPathComponent:permanentCacheFolder];
        dataPath = [path stringByAppendingPathComponent:[[[self class] keyForURL:url] stringByAppendingPathExtension:extension]];
        if ([fileManager fileExistsAtPath:dataPath]) {
            return dataPath;
        }
        return nil;
  
        
    }        
    @finally {
       	[[self accessLock] unlock]; 
    }
    
    
  }

- (NSString *)pathToCachedResponseHeadersForURL:(NSURL *)url
{
    
    @try {
        [[self accessLock] lock];
        if (![self storagePath]) {
            return nil;
        }
        
        NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
        
        // Look in the session store
        NSString *path = [[self storagePath] stringByAppendingPathComponent:sessionCacheFolder];
        NSString *dataPath = [path stringByAppendingPathComponent:[[[self class] keyForURL:url] stringByAppendingPathExtension:@"cachedheaders"]];
        if ([fileManager fileExistsAtPath:dataPath]) {
            return dataPath;
        }
        // Look in the permanent store
        path = [[self storagePath] stringByAppendingPathComponent:permanentCacheFolder];
        dataPath = [path stringByAppendingPathComponent:[[[self class] keyForURL:url] stringByAppendingPathExtension:@"cachedheaders"]];
        if ([fileManager fileExistsAtPath:dataPath]) {
            return dataPath;
        }
        return nil;  
                
    }        
    @finally {
       	[[self accessLock] unlock]; 
    }
    
}

- (NSString *)pathToStoreCachedResponseDataForRequest:(ASIHTTPRequest *)request
{
    
    @try {
        
        [[self accessLock] lock];
        if (![self storagePath]) {
            return nil;
        }
        
        NSString *path = [[self storagePath] stringByAppendingPathComponent:([request cacheStoragePolicy] == ASICacheForSessionDurationCacheStoragePolicy ? sessionCacheFolder : permanentCacheFolder)];
        
        // Grab the file extension, if there is one. We do this so we can save the cached response with the same file extension - this is important if you want to display locally cached data in a web view 
        NSString *extension = [[[request url] path] pathExtension];
        if (![extension length]) {
            extension = @"html";
        }
        path =  [path stringByAppendingPathComponent:[[[self class] keyForURL:[request url]] stringByAppendingPathExtension:extension]];
        return path;
     
        
    }        
    @finally {
       	[[self accessLock] unlock]; 
    }
    
    
}

- (NSString *)pathToStoreCachedResponseHeadersForRequest:(ASIHTTPRequest *)request
{
    
    @try {
        [[self accessLock] lock];
        if (![self storagePath]) {
            return nil;
        }
        NSString *path = [[self storagePath] stringByAppendingPathComponent:([request cacheStoragePolicy] == ASICacheForSessionDurationCacheStoragePolicy ? sessionCacheFolder : permanentCacheFolder)];
        path =  [path stringByAppendingPathComponent:[[[self class] keyForURL:[request url]] stringByAppendingPathExtension:@"cachedheaders"]];
        return path;
    }

    @finally {
        
        [[self accessLock] unlock];  
    }
}


- (void)removeCachedDataForRequest:(ASIHTTPRequest *)request
{
    @try {
        
        [[self accessLock] lock];
        if (![self storagePath]) {
            return;
        }
        
        NSString *cachedHeadersPath = [self pathToCachedResponseHeadersForURL:[request url]];
        if (!cachedHeadersPath) {
            return;
        }
        NSString *dataPath = [self pathToCachedResponseDataForURL:[request url]];
        if (!dataPath) {
            return;
        }
        
        NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
        [fileManager removeItemAtPath:cachedHeadersPath error:NULL];
        [fileManager removeItemAtPath:dataPath error:NULL];        
        
    }        
    @finally {
       	[[self accessLock] unlock]; 
    }
    
}

- (BOOL)isCachedDataCurrentForRequest:(ASIHTTPRequest *)request
{
    
    @try {
        [[self accessLock] lock];
        if (![self storagePath]) {
            return NO;
        }
        NSDictionary *cachedHeaders = [self cachedResponseHeadersForURL:[request url]];
        if (!cachedHeaders) {
            return NO;
        }
        NSString *dataPath = [self pathToCachedResponseDataForURL:[request url]];
        if (!dataPath) {
            return NO;
        }
        
        // If we already have response headers for this request, check to see if the new content is different
        if ([request responseHeaders]) {
            
            // New content is not different
            if ([request responseStatusCode] == 304) {
                return YES;
            }
            
            // If the Etag or Last-Modified date are different from the one we have, we'll have to fetch this resource again
            NSArray *headersToCompare = [NSArray arrayWithObjects:@"Etag",@"Last-Modified",nil];
            for (NSString *header in headersToCompare) {
                if (![[[request responseHeaders] objectForKey:header] isEqualToString:[cachedHeaders objectForKey:header]]) {
                    return NO;
                }
            }
        }
        
        if ([self shouldRespectCacheControlHeaders]) {
            
            // Look for a max-age header
            NSString *cacheControl = [[cachedHeaders objectForKey:@"Cache-Control"] lowercaseString];
            if (cacheControl) {
                NSScanner *scanner = [NSScanner scannerWithString:cacheControl];
                [scanner scanUpToString:@"max-age" intoString:NULL];
                if ([scanner scanString:@"max-age" intoString:NULL]) {
                    [scanner scanString:@"=" intoString:NULL];
                    NSTimeInterval maxAge = 0;
                    [scanner scanDouble:&maxAge];
                    
                    NSDate *fetchDate = [ASIHTTPRequest dateFromRFC1123String:[cachedHeaders objectForKey:@"X-ASIHTTPRequest-Fetch-date"]];
                    NSDate *expiryDate = [[[NSDate alloc] initWithTimeInterval:maxAge sinceDate:fetchDate] autorelease];
                    
                    if ([expiryDate timeIntervalSinceNow] >= 0) {
                        return YES;
                    }
                    // RFC 2612 says max-age must override any Expires header
                    return NO;
                }
            }
            
            // Look for an Expires header to see if the content is out of date
            NSString *expires = [cachedHeaders objectForKey:@"Expires"];
            if (expires) {
                if ([[ASIHTTPRequest dateFromRFC1123String:expires] timeIntervalSinceNow] >= 0) {
                    return YES;
                }
            }
            
            // No explicit expiration time sent by the server
            return NO;
        }

        return YES;
                
    }        
    @finally {
       	[[self accessLock] unlock]; 
    }

}

- (ASICachePolicy)defaultCachePolicy
{
    @try {
        
        [[self accessLock] lock];
        return defaultCachePolicy;
         
    }        
    @finally {
       	[[self accessLock] unlock]; 
    }
    
    
}


- (void)setDefaultCachePolicy:(ASICachePolicy)cachePolicy
{
    @try {
        
        [[self accessLock] lock];
        if (!cachePolicy) {
            defaultCachePolicy = ASIAskServerIfModifiedWhenStaleCachePolicy;
        }  else {
            defaultCachePolicy = cachePolicy;	
        }
        
    }        
    @finally {
       	[[self accessLock] unlock]; 
    }
    
    
    
	
}

- (void)clearCachedResponsesForStoragePolicy:(ASICacheStoragePolicy)storagePolicy
{
    @try {
        [[self accessLock] lock];
        if (![self storagePath]) {
            return;
        }
        NSString *path = [[self storagePath] stringByAppendingPathComponent:(storagePolicy == ASICacheForSessionDurationCacheStoragePolicy ? sessionCacheFolder : permanentCacheFolder)];
        
        NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
        
        BOOL isDirectory = NO;
        BOOL exists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
        if (!exists || !isDirectory) {
            return;
        }
        NSError *error = nil;
        NSArray *cacheFiles = [fileManager contentsOfDirectoryAtPath:path error:&error];
        if (error) {
            [NSException raise:@"FailedToTraverseCacheDirectory" format:@"Listing cache directory failed at path '%@'",path];	
        }
        for (NSString *file in cacheFiles) {
            [fileManager removeItemAtPath:[path stringByAppendingPathComponent:file] error:&error];
            if (error) {
                [NSException raise:@"FailedToRemoveCacheFile" format:@"Failed to remove cached data at path '%@'",path];
            }
        }      
        
    }        
    @finally {
       	[[self accessLock] unlock]; 
    }
  
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
+ (NSString *)keyForURL:(NSURL *)url
{
	NSString *urlString = [url absoluteString];
	// Strip trailing slashes so http://allseeing-i.com/ASIHTTPRequest/ is cached the same as http://allseeing-i.com/ASIHTTPRequest
	if ([[urlString substringFromIndex:[urlString length]-1] isEqualToString:@"/"]) {
		urlString = [urlString substringToIndex:[urlString length]-1];
	}
	const char *cStr = [urlString UTF8String];
	unsigned char result[16];
	CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
	return [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],result[8], result[9], result[10], result[11],result[12], result[13], result[14], result[15]]; 	
}

+ (NSDateFormatter *)rfc1123DateFormatter
{
	NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
	NSDateFormatter *dateFormatter = [threadDict objectForKey:@"ASIDownloadCacheDateFormatter"];
	if (dateFormatter == nil) {
		dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease]];
		[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		[dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss 'GMT'"];
		[threadDict setObject:dateFormatter forKey:@"ASIDownloadCacheDateFormatter"];
	}
	return dateFormatter;
}


- (BOOL)canUseCachedDataForRequest:(ASIHTTPRequest *)request
{
	// Ensure the request is allowed to read from the cache
	if ([request cachePolicy] & ASIDoNotReadFromCacheCachePolicy) {
		return NO;

	// If we don't want to load the request whatever happens, always pretend we have cached data even if we don't
	} else if ([request cachePolicy] & ASIDontLoadCachePolicy) {
		return YES;
	}

	NSDictionary *headers = [self cachedResponseHeadersForURL:[request url]];
	if (!headers) {
		return NO;
	}
	NSString *dataPath = [self pathToCachedResponseDataForURL:[request url]];
	if (!dataPath) {
		return NO;
	}

	// If we get here, we have cached data

	// If we have cached data, we can use it
	if ([request cachePolicy] & ASIOnlyLoadIfNotCachedCachePolicy) {
		return YES;

	// If we want to fallback to the cache after an error
	} else if ([request complete] && [request cachePolicy] & ASIFallbackToCacheIfLoadFailsCachePolicy) {
		return YES;

	// If we have cached data that is current, we can use it
	} else if ([request cachePolicy] & ASIAskServerIfModifiedWhenStaleCachePolicy) {
		if ([self isCachedDataCurrentForRequest:request]) {
			return YES;
		}

	// If we've got headers from a conditional GET and the cached data is still current, we can use it
	} else if ([request cachePolicy] & ASIAskServerIfModifiedCachePolicy) {
		if (![request responseHeaders]) {
			return NO;
		} else if ([self isCachedDataCurrentForRequest:request]) {
			return YES;
		}
	}
	return NO;
}

@synthesize storagePath;
@synthesize defaultCachePolicy;
@synthesize accessLock;
@synthesize shouldRespectCacheControlHeaders;
@end
