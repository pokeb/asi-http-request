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
#import "ASINetworkQueue.h"


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
	
	//Attempt to grab from bad url
	url = [[[NSURL alloc] initWithString:@""] autorelease];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request start];
	NSError *error = [request error];
	STAssertNotNil(error,@"Failed to generate an error for a bad host");
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


- (void)testRequestMethod
{
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASI-HTTP-Request/tests/request-method"] autorelease];
	NSArray *methods = [[[NSArray alloc] initWithObjects:@"GET",@"POST",@"PUT",@"DELETE"] autorelease];
	for (NSString *method in methods) {
		ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
		[request setRequestMethod:method];
		[request start];
		BOOL success = [[request dataString] isEqualToString:method];
		STAssertTrue(success,@"Failed to set the request method correctly");	
	}
}

- (void)testContentLength
{
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/i/logo.png"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request start];
	
	BOOL success = ([request contentLength] == 18443);
	STAssertTrue(success,@"Got wrong content length");
}

- (void)testFileDownload
{
	NSString *path = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"testfile"];
	
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/asi-http-request/tests/first"] autorelease];
	ASIHTTPRequest *request1 = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request1 setDownloadDestinationPath:path];
	[request1 start];
	
	BOOL success = [[NSString stringWithContentsOfURL:[NSURL fileURLWithPath:path]] isEqualToString:@"This is the expected content for the first string"];
	STAssertTrue(success,@"Failed to download data to a file");
}


- (void)testDownloadProgress
{
	progress = 0;
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/i/logo.png"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setDownloadProgressDelegate:self];
	[request start];
	BOOL success = (progress == 1);
	STAssertTrue(success,@"Failed to properly increment download progress");	
}


- (void)testUploadProgress
{
	progress = 0;
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://asi/ignore"]] autorelease];
	[request setPostBody:[NSMutableData dataWithLength:1024*32]];
	[request setUploadProgressDelegate:self];
	[request start];
	BOOL success = (progress == 1);
	STAssertTrue(success,@"Failed to properly increment upload progress");	
}


- (void)setProgress:(float)newProgress;
{
	progress = newProgress;
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
			success = [[cookie decodedValue] isEqualToString:@"This is the value"];
			STAssertTrue(success,@"Failed to store the correct value for a cookie");
			success = [[cookie domain] isEqualToString:@"allseeing-i.com"];
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
	[cookieProperties setValue:@"allseeing-i.com" forKey:NSHTTPCookieDomain];
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


- (void)testBasicAuthentication
{

	NSURL *url = [[[NSURL alloc] initWithString:@"http://asi/asi-http-request/tests/basic-authentication"] autorelease];
	ASIHTTPRequest *request;
	BOOL success;
	NSError *err;
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:NO];
	[request start];
	success = ([[[[request error] userInfo] objectForKey:@"Description"] isEqualToString:@"Your username and password were incorrect."]);
	STAssertTrue(success,@"Failed to generate permission denied error with no credentials");
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:NO];
	[request setUsername:@"wrong"];
	[request setPassword:@"wrong"];
	[request start];
	success = ([[[[request error] userInfo] objectForKey:@"Description"] isEqualToString:@"Your username and password were incorrect."]);
	STAssertTrue(success,@"Failed to generate permission denied error with wrong credentials");
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:YES];
	[request setUseKeychainPersistance:YES];
	[request setUsername:@"secret_username"];
	[request setPassword:@"secret_password"];
	[request start];
	err = [request error];
	STAssertNil(err,@"Failed to supply correct username and password");
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:NO];
	[request setUseKeychainPersistance:NO];
	[request start];
	success = ([[[[request error] userInfo] objectForKey:@"Description"] isEqualToString:@"Your username and password were incorrect."]);
	STAssertTrue(success,@"Reused credentials when we shouldn't have");

	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:YES];
	[request setUseKeychainPersistance:NO];
	[request start];
	err = [request error];
	STAssertNil(err,@"Failed to reuse credentials");
	
	[ASIHTTPRequest clearSession];
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:NO];
	[request start];
	success = ([[[[request error] userInfo] objectForKey:@"Description"] isEqualToString:@"Your username and password were incorrect."]);
	STAssertTrue(success,@"Failed to clear credentials");
	
	//This test may show a dialog!
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:YES];
	[request start];
	err = [request error];
	STAssertNil(err,@"Failed to use stored credentials");
}



- (void)testDigestAuthentication
{
	[ASIHTTPRequest clearSession];
	
	NSURL *url = [[[NSURL alloc] initWithString:@"http://asi/asi-http-request/tests/digest-authentication"] autorelease];
	ASIHTTPRequest *request;
	BOOL success;
	NSError *err;
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:NO];
	[request start];
	success = ([[[[request error] userInfo] objectForKey:@"Description"] isEqualToString:@"Your username and password were incorrect."]);
	STAssertTrue(success,@"Failed to generate permission denied error with no credentials");
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:NO];
	[request setUsername:@"wrong"];
	[request setPassword:@"wrong"];
	[request start];
	success = ([[[[request error] userInfo] objectForKey:@"Description"] isEqualToString:@"Your username and password were incorrect."]);
	STAssertTrue(success,@"Failed to generate permission denied error with wrong credentials");
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:YES];
	[request setUseKeychainPersistance:YES];
	[request setUsername:@"secret_username"];
	[request setPassword:@"secret_password"];
	[request start];
	err = [request error];
	STAssertNil(err,@"Failed to supply correct username and password");
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:NO];
	[request setUseKeychainPersistance:NO];
	[request start];
	success = ([[[[request error] userInfo] objectForKey:@"Description"] isEqualToString:@"Your username and password were incorrect."]);
	STAssertTrue(success,@"Reused credentials when we shouldn't have");
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:YES];
	[request setUseKeychainPersistance:NO];
	[request start];
	err = [request error];
	STAssertNil(err,@"Failed to reuse credentials");
	
	[ASIHTTPRequest clearSession];
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:NO];
	[request start];
	success = ([[[[request error] userInfo] objectForKey:@"Description"] isEqualToString:@"Your username and password were incorrect."]);
	STAssertTrue(success,@"Failed to clear credentials");

}



@end
