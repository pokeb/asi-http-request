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
#import "ASIFormDataRequest.h"

/*
IMPORTANT
Code that appears in these tests is not for general purpose use. 
You should not use [networkQueue waitUntilAllOperationsAreFinished] or [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]] in your own software.
They are used here to force a queue to operate synchronously to simplify writing the tests.
IMPORTANT
*/

// Used for subclass test
@interface ASINetworkQueueSubclass : ASINetworkQueue {}
@end
@implementation ASINetworkQueueSubclass
@end

@implementation ASINetworkQueueTests

- (void)testDelegateAuthenticationCredentialsReuse
{
	complete = NO;
	authenticationPromptCount = 0;

	ASINetworkQueue *networkQueue = [ASINetworkQueue queue];
	[networkQueue setDelegate:self];
	[networkQueue setQueueDidFinishSelector:@selector(queueFinished:)];	
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"reuse" forKey:@"test"];
	
	int i;
	for (i=0; i<5; i++) {
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/basic-authentication"]];
		[request setUserInfo:userInfo];
		[networkQueue addOperation:request];
	}
	[networkQueue go];
	
	while (!complete) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	}
}



- (void)testProgress
{
	complete = NO;
	progress = 0;
	
	ASINetworkQueue *networkQueue = [ASINetworkQueue queue];
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
		
	while (!complete) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	}
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	BOOL success = (progress > 0.95);
	GHAssertTrue(success,@"Failed to increment progress properly");
	
	//Now test again with accurate progress
	complete = NO;
	progress = 0;
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
	
	// Progress maths are inexact for queues
	success = (progress > 0.95);
	GHAssertTrue(success,@"Failed to increment progress properly");
	
}

- (void)testUploadProgress
{
	complete = NO;
	progress = 0;
	
	ASINetworkQueue *networkQueue = [[[ASINetworkQueue alloc] init] autorelease];
	[networkQueue setUploadProgressDelegate:self];
	[networkQueue setDelegate:self];
	[networkQueue setShowAccurateProgress:NO];
	[networkQueue setQueueDidFinishSelector:@selector(queueFinished:)];	
	
	NSURL *url = [NSURL URLWithString:@"http://allseeing-i.com/ignore"];
	
	int fileSizes[3] = {16,64,257};
	int i;
	for (i=0; i<3; i++) {
		NSData *data = [[[NSMutableData alloc] initWithLength:fileSizes[i]*1024] autorelease];
		NSString *path = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:[NSString stringWithFormat:@"file%hi",i]];
		[data writeToFile:path atomically:NO];
		ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
		[request setFile:path forKey:@"file"];
		[networkQueue addOperation:request];	
	}
	
	[networkQueue go];
	
	while (!complete) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	}
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	BOOL success = (progress > 0.95);
	GHAssertTrue(success,@"Failed to increment progress properly");
	
	//Now test again with accurate progress
	complete = NO;
	progress = 0;
	[networkQueue cancelAllOperations];
	[networkQueue setShowAccurateProgress:YES];
	
	for (i=0; i<3; i++) {
		NSData *data = [[[NSMutableData alloc] initWithLength:fileSizes[i]*1024] autorelease];
		NSString *path = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:[NSString stringWithFormat:@"file%hi",i]];
		[data writeToFile:path atomically:NO];
		ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
		[request setFile:path forKey:@"file"];
		[networkQueue addOperation:request];	
	}
	
	[networkQueue go];
	
	while (!complete) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	}
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	success = (progress > 0.95);
	GHAssertTrue(success,@"Failed to increment progress properly");
	
}




- (void)setProgress:(float)newProgress
{
	progress = newProgress;
}



