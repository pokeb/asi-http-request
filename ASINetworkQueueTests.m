//
//  ASINetworkQueueTests.m
//  asi-http-request
//
//  Created by Ben Copsey on 08/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import "ASINetworkQueueTests.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"

@implementation ASINetworkQueueTests


- (void)testProgress
{
	complete = NO;
	progress = 0;
	
	networkQueue = [[ASINetworkQueue alloc] init];
	[networkQueue setDownloadProgressDelegate:self];
	[networkQueue setDelegate:self];
	[networkQueue setRequestDidFinishSelector:@selector(queueFinished:)];	
	
	NSURL *url;	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/first"] autorelease];
	ASIHTTPRequest *request1 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request1];
	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/second"] autorelease];
	ASIHTTPRequest *request2 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request2];
	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/third"] autorelease];
	ASIHTTPRequest *request3 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request3];
	
	
	NSDate* endDate = [NSDate distantFuture];
	while (!complete) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:endDate];
	}
	
	BOOL success = (progress == 1.0);
	STAssertTrue(success,@"Failed to increment progress properly");
	
	[networkQueue release];
	
	
}

- (void)setProgress:(float)newProgress
{
	progress = newProgress;
}


- (void)testFailure
{
	complete = NO;
	
	networkQueue = [[ASINetworkQueue alloc] init];
	[networkQueue setDelegate:self];
	[networkQueue setRequestDidFailSelector:@selector(requestFailed:)];
	[networkQueue setQueueDidFinishSelector:@selector(queueFinished:)];
	[networkQueue setShouldCancelAllRequestsOnFailure:NO];
	
	NSURL *url;	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/first"] autorelease];
	ASIHTTPRequest *request1 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request1];
	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/second"] autorelease];
	ASIHTTPRequest *request2 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request2];
	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/third"] autorelease];
	ASIHTTPRequest *request3 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request3];
	
	url = [[[NSURL alloc] initWithString:@""] autorelease];
	requestThatShouldFail = [[ASIHTTPRequest alloc] initWithURL:url];
	[networkQueue addOperation:requestThatShouldFail];
	
	NSDate* endDate = [NSDate distantFuture];
	while (!complete) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:endDate];
	}
	
	[requestThatShouldFail release];
	
}


- (void)testFailureCancelsOtherRequests
{
	complete = NO;
	
	networkQueue = [[ASINetworkQueue alloc] init];
	[networkQueue setDelegate:self];
	[networkQueue setRequestDidFailSelector:@selector(requestFailedCancellingOthers:)];
	[networkQueue setQueueDidFinishSelector:@selector(queueFinished:)];	
	
	NSURL *url;	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/first"] autorelease];
	ASIHTTPRequest *request1 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request1];
	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/second"] autorelease];
	ASIHTTPRequest *request2 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request2];
	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/third"] autorelease];
	ASIHTTPRequest *request3 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request3];
	
	url = [[[NSURL alloc] initWithString:@""] autorelease];
	requestThatShouldFail = [[ASIHTTPRequest alloc] initWithURL:url];
	[networkQueue addOperation:requestThatShouldFail];

	NSDate* endDate = [NSDate distantFuture];
	while (!complete) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:endDate];
	}
	
	[requestThatShouldFail release];
	
}

- (void)requestFailedCancellingOthers:(ASIHTTPRequest *)request
{
	BOOL success = (request == requestThatShouldFail);
	STAssertTrue(success,@"Wrong request failed");
	complete = YES;
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	BOOL success = (request == requestThatShouldFail);
	STAssertTrue(success,@"Wrong request failed");
}

- (void)queueFinished:(ASINetworkQueue *)queue
{
	complete = YES;

}
 



@end
