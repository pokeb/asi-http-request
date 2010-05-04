//
//  ASIDownloadCacheTests.m
//  Part of ASIHTTPRequest -> http://asi/ASIHTTPRequest
//
//  Created by Ben Copsey on 03/05/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//

#import "ASIDownloadCacheTests.h"
#import "ASIDownloadCache.h"
#import "ASIHTTPRequest.h"

@implementation ASIDownloadCacheTests

- (void)testDownloadCache
{
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
	[[ASIDownloadCache sharedCache] setDefaultCachePolicy:ASIReloadIfDifferentCachePolicy];
	
	// Ensure a request without a download cache does not pull from the cache
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/cache-away"]];
	[request startSynchronous];
	BOOL success = ![request didUseCachedResponse];
	GHAssertTrue(success,@"Used cached response when we shouldn't have");
	
	// Check a request isn't setting didUseCachedResponse when the data is not in the cache
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/cache-away"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request startSynchronous];
	success = ![request didUseCachedResponse];
	GHAssertTrue(success,@"Cached response should not have been available");	
	
	// Ensure the cache works
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/cache-away"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request startSynchronous];
	success = [request didUseCachedResponse];
	GHAssertTrue(success,@"Failed to use cached response");
	
	// Test respecting etag
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/content-always-new"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request startSynchronous];
	success = ![request didUseCachedResponse];
	GHAssertTrue(success,@"Used cached response when we shouldn't have");
	
	// Etag will be different on the second request
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/content-always-new"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request startSynchronous];
	success = ![request didUseCachedResponse];
	GHAssertTrue(success,@"Used cached response when we shouldn't have");
	
	// Test ignoring server headers
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/no-cache"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[[ASIDownloadCache sharedCache] setShouldRespectCacheControlHeaders:NO];
	[request startSynchronous];
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/no-cache"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[[ASIDownloadCache sharedCache] setShouldRespectCacheControlHeaders:NO];
	[request startSynchronous];
	success = [request didUseCachedResponse];
	GHAssertTrue(success,@"Failed to use cached response");
	
	// Test ASIOnlyLoadIfNotCachedCachePolicy
	[[ASIDownloadCache sharedCache] setShouldRespectCacheControlHeaders:YES];
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/content-always-new"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[[ASIDownloadCache sharedCache] setDefaultCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
	[request startSynchronous];
	success = [request didUseCachedResponse];
	GHAssertTrue(success,@"Failed to use cached response");
	
	// Test clearing the cache
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/cache-away"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request startSynchronous];
	success = ![request didUseCachedResponse];
	GHAssertTrue(success,@"Cached response should not have been available");
}

- (void)testDefaultPolicy
{
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/the_great_american_novel_(abridged).txt"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request startSynchronous];
	BOOL success = ([request cachePolicy] == [[ASIDownloadCache sharedCache] defaultCachePolicy]);
	GHAssertTrue(success,@"Failed to use the cache policy from the cache");
	
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/the_great_american_novel_(abridged).txt"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
	[request startSynchronous];
	success = ([request cachePolicy] == ASIOnlyLoadIfNotCachedCachePolicy);
	GHAssertTrue(success,@"Failed to use the cache policy from the cache");
}