- (void)testFailure
{
	complete = NO;
	
	ASINetworkQueue *networkQueue = [ASINetworkQueue queue];
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
	GHAssertTrue(success,@"Request 1 failed");
	
	success = [[request1 responseString] isEqualToString:@"This is the expected content for the first string"];
	GHAssertTrue(success,@"Failed to download the correct data for request 1");
	
	success = ([request2 error] == nil);
	GHAssertTrue(success,@"Request 2 failed");
	
	success = [[request2 responseString] isEqualToString:@"This is the expected content for the second string"];
	GHAssertTrue(success,@"Failed to download the correct data for request 2");
	
	success = ([request3 error] == nil);
	GHAssertTrue(success,@"Request 3 failed");
	
	success = [[request3 responseString] isEqualToString:@"This is the expected content for the third string"];
	GHAssertTrue(success,@"Failed to download the correct data for request 3");
	
	success = ([requestThatShouldFail error] != nil);
	GHAssertTrue(success,@"Request 4 succeed when it should have failed");
	
	success = ([request5 error] == nil);
	GHAssertTrue(success,@"Request 5 failed");
	
	success = ([request5 responseStatusCode] == 404);
	GHAssertTrue(success,@"Failed to obtain the correct status code for request 5");


	
	[requestThatShouldFail release];
	
}


- (void)testFailureCancelsOtherRequests
{
	complete = NO;
	
	ASINetworkQueue *networkQueue = [ASINetworkQueue queue];
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
	GHAssertTrue(success,@"Wrong request failed");
}

- (void)queueFinished:(ASINetworkQueue *)queue
{
	complete = YES;
}




- (void)testProgressWithAuthentication
{
	complete = NO;
	progress = 0;
	
	// Make sure we don't re-use credentials from previous tests
	[ASIHTTPRequest clearSession];
	
	ASINetworkQueue *networkQueue = [ASINetworkQueue queue];
	[networkQueue setDownloadProgressDelegate:self];
	[networkQueue setDelegate:self];
	[networkQueue setShowAccurateProgress:YES];
	[networkQueue setQueueDidFinishSelector:@selector(queueFinished:)];	
	[networkQueue setRequestDidFailSelector:@selector(requestFailedCancellingOthers:)];
	
	NSURL *url;	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/basic-authentication"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUserInfo:[NSDictionary dictionaryWithObject:@"Don't bother" forKey:@"Shall I return any credentials?"]];
	[networkQueue addOperation:request];
	
	[networkQueue go];
	

	while (!complete) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	}

	NSError *error = [request error];
	GHAssertNotNil(error,@"The HEAD request failed, but it didn't tell the main request to fail");	
	
	complete = NO;
	progress = 0;	
	networkQueue = [ASINetworkQueue queue];
	[networkQueue setDownloadProgressDelegate:self];
	[networkQueue setDelegate:self];
	[networkQueue setShowAccurateProgress:YES];
	[networkQueue setQueueDidFinishSelector:@selector(queueFinished:)];	
	[networkQueue setRequestDidFailSelector:@selector(requestFailed:)];
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUserInfo:[NSDictionary dictionaryWithObject:@"Don't bother" forKey:@"Shall I return any credentials?"]];
	[request setUsername:@"secret_username"];
	[request setPassword:@"secret_password"];
	[networkQueue addOperation:request];
	
	[networkQueue go];
	
	while (!complete) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	}
	
	error = [request error];
	GHAssertNil(error,@"Failed to use authentication in a queue");	
	
}

- (void)testDelegateAuthentication
{
	complete = NO;
	ASINetworkQueue *networkQueue = [ASINetworkQueue queue];
	[networkQueue setDelegate:self];
	[networkQueue setRequestDidFinishSelector:@selector(queueFinished:)];
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/basic-authentication"]];
	[networkQueue addOperation:request];
	
	[networkQueue go];
	
	while (!complete) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	}
	
	NSError *error = [request error];
	GHAssertNil(error,@"Request failed");	
}


- (void)authenticationNeededForRequest:(ASIHTTPRequest *)request
{
	// We're using this method in multiple tests, so the code here is to act appropriatly for each one
	if ([[[request userInfo] objectForKey:@"test"] isEqualToString:@"reuse"]) {
		authenticationPromptCount++;
		BOOL success = (authenticationPromptCount == 1);
		GHAssertTrue(success,@"Delegate was asked for credentials more than once");
		
		[request setUsername:@"secret_username"];
		[request setPassword:@"secret_password"];
		[request retryUsingSuppliedCredentials];
		
	} else if ([[[request userInfo] objectForKey:@"test"] isEqualToString:@"delegate-auth-failure"]) {
		authenticationPromptCount++;
		if (authenticationPromptCount == 5) {
			[request setUsername:@"secret_username"];
			[request setPassword:@"secret_password"];
		} else {
			[request setUsername:@"wrong_username"];
			[request setPassword:@"wrong_password"];
		}
		[request retryUsingSuppliedCredentials];
			

	// testProgressWithAuthentication will set a userInfo dictionary on the main request, to tell us not to supply credentials
	} else if (![request mainRequest] || ![[request mainRequest] userInfo]) {
		[request setUsername:@"secret_username"];
		[request setPassword:@"secret_password"];
		[request retryUsingSuppliedCredentials];
	} else {
		[request cancelAuthentication];
	}
}





