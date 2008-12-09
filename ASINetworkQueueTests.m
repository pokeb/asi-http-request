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
	[networkQueue setShowAccurateProgress:NO];
	[networkQueue setQueueDidFinishSelector:@selector(queueFinished:)];	
	
	NSURL *url;	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/i/logo.png"] autorelease];
	ASIHTTPRequest *request1 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request1];
	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/i/trailsnetwork.png"] autorelease];
	ASIHTTPRequest *request2 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request2];
	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/sharedspace20.png"] autorelease];
	ASIHTTPRequest *request3 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request3];
	
	[networkQueue go];
	
	NSDate* endDate = [NSDate distantFuture];
	while (!complete) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:endDate];
	}
	
	BOOL success = (progress == 1.0);
	STAssertTrue(success,@"Failed to increment progress properly");
	
	//Now test again with accurate progress
	[networkQueue cancelAllOperations];
	[networkQueue setShowAccurateProgress:YES];

	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/i/logo.png"] autorelease];
	request1 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request1];
	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/i/trailsnetwork.png"] autorelease];
	request2 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request2];
	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/sharedspace20.png"] autorelease];
	request3 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request3];
	
	[networkQueue go];
	
	[networkQueue waitUntilAllOperationsAreFinished];
	
	success = (progress == 1.0);
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
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/first"] autorelease];
	ASIHTTPRequest *request1 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request1];
	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/second"] autorelease];
	ASIHTTPRequest *request2 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request2];
	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/third"] autorelease];
	ASIHTTPRequest *request3 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request3];
	
	url = [[[NSURL alloc] initWithString:@""] autorelease];
	requestThatShouldFail = [[ASIHTTPRequest alloc] initWithURL:url];
	[networkQueue addOperation:requestThatShouldFail];

	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/broken"] autorelease];
	ASIHTTPRequest *request5 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request5];

	[networkQueue go];
	
	[networkQueue waitUntilAllOperationsAreFinished];
	
	
	BOOL success;
	success = ([request1 error] == nil);
	STAssertTrue(success,@"Request 1 failed");
	
	success = [[request1 dataString] isEqualToString:@"This is the expected content for the first string"];
	STAssertTrue(success,@"Failed to download the correct data for request 1");
	
	success = ([request2 error] == nil);
	STAssertTrue(success,@"Request 2 failed");
	
	success = [[request2 dataString] isEqualToString:@"This is the expected content for the second string"];
	STAssertTrue(success,@"Failed to download the correct data for request 2");
	
	success = ([request3 error] == nil);
	STAssertTrue(success,@"Request 3 failed");
	
	success = [[request3 dataString] isEqualToString:@"This is the expected content for the third string"];
	STAssertTrue(success,@"Failed to download the correct data for request 3");
	
	success = ([requestThatShouldFail error] != nil);
	STAssertTrue(success,@"Request 4 succeed when it should have failed");
	
	success = ([request5 error] == nil);
	STAssertTrue(success,@"Request 5 failed");
	
	success = ([request5 responseStatusCode] == 404);
	STAssertTrue(success,@"Failed to obtain the correct status code for request 5");


	
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
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/first"] autorelease];
	ASIHTTPRequest *request1 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request1];
	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/second"] autorelease];
	ASIHTTPRequest *request2 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request2];
	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/third"] autorelease];
	ASIHTTPRequest *request3 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request3];
	
	url = [[[NSURL alloc] initWithString:@""] autorelease];
	requestThatShouldFail = [[ASIHTTPRequest alloc] initWithURL:url];
	[networkQueue addOperation:requestThatShouldFail];

	[networkQueue go];
	
	[networkQueue waitUntilAllOperationsAreFinished];
	
	
	[requestThatShouldFail release];	
}


 
- (void)requestFailedCancellingOthers:(ASIHTTPRequest *)request
{
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

- (void)testProgressWithAuthentication
{
	complete = NO;
	progress = 0;
	
	networkQueue = [[ASINetworkQueue alloc] init];
	[networkQueue setDownloadProgressDelegate:self];
	[networkQueue setDelegate:self];
	[networkQueue setShowAccurateProgress:YES];
	[networkQueue setQueueDidFinishSelector:@selector(queueFinished:)];	
	[networkQueue setRequestDidFailSelector:@selector(requestFailedCancellingOthers:)];
	
	NSURL *url;	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/basic-authentication"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[networkQueue addOperation:request];
	
	[networkQueue go];
	
	NSDate* endDate = [NSDate distantFuture];
	while (!complete) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:endDate];
	}

	NSError *error = [request error];
	STAssertNotNil(error,@"The HEAD request failed, but it didn't tell the main request to fail");	
	[networkQueue release];
	
	
	networkQueue = [[ASINetworkQueue alloc] init];
	[networkQueue setDownloadProgressDelegate:self];
	[networkQueue setDelegate:self];
	[networkQueue setShowAccurateProgress:YES];
	[networkQueue setQueueDidFinishSelector:@selector(queueFinished:)];	
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUsername:@"secret_username"];
	[request setPassword:@"secret_password"];
	[networkQueue addOperation:request];
	
	[networkQueue go];
	
	while (!complete) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:endDate];
	}
	
	error = [request error];
	STAssertNil(error,@"Failed to use authentication in a queue");	
	[networkQueue release];
	
	
	
	
	
}



@end
