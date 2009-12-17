//
//  PerformanceTests.m
//  Mac
//
//  Created by Ben Copsey on 17/12/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import "PerformanceTests.h"
#import "ASIHTTPRequest.h"

@interface NSURLConnectionSubclass : NSURLConnection {
	int tag;
}
@property (assign) int tag;
@end
@implementation NSURLConnectionSubclass
@synthesize tag;
@end


@implementation PerformanceTests

- (void)testASIHTTPRequestAsyncPerformance
{
	[self performSelectorOnMainThread:@selector(startASIHTTPRequests) withObject:nil waitUntilDone:NO];
}


- (void)startASIHTTPRequests
{
	bytesDownloaded = 0;
	[self setRequestsComplete:0];
	[self setTestStartDate:[NSDate date]];
	int i;
	for (i=0; i<5; i++) {
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/the_great_american_novel_(abridged).txt"]];
		[request setDelegate:self];
		[request startAsynchronous];
	}
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	GHFail(@"Cannot proceed with ASIHTTPRequest test - a request failed");
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	bytesDownloaded += [[request responseData] length];
	requestsComplete++;
	if (requestsComplete == 5) {
		NSLog(@"ASIHTTPRequest: Completed 5 (downloaded %lu bytes) requests in %f seconds",bytesDownloaded,[[NSDate date] timeIntervalSinceDate:[self testStartDate]]);
	}
}

- (void)testNSURLConnectionAsyncPerformance
{
	[self performSelectorOnMainThread:@selector(startNSURLConnections) withObject:nil waitUntilDone:NO];
}

- (void)startNSURLConnections
{
	bytesDownloaded = 0;
	[self setRequestsComplete:0];
	[self setTestStartDate:[NSDate date]];
	[self setResponseData:[NSMutableArray arrayWithCapacity:5]]; 
	
	int i;
	for (i=0; i<5; i++) {
		NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/the_great_american_novel_(abridged).txt"] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];
		[[self responseData] addObject:[NSMutableData data]];
		NSURLConnectionSubclass *connection = [[[NSURLConnectionSubclass alloc] initWithRequest:request delegate:self startImmediately:YES] autorelease];
		[connection setTag:i];		
	}
}

- (void)connection:(NSURLConnectionSubclass *)connection didReceiveResponse:(NSURLResponse *)response
{
}

- (void)connection:(NSURLConnectionSubclass *)connection didFailWithError:(NSError *)error
{
	GHFail(@"Cannot proceed with NSURLConnection test - a request failed");
}

- (void)connection:(NSURLConnectionSubclass *)connection didReceiveData:(NSData *)data
{
	[[[self responseData] objectAtIndex:[connection tag]] appendData:data];	

}

- (void)connectionDidFinishLoading:(NSURLConnectionSubclass *)connection
{
	bytesDownloaded += [[responseData objectAtIndex:[connection tag]] length];
	requestsComplete++;
	if (requestsComplete == 5) {
		NSLog(@"NSURLConnection: Completed 5 (downloaded %lu bytes) requests in %f seconds",bytesDownloaded,[[NSDate date] timeIntervalSinceDate:[self testStartDate]]);
	}		
}

@synthesize requestsComplete;
@synthesize testStartDate;
@synthesize responseData;
@end