- (void)requestFailedExpectedly:(ASIHTTPRequest *)request
{
    request_didfail = YES;
    BOOL success = (request == requestThatShouldFail);
    GHAssertTrue(success,@"Wrong request failed");
}

- (void)requestSucceededUnexpectedly:(ASIHTTPRequest *)request
{
    request_succeeded = YES;
}

//Connect to a port the server isn't listening on, and the read stream won't be created (Test + Fix contributed by Michael Krause)
- (void)testWithNoListener
{
    request_succeeded = NO;
    request_didfail = NO;
	ASINetworkQueue *networkQueue = [ASINetworkQueue queue];
	[networkQueue setDownloadProgressDelegate:self];
	[networkQueue setDelegate:self];
	[networkQueue setShowAccurateProgress:YES];
    [networkQueue setRequestDidFailSelector:@selector(requestFailedExpectedly:)];
    [networkQueue setRequestDidFinishSelector:@selector(requestSucceededUnexpectedly:)];
	[networkQueue setQueueDidFinishSelector:@selector(queueFinished:)];	
	
	NSURL *url;	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com:9999/i/logo.png"] autorelease];
	requestThatShouldFail = [[ASIHTTPRequest alloc] initWithURL:url];
	[networkQueue addOperation:requestThatShouldFail];
	
	[networkQueue go];
	[networkQueue waitUntilAllOperationsAreFinished];
    
	// Give the queue time to notify us
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	
	// This test may fail if you are using a proxy and it returns a page when you try to connect to a bad port.
	GHAssertTrue(!request_succeeded && request_didfail,@"Request to resource without listener succeeded but should have failed");
    
}

- (void)testPartialResume
{
	complete = NO;
	progress = 0;
	
	NSString *temporaryPath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"MemexTrails_1.0b1.zip.download"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:temporaryPath]) {
		[[NSFileManager defaultManager] removeItemAtPath:temporaryPath error:nil];
	}
	
	NSString *downloadPath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"MemexTrails_1.0b1.zip"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:downloadPath]) {
		[[NSFileManager defaultManager] removeItemAtPath:downloadPath error:nil];
	}
	
	NSURL *downloadURL = [NSURL URLWithString:@"http://trails-network.net/Downloads/MemexTrails_1.0b1.zip"];
	ASINetworkQueue *networkQueue = [ASINetworkQueue queue];	

	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:downloadURL] autorelease];
	[request setDownloadDestinationPath:downloadPath];
	[request setTemporaryFileDownloadPath:temporaryPath];
	[request setAllowResumeForFileDownloads:YES];
	[networkQueue addOperation:request];
	[networkQueue go];
	 
	// Let the download run for 5 seconds, which hopefully won't be enough time to grab this file. If you have a super fast connection, this test may fail, serves you right for being so smug. :)
	NSTimer *timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(stopQueue:) userInfo:nil repeats:NO];
	
	while (!complete) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	}
	
	// 5 seconds is up, let's tell the queue to stop
	[networkQueue cancelAllOperations];
	
	networkQueue = [ASINetworkQueue queue];
	[networkQueue setDownloadProgressDelegate:self];
	[networkQueue setShowAccurateProgress:YES];
	[networkQueue setDelegate:self];
	[networkQueue setQueueDidFinishSelector:@selector(queueFinished:)];	
	
	complete = NO;
	progress = 0;	
	unsigned long long downloadedSoFar = [[[NSFileManager defaultManager] fileAttributesAtPath:temporaryPath traverseLink:NO] fileSize];
	BOOL success = (downloadedSoFar > 0);
	GHAssertTrue(success,@"Failed to download part of the file, so we can't proceed with this test");
	
	request = [[[ASIHTTPRequest alloc] initWithURL:downloadURL] autorelease];
	[request setDownloadDestinationPath:downloadPath];
	[request setTemporaryFileDownloadPath:temporaryPath];
	[request setAllowResumeForFileDownloads:YES];
	
	[networkQueue addOperation:request];

	[networkQueue go];

	while (!complete) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	}
	
	unsigned long long amountDownloaded = [[[NSFileManager defaultManager] fileAttributesAtPath:downloadPath traverseLink:NO] fileSize];
	success = (amountDownloaded == 9145357);
	GHAssertTrue(success,@"Failed to complete the download");
	
	success = (progress > 0.95);
	GHAssertTrue(success,@"Failed to increment progress properly");
	

	
	//Test the temporary file cleanup
	complete = NO;
	progress = 0;
	networkQueue = [ASINetworkQueue queue];
	[networkQueue setDownloadProgressDelegate:self];
	[networkQueue setShowAccurateProgress:YES];
	[networkQueue setDelegate:self];
	[networkQueue setQueueDidFinishSelector:@selector(queueFinished:)];	
	
	request = [[[ASIHTTPRequest alloc] initWithURL:downloadURL] autorelease];
	[request setDownloadDestinationPath:downloadPath];
	[request setTemporaryFileDownloadPath:temporaryPath];
	[request setAllowResumeForFileDownloads:YES];
	[networkQueue addOperation:request];
	[networkQueue go];
	
	// Let the download run for 5 seconds
	timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(stopQueue:) userInfo:nil repeats:NO];
	while (!complete) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	}
	[networkQueue cancelAllOperations];
	
	success = ([[NSFileManager defaultManager] fileExistsAtPath:temporaryPath]);
	GHAssertTrue(success,@"Temporary download file doesn't exist");	
	
	[request removeTemporaryDownloadFile];
	
	success = (![[NSFileManager defaultManager] fileExistsAtPath:temporaryPath]);
	GHAssertTrue(success,@"Temporary download file should have been deleted");		
	
	timeoutTimer = nil;
	
}

