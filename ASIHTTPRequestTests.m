//
//  ASIHTTPRequestTests.m
//  asi-http-request
//
//  Created by Ben Copsey on 01/08/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import "ASIHTTPRequestTests.h"
#import "ASIHTTPRequest.h"
#import "NSHTTPCookieAdditions.h"

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
	STAssertNotNil(error,@"Failed to generate an error for a bad host - this test may fail when your DNS server redirects you to another page when it can't find a domain name (eg OpenDNS)");
}

- (void)testTimeOut
{
	//Grab data
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setTimeOutSeconds:0.0001]; //It's pretty unlikely we will be able to grab the data this quickly, so the request should timeout
	[request start];
	NSError *error = [request error];
	STAssertNotNil(error,@"Request didn't timeout");
	BOOL success = [[[error userInfo] valueForKey:@"Description"] isEqualToString:@"Request timed out"];
	STAssertTrue(success,@"Timeout didn't generate the correct error");
	
}

- (void)testOperationQueue
{
	NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];

	NSURL *url;	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/first"] autorelease];
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
	STAssertTrue(success,@"Request 4 succeed when it should have failed - this test may fail when your DNS server redirects you to another page when it can't find a domain name (eg OpenDNS)");

	success = ([request5 error] == nil);
	STAssertTrue(success,@"Request 5 failed");
	
	success = ([request5 responseStatusCode] == 404);
	STAssertTrue(success,@"Failed to obtain the correct status code for request 5");
		
}

- (void)testCookies
{
	BOOL success;
	
	//Set setting a cookie
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/set_cookie"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseCookiePersistance:YES];
	[request start];
	NSString *html = [request dataString];
	success = [html isEqualToString:@"I have set a cookie"];
	STAssertTrue(success,@"Failed to set a cookie");
	
	//Test a cookie is stored in responseCookies
	NSArray *cookies = [request responseCookies];
	STAssertNotNil(cookies,@"Failed to store cookie data in responseCookies");
	

	//Test the cookie contains the correct data
	NSHTTPCookie *cookie = nil;
	BOOL foundCookie = NO;
	for (cookie in cookies) {
		if ([[cookie name] isEqualToString:@"ASIHTTPRequestTestCookie"]) {
			foundCookie = YES;
			NSLog(@"%@",cookie);
			success = [[cookie decodedValue] isEqualToString:@"This is the value"];
			STAssertTrue(success,@"Failed to store the correct value for a cookie");
			success = [[cookie domain] isEqualToString:@".allseeing-i.com"];
			STAssertTrue(success,@"Failed to store the correct domain for a cookie");
			success = [[cookie path] isEqualToString:@"/asi-http-request/tests"];
			STAssertTrue(success,@"Failed to store the correct path for a cookie");
			break;
		}
	}
	STAssertTrue(foundCookie,@"Failed store a particular cookie - can't continue with the rest of the tests");
	
	if (!foundCookie) {
		return;
	}
	
	//Test a cookie is presented when manually added to the request
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/read_cookie"] autorelease];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseCookiePersistance:NO];
	[request setRequestCookies:[NSMutableArray arrayWithObject:cookie]];
	[request start];
	html = [request dataString];
	success = [html isEqualToString:@"I have 'This is the value' as the value of 'ASIHTTPRequestTestCookie'"];
	STAssertTrue(success,@"Cookie not presented to the server with cookie persistance OFF");

	//Test a cookie is presented from the persistent store
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/read_cookie"] autorelease];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseCookiePersistance:YES];
	[request start];
	html = [request dataString];
	success = [html isEqualToString:@"I have 'This is the value' as the value of 'ASIHTTPRequestTestCookie'"];
	STAssertTrue(success,@"Cookie not presented to the server with cookie persistance ON");
	
	//Test removing a cookie
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/remove_cookie"] autorelease];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request start];
	html = [request dataString];
	success = [html isEqualToString:@"I have removed a cookie"];
	STAssertTrue(success,@"Failed to remove a cookie");

	//Test making sure cookie was properly removed
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/read_cookie"] autorelease];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request start];
	html = [request dataString];
	success = [html isEqualToString:@"No cookie exists"];
	STAssertTrue(success,@"Cookie presented to the server when it should have been removed");
	
	//Test setting a custom cookie works
	NSDictionary *cookieProperties = [[[NSMutableDictionary alloc] init] autorelease];
	[cookieProperties setValue:@"Test Value" forKey:NSHTTPCookieValue];
	[cookieProperties setValue:@"ASIHTTPRequestTestCookie" forKey:NSHTTPCookieName];
	[cookieProperties setValue:@".allseeing-i.com" forKey:NSHTTPCookieDomain];
	[cookieProperties setValue:[NSDate dateWithTimeIntervalSinceNow:60*60*4] forKey:NSHTTPCookieExpires];
	[cookieProperties setValue:@"/asi-http-request/tests" forKey:NSHTTPCookiePath];
	cookie = [[[NSHTTPCookie alloc] initWithProperties:cookieProperties] autorelease];

	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/read_cookie"] autorelease];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseCookiePersistance:NO];
	[request setRequestCookies:[NSMutableArray arrayWithObject:cookie]];
	[request start];
	html = [request dataString];
	success = [html isEqualToString:@"I have 'Test Value' as the value of 'ASIHTTPRequestTestCookie'"];
	STAssertTrue(success,@"Custom cookie not presented to the server with cookie persistance OFF");
	
	//Test removing all cookies works
	[ASIHTTPRequest clearSession];

	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/read_cookie"] autorelease];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request start];
	html = [request dataString];
	success = [html isEqualToString:@"No cookie exists"];
	STAssertTrue(success,@"Cookie presented to the server when it should have been removed");
}

@end