- (void)testNoCache
{
	// Test default cache policy
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	[[ASIDownloadCache sharedCache] setDefaultCachePolicy:ASIIgnoreCachePolicy];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/the_great_american_novel_(abridged).txt"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request startSynchronous];
	
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/the_great_american_novel_(abridged).txt"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request startSynchronous];
	BOOL success = ![request didUseCachedResponse];
	GHAssertTrue(success,@"Data should not have been stored in the cache");	
	
	// Test request cache policy
	[[ASIDownloadCache sharedCache] setDefaultCachePolicy:ASIDefaultCachePolicy];
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/the_great_american_novel_(abridged).txt"]];
	[request setCachePolicy:ASIIgnoreCachePolicy];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request startSynchronous];
	
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/the_great_american_novel_(abridged).txt"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request startSynchronous];
	success = ![request didUseCachedResponse];
	GHAssertTrue(success,@"Data should not have been stored in the cache");
	
	// Test server no-cache headers
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	NSArray *cacheHeaders = [NSArray arrayWithObjects:@"cache-control/no-cache",@"cache-control/no-store",@"pragma/no-cache",nil];
	for (NSString *cacheType in cacheHeaders) {
		NSString *url = [NSString stringWithFormat:@"http://asi/ASIHTTPRequest/tests/%@",cacheType];
		request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
		[request setDownloadCache:[ASIDownloadCache sharedCache]];
		[request startSynchronous];
		
		request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
		[request setDownloadCache:[ASIDownloadCache sharedCache]];
		[request startSynchronous];
		success = ![request didUseCachedResponse];
		GHAssertTrue(success,@"Data should not have been stored in the cache");
	}
}

- (void)testSharedCache
{
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];

	// Make using the cache automatic
	[ASIHTTPRequest setDefaultCache:[ASIDownloadCache sharedCache]];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/the_great_american_novel_(abridged).txt"]];
	[request startSynchronous];
	
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/the_great_american_novel_(abridged).txt"]];
	[request startSynchronous];
	BOOL success = [request didUseCachedResponse];
	GHAssertTrue(success,@"Failed to use data cached in default cache");
	
	[ASIHTTPRequest setDefaultCache:nil];
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/the_great_american_novel_(abridged).txt"]];
	[request startSynchronous];
	success = ![request didUseCachedResponse];
	GHAssertTrue(success,@"Should not have used data cached in default cache");
}

- (void)testExpiry
{
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	[[ASIDownloadCache sharedCache] setDefaultCachePolicy:ASIReloadIfDifferentCachePolicy];

	NSArray *headers = [NSArray arrayWithObjects:@"last-modified",@"etag",@"expires",@"max-age",nil];
	for (NSString *header in headers) {
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://asi/ASIHTTPRequest/tests/content-always-new/%@",header]]];
		[request setDownloadCache:[ASIDownloadCache sharedCache]];
		[request startSynchronous];

		if ([header isEqualToString:@"last-modified"]) {
			[NSThread sleepForTimeInterval:2];
		}

		request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://asi/ASIHTTPRequest/tests/content-always-new/%@",header]]];
		[request setDownloadCache:[ASIDownloadCache sharedCache]];
		[request startSynchronous];
		BOOL success = ![request didUseCachedResponse];
		GHAssertTrue(success,@"Cached data should have expired");
	}
}

- (void)testCustomExpiry
{
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	[[ASIDownloadCache sharedCache] setDefaultCachePolicy:ASIReloadIfDifferentCachePolicy];

	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/cache-away"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request setSecondsToCache:-2];
	[request startSynchronous];

	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/cache-away"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request startSynchronous];

	BOOL success = ![request didUseCachedResponse];
	GHAssertTrue(success,@"Cached data should have expired");

	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/cache-away"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request setSecondsToCache:20];
	[request startSynchronous];

	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/cache-away"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request startSynchronous];

	success = [request didUseCachedResponse];
	GHAssertTrue(success,@"Cached data should have been used");
}

- (void)test304
{
	// Test default cache policy
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	[[ASIDownloadCache sharedCache] setDefaultCachePolicy:ASIReloadIfDifferentCachePolicy];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/the_great_american_novel_(abridged).txt"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request startSynchronous];

	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://asi/ASIHTTPRequest/tests/the_great_american_novel_(abridged).txt"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request startSynchronous];
	BOOL success = ([request responseStatusCode] == 304);
	GHAssertTrue(success,@"Failed to perform a conditional get");

	success = [request didUseCachedResponse];
	GHAssertTrue(success,@"Cached data should have been used");

	success = ([[request responseData] length]);
	GHAssertTrue(success,@"Response was empty");
}

@end