- (void)stopQueue:(id)sender
{
	complete = YES;
}

// A test for a potential crasher that used to exist when requests were cancelled
// We aren't testing a specific condition here, but rather attempting to trigger a crash
// This test is commented out because it may generate enough load to kill a low-memory server
// PLEASE DO NOT RUN THIS TEST ON A NON-LOCAL SERVER
/*
- (void)testCancelStressTest
{
	[self setCancelQueue:[ASINetworkQueue queue]];
	
	// Increase the risk of this crash
	[[self cancelQueue] setMaxConcurrentOperationCount:25];
	int i;
	for (i=0; i<100; i++) {
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://127.0.0.1"]];
		[[self cancelQueue] addOperation:request];
	}
	[[self cancelQueue] go];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
	[[self cancelQueue] cancelAllOperations];
	[self setCancelQueue:nil];
}
*/

// Not strictly an ASINetworkQueue test, but queue related
// As soon as one request finishes or fails, we'll cancel the others and ensure that no requests are both finished and failed
- (void)testImmediateCancel
{
	[self setFailedRequests:[[[NSMutableArray alloc] init] autorelease]];
	[self setFinishedRequests:[[[NSMutableArray alloc] init] autorelease]];
	[self setImmediateCancelQueue:[[[NSOperationQueue alloc] init] autorelease]];
	int i;
	for (i=0; i<100; i++) {
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com"]];
		[request setDelegate:self];
		[request setDidFailSelector:@selector(immediateCancelFail:)];
		[request setDidFinishSelector:@selector(immediateCancelFinish:)];
		[[self immediateCancelQueue] addOperation:request];
	}
	
}

- (void)immediateCancelFail:(ASIHTTPRequest *)request
{
	[[self immediateCancelQueue] cancelAllOperations];
	if ([[self failedRequests] containsObject:request]) {
		GHFail(@"A request called its fail delegate method twice");
	}
	if ([[self finishedRequests] containsObject:request]) {
		GHFail(@"A request that had already finished called its fail delegate method");
	}
	[[self failedRequests] addObject:request];
	if ([[self failedRequests] count]+[[self finishedRequests] count] > 100) {
		GHFail(@"We got more than 100 delegate fail/finish calls - this shouldn't happen!");
	}
}

