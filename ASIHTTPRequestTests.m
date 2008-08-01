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

@end
