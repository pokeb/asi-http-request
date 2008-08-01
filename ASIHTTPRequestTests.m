//
//  ASIHTTPRequestTests.m
//  asi-http-request
//
//  Created by Ben Copsey on 01/08/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import "ASIHTTPRequestTests.h"
#import "ASIHTTPRequest.h"

@implementation ASIHTTPRequestTests

/*
More tests needed for:
 - Delegates
 - Progress delegates
 - Content length
 - POSTing
 - File downloads
 - Authentication
 - Keychains
 - Session persistence
*/

- (void)testBasicDownload
{
	//Grab data
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request start];
	NSString *html = [request dataString];
	STAssertNotNil(html,@"Basic synchronous request failed");

	//Check we're getting the correct response headers
	NSString *pingBackHeader = [[request responseHeaders] objectForKey:@"X-Pingback"];
	BOOL success = [pingBackHeader isEqualToString:@"http://allseeing-i.com/Ping-Back"];
	STAssertTrue(success,@"Failed to populate response headers");
	
	//Check we're getting back the correct status code
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/a-page-that-does-not-exist"] autorelease];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request start];
	success = ([request responseStatusCode] == 404);
	STAssertTrue(success,@"Didn't get correct status code");	
	
	//Check data
	NSRange notFound = NSMakeRange(NSNotFound, 0);
	success = !NSEqualRanges([html rangeOfString:@"All-Seeing Interactive"],notFound);
	STAssertTrue(success,@"Failed to download the correct data");
	
	//Attempt to grab from bad url (astonishingly, there is a website at http://aaaaaaaaaaaaaaaaaaaaaaaaaaaaa.com !)
	url = [[[NSURL alloc] initWithString:@"http://aaaaaaaaaaaaaaaaaaaaaaaaaaaaab.com"] autorelease];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request start];
	NSError *error = [request error];
	STAssertNotNil(error,@"Failed to generate an error for a bad host");
}

- (void)testOperationQueue
{
	NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];

	NSURL *url;	
	url = [[[NSURL alloc] initWithString:@"http:/allseeing-i.com/asi-http-request/tests/first"] autorelease];
	ASIHTTPRequest *request1 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[queue addOperation:request1];

	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/second"] autorelease];
	ASIHTTPRequest *request2 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[queue addOperation:request2];

	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/third"] autorelease];
	ASIHTTPRequest *request3 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[queue addOperation:request3];
	
	url = [[[NSURL alloc] initWithString:@"http://aaaaaaaaaaaaaaaaaaaaaaaaaaaaab.com"] autorelease];
	ASIHTTPRequest *request4 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[queue addOperation:request4];
	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/broken"] autorelease];
	ASIHTTPRequest *request5 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[queue addOperation:request5];

	[queue waitUntilAllOperationsAreFinished];

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
	
	success = ([request4 error] != nil);
	STAssertTrue(success,@"Request 4 succeed when it should have failed");

	success = ([request5 error] == nil);
	STAssertTrue(success,@"Request 5 failed");
	
	success = ([request5 responseStatusCode] == 404);
	STAssertTrue(success,@"Failed to obtain the correct status code for request 5");
		
}

@end