- (void)immediateCancelFinish:(ASIHTTPRequest *)request
{
	[[self immediateCancelQueue] cancelAllOperations];
	if ([[self finishedRequests] containsObject:request]) {
		GHFail(@"A request called its finish delegate method twice");
	}
	if ([[self failedRequests] containsObject:request]) {
		GHFail(@"A request that had already failed called its finish delegate method");
	}
	[[self finishedRequests] addObject:request];
	if ([[self failedRequests] count]+[[self finishedRequests] count] > 100) {
		GHFail(@"We got more than 100 delegate fail/finish calls - this shouldn't happen!");
	}
}

// Ensure class convenience constructor returns an instance of our subclass
- (void)testSubclass
{
	ASINetworkQueueSubclass *instance = [ASINetworkQueueSubclass queue];
	BOOL success = [instance isKindOfClass:[ASINetworkQueueSubclass class]];
	GHAssertTrue(success,@"Convenience constructor failed to return an instance of the correct class");	
}


// Test releasing the queue in a couple of ways - the purpose of these tests is really just to ensure we don't crash
- (void)testQueueReleaseOnRequestComplete
{
	[[self releaseTestQueue] cancelAllOperations];
	[self setReleaseTestQueue:[ASINetworkQueue queue]];
	int i;
	for (i=0; i<5; i++) {
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com"]];
		[request setDelegate:self];
		[request setDidFailSelector:@selector(fail:)];
		[request setDidFinishSelector:@selector(finish:)];
		[[self releaseTestQueue] addOperation:request];
	}
}

- (void)fail:(ASIHTTPRequest *)request
{
	if ([[self releaseTestQueue] requestsCount] == 0) {
		[self setReleaseTestQueue:nil];
	}
}
 
- (void)finish:(ASIHTTPRequest *)request
{
	if ([[self releaseTestQueue] requestsCount] == 0) {
		[self setReleaseTestQueue:nil];
	}	
}

- (void)testQueueReleaseOnQueueComplete
{
	[[self releaseTestQueue] cancelAllOperations];
	[self setReleaseTestQueue:[ASINetworkQueue queue]];
	[[self releaseTestQueue] setDelegate:self];
	int i;
	for (i=0; i<5; i++) {
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com"]];
		[[self releaseTestQueue] addOperation:request];
	}
}

- (void)queueComplete:(ASINetworkQueue *)queue
{
	[self setReleaseTestQueue:nil];
}

- (void)testMultipleDownloadsThrottlingBandwidth
{
	complete = NO;
	
	[ASIHTTPRequest setMaxBandwidthPerSecond:0];
	
	ASINetworkQueue *networkQueue = [ASINetworkQueue queue];
	[networkQueue setDelegate:self];
	[networkQueue setRequestDidFailSelector:@selector(throttleFail:)];
	[networkQueue setQueueDidFinishSelector:@selector(queueFinished:)];
	
	// We'll test first without throttling
	int i;
	for (i=0; i<5; i++) {
		// This image is around 18KB in size, for 90KB total download size
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/i/logo.png"]];
		[networkQueue addOperation:request];
	}
	
	NSDate *date = [NSDate date];
	[networkQueue go];
	
	while (!complete) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	}
	
	
	NSTimeInterval interval =[date timeIntervalSinceNow];
	BOOL success = (interval > -6);
	GHAssertTrue(success,@"Downloaded the data too slowly - either this is a bug, or your internet connection is too slow to run this test (must be able to download 90KB in less than 6 seconds, without throttling)");

	//NSLog(@"Throttle");
	
	// Reset the queue
	[networkQueue cancelAllOperations];
	networkQueue = [ASINetworkQueue queue];
	[networkQueue setDelegate:self];
	[networkQueue setRequestDidFailSelector:@selector(throttleFail:)];
	[networkQueue setQueueDidFinishSelector:@selector(queueFinished:)];
	complete = NO;
	
	// Now we'll test with throttling
	[ASIHTTPRequest setMaxBandwidthPerSecond:ASIWWANBandwidthThrottleAmount];
	
	for (i=0; i<5; i++) {
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/i/logo.png"]];
		[networkQueue addOperation:request];
	}
	
	date = [NSDate date];
	[networkQueue go];
	
	while (!complete) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	}
	
	[ASIHTTPRequest setMaxBandwidthPerSecond:0];
	
	interval =[date timeIntervalSinceNow];
	success = (interval < -6);
	GHAssertTrue(success,@"Failed to throttle upload");		
	
}

- (void)testMultipleUploadsThrottlingBandwidth
{
	complete = NO;
	
	[ASIHTTPRequest setMaxBandwidthPerSecond:0];
	
	ASINetworkQueue *networkQueue = [ASINetworkQueue queue];
	[networkQueue setDelegate:self];
	[networkQueue setRequestDidFailSelector:@selector(throttleFail:)];
	[networkQueue setQueueDidFinishSelector:@selector(queueFinished:)];

	// Create a 16KB request body
	NSData *data = [[[NSMutableData alloc] initWithLength:16*1024] autorelease];

	// We'll test first without throttling
	int i;
	for (i=0; i<10; i++) {
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ignore"]];
		[request appendPostData:data];
		[networkQueue addOperation:request];
	}
	
	NSDate *date = [NSDate date];
	[networkQueue go];
	
	while (!complete) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	}
	
		
	NSTimeInterval interval =[date timeIntervalSinceNow];
	BOOL success = (interval > -11);
	GHAssertTrue(success,@"Uploaded the data too slowly - either this is a bug, or your internet connection is too slow to run this test (must be able to upload 320KB in less than 11 seconds, without throttling)");
	
	//NSLog(@"Throttle");
	
	// Reset the queue
	[networkQueue cancelAllOperations];
	networkQueue = [ASINetworkQueue queue];
	[networkQueue setDelegate:self];
	[networkQueue setRequestDidFailSelector:@selector(throttleFail:)];
	[networkQueue setQueueDidFinishSelector:@selector(queueFinished:)];
	complete = NO;
	
	// Now we'll test with throttling
	[ASIHTTPRequest setMaxBandwidthPerSecond:ASIWWANBandwidthThrottleAmount];

	for (i=0; i<10; i++) {
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ignore"]];
		[request appendPostData:data];
		[networkQueue addOperation:request];
	}
	
	date = [NSDate date];
	[networkQueue go];
	
	while (!complete) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	}
	
	[ASIHTTPRequest setMaxBandwidthPerSecond:0];
	
	interval =[date timeIntervalSinceNow];
	success = (interval < -11);
	GHAssertTrue(success,@"Failed to throttle upload");		
	
}
	 
- (void)throttleFail:(ASIHTTPRequest *)request
{
	GHAssertTrue(NO,@"Request failed");
}

// Test for a bug that used to exist where the temporary file used to store the request body would be removed when authentication failed
- (void)testPOSTWithAuthentication
{
	[[self postQueue] cancelAllOperations];
	[self setPostQueue:[ASINetworkQueue queue]];
	[[self postQueue] setRequestDidFinishSelector:@selector(postDone:)];
	[[self postQueue] setDelegate:self];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/Tests/post_with_authentication"]];
	[request setPostValue:@"This is the first item" forKey:@"first"];
	[request setData:[@"This is the second item" dataUsingEncoding:NSUTF8StringEncoding] forKey:@"second"];
	[[self postQueue] addOperation:request];
	[[self postQueue] go];
}

- (void)postDone:(ASIHTTPRequest *)request
{
	BOOL success = [[request responseString] isEqualToString:@"This is the first item\r\nThis is the second item"];
	GHAssertTrue(success,@"Didn't post correct data");	
}

- (void)testDelegateAuthenticationFailure
{
	[[self postQueue] cancelAllOperations];
	[self setPostQueue:[ASINetworkQueue queue]];
	[[self postQueue] setRequestDidFinishSelector:@selector(postDone:)];
	[[self postQueue] setDelegate:self];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/Tests/post_with_authentication"]];
	[request setPostValue:@"This is the first item" forKey:@"first"];
	[request setData:[@"This is the second item" dataUsingEncoding:NSUTF8StringEncoding] forKey:@"second"];
	[request setUserInfo:[NSDictionary dictionaryWithObject:@"delegate-auth-failure" forKey:@"test"]];
	[[self postQueue] addOperation:request];
	[[self postQueue] go];
}

@synthesize immediateCancelQueue;
@synthesize failedRequests;
@synthesize finishedRequests;
@synthesize releaseTestQueue;
@synthesize cancelQueue;
@synthesize postQueue;
@end
