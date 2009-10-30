//
//  ASIHTTPRequestTests.m
//  asi-http-request
//
//  Created by Ben Copsey on 01/08/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import "ASIHTTPRequestTests.h"
#import "ASIHTTPRequest.h"
#import "ASINSStringAdditions.h"
#import "ASINetworkQueue.h"
#import "ASIFormDataRequest.h"
#import <SystemConfiguration/SystemConfiguration.h>

// Used for subclass test
@interface ASIHTTPRequestSubclass : ASIHTTPRequest {}
@end
@implementation ASIHTTPRequestSubclass;

// For testing exceptions are caught
- (void)loadRequest
{
	[[NSException exceptionWithName:@"Test Exception" reason:@"Test Reason" userInfo:nil] raise];
}
@end

@implementation ASIHTTPRequestTests

- (void)testBasicDownload
{
	NSURL *url = [NSURL URLWithString:@"http://allseeing-i.com"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request start];
	NSString *html = [request responseString];
	GHAssertNotNil(html,@"Basic synchronous request failed");

	// Check we're getting the correct response headers
	NSString *pingBackHeader = [[request responseHeaders] objectForKey:@"X-Pingback"];
	BOOL success = [pingBackHeader isEqualToString:@"http://allseeing-i.com/Ping-Back"];
	GHAssertTrue(success,@"Failed to populate response headers");
	
	// Check we're getting back the correct status code
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/a-page-that-does-not-exist"] autorelease];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request start];
	success = ([request responseStatusCode] == 404);
	GHAssertTrue(success,@"Didn't get correct status code");	
	
	// Check data is as expected
	NSRange notFound = NSMakeRange(NSNotFound, 0);
	success = !NSEqualRanges([html rangeOfString:@"All-Seeing Interactive"],notFound);
	GHAssertTrue(success,@"Failed to download the correct data");
	
	// Attempt to grab from bad url
	url = [[[NSURL alloc] initWithString:@""] autorelease];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request start];
	success = [[request error] code] == ASIInternalErrorWhileBuildingRequestType;
	GHAssertTrue(success,@"Failed to generate an error for a bad host");
	
	request = [[[ASIHTTPRequest alloc] initWithURL:nil] autorelease];
	[request start];
	success = [[request error] code] == ASIUnableToCreateRequestErrorType;
	GHAssertTrue(success,@"Failed to generate an error for a bad host");
}

- (void)testConditionalGET
{
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/i/logo.png"]];
	[request start];
	BOOL success = ([request responseStatusCode] == 200);
	GHAssertTrue(success, @"Failed to download file, cannot proceed with this test");
	success = ([[request responseData] length] > 0);
	GHAssertTrue(success, @"Response length is 0, this shouldn't happen");
	
	NSString *etag = [[request responseHeaders] objectForKey:@"Etag"];
	NSString *lastModified = [[request responseHeaders] objectForKey:@"Last-Modified"];
	
	GHAssertNotNil(etag, @"Response didn't return an etag");
	GHAssertNotNil(lastModified, @"Response didn't return a last modified date");
	
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/i/logo.png"]];
	[request addRequestHeader:@"If-Modified-Since" value:lastModified];
	[request addRequestHeader:@"If-None-Match" value:etag];
	[request start];
	success = ([request responseStatusCode] == 304);
	GHAssertTrue(success, @"Got wrong status code");
	success = ([[request responseData] length] == 0);
	GHAssertTrue(success, @"Response length is not 0, this shouldn't happen");
	
}

- (void)testException
{
	ASIHTTPRequestSubclass *request = [ASIHTTPRequestSubclass requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com"]];
	[request start];
	NSError *error = [request error];
	GHAssertNotNil(error,@"Failed to generate an error for an exception");
	
	BOOL success = [[[error userInfo] objectForKey:NSLocalizedDescriptionKey] isEqualToString:@"Test Exception"];
	GHAssertTrue(success, @"Generated wrong error for exception");
	
}

- (void)testCharacterEncoding
{
	
	NSArray *IANAEncodings = [NSArray arrayWithObjects:@"UTF-8",@"US-ASCII",@"ISO-8859-1",@"UTF-16",nil];
	NSUInteger NSStringEncodings[] = {NSUTF8StringEncoding,NSASCIIStringEncoding,NSISOLatin1StringEncoding,NSUnicodeStringEncoding};
	
	int i;
	for (i=0; i<[IANAEncodings count]; i++) {
		NSURL *url = [[[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://allseeing-i.com/ASIHTTPRequest/tests/Character-Encoding/%@",[IANAEncodings objectAtIndex:i]]] autorelease];
		ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
		[request start];
		BOOL success = [request responseEncoding] == NSStringEncodings[i];
		GHAssertTrue(success,[NSString stringWithFormat:@"Failed to use the correct text encoding for %@i",[IANAEncodings objectAtIndex:i]]);
	}
					 
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/Character-Encoding/Something-else"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setDefaultResponseEncoding:NSWindowsCP1251StringEncoding];
	[request start];
	BOOL success = [request responseEncoding] == [request defaultResponseEncoding];
	GHAssertTrue(success,[NSString stringWithFormat:@"Failed to use the default string encoding"]);
	
	// Will return a Content-Type header with charset in the middle of the value (Fix contributed by Roman Busyghin)
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/Character-Encoding/utf-16-with-type-header"] autorelease];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request start];
	success = [request responseEncoding] == NSUnicodeStringEncoding;
	GHAssertTrue(success,[NSString stringWithFormat:@"Failed to parse the content type header correctly"]);
}

- (void)testTimeOut
{
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setTimeOutSeconds:0.0001]; //It's pretty unlikely we will be able to grab the data this quickly, so the request should timeout
	[request start];
	
	BOOL success = [[request error] code] == ASIRequestTimedOutErrorType;
	GHAssertTrue(success,@"Timeout didn't generate the correct error");
}


// Test fix for a bug that might have caused timeouts when posting data
- (void)testTimeOutWithoutDownloadDelegate
{
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://trails-network.net/Downloads/MemexTrails_1.0b1.zip"]];
	[request setTimeOutSeconds:5];
	[request setShowAccurateProgress:NO];
	[request setPostBody:[NSMutableData dataWithData:[@"Small Body" dataUsingEncoding:NSUTF8StringEncoding]]];
	[request start];
	
	GHAssertNil([request error],@"Generated an error (most likely a timeout) - this test might fail on high latency connections");	
}


- (void)testRequestMethod
{
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/request-method"] autorelease];
	NSArray *methods = [[[NSArray alloc] initWithObjects:@"GET",@"POST",@"PUT",@"DELETE", nil] autorelease];
	for (NSString *method in methods) {
		ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
		[request setRequestMethod:method];
		[request start];
		BOOL success = [[request responseString] isEqualToString:method];
		GHAssertTrue(success,@"Failed to set the request method correctly");	
	}
	
	// Test to ensure we don't change the request method when we have an unrecognised method already set
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setRequestMethod:@"FINK"];
	[request appendPostData:[@"King" dataUsingEncoding:NSUTF8StringEncoding]];
	[request buildPostBody];
	BOOL success = [[request requestMethod] isEqualToString:@"FINK"];
	GHAssertTrue(success,@"Erroneously changed request method");	
}

- (void)testHTTPVersion
{
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/http-version"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request start];
	
	BOOL success = [[request responseString] isEqualToString:@"HTTP/1.1"];
	GHAssertTrue(success,@"Wrong HTTP version used (May fail when using a proxy that changes the HTTP version!)");
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseHTTPVersionOne:YES];
	[request start];
	
	success = [[request responseString] isEqualToString:@"HTTP/1.0"];
	GHAssertTrue(success,@"Wrong HTTP version used (May fail when using a proxy that changes the HTTP version!)");	
}

- (void)testUserAgent
{
	// defaultUserAgentString will be nil if we haven't set a Bundle Name or Bundle Display Name
	if ([ASIHTTPRequest defaultUserAgentString]) {
		
		// Returns the user agent it received in the response body
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/user-agent"]];
		[request start];
		BOOL success = [[request responseString] isEqualToString:[ASIHTTPRequest defaultUserAgentString]];
		GHAssertTrue(success,@"Failed to set the correct user agent");
	}
	
	// Now test specifying a custom user agent
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/user-agent"]];
	[request addRequestHeader:@"User-Agent" value:@"Ferdinand Fuzzworth's Magic Tent of Mystery"];
	[request start];
	BOOL success = [[request responseString] isEqualToString:@"Ferdinand Fuzzworth's Magic Tent of Mystery"];
	GHAssertTrue(success,@"Failed to set the correct user agent");
	
}

- (void)testAutomaticRedirection
{
	ASIHTTPRequest *request;
	BOOL success;
	int i;
	for (i=301; i<308; i++) {
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://allseeing-i.com/ASIHTTPRequest/tests/redirect/%hi",i]];
		request = [ASIHTTPRequest requestWithURL:url];
		[request setShouldRedirect:NO];
		[request start];
		if (i == 304) { // 304s will not contain a body, as per rfc2616. Will test 304 handling in a future test when we have etag support
			continue;
		}
		success = [[request responseString] isEqualToString:[NSString stringWithFormat:@"Non-redirected content with %hi status code",i]];
		GHAssertTrue(success,[NSString stringWithFormat:@"Got the wrong content when not redirecting after a %hi",i]);
	
		request = [ASIHTTPRequest requestWithURL:url];
		[request start];
		success = [[request responseString] isEqualToString:[NSString stringWithFormat:@"Redirected content after a %hi status code",i]];
		GHAssertTrue(success,[NSString stringWithFormat:@"Got the wrong content when redirecting after a %hi",i]);
	
		success = ([request responseStatusCode] == 200);
		GHAssertTrue(success,[NSString stringWithFormat:@"Got the wrong status code (expected %hi)",i]);

	}
}

- (void)testUploadContentLength
{
	//This url will return the contents of the Content-Length request header
	NSURL *url = [NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/content-length"];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setPostBody:[NSMutableData dataWithLength:1024*32]];
	[request start];
	
	BOOL success = ([[request responseString] isEqualToString:[NSString stringWithFormat:@"%hu",(1024*32)]]);
	GHAssertTrue(success,@"Sent wrong content length");
}

- (void)testDownloadContentLength
{
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/i/logo.png"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request start];
	
	BOOL success = ([request contentLength] == 18443);
	GHAssertTrue(success,@"Got wrong content length");
}

- (void)testFileDownload
{
	NSString *path = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"testimage.png"];
	
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/i/logo.png"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setDownloadDestinationPath:path];
	[request start];

#if TARGET_OS_IPHONE
	UIImage *image = [[[UIImage alloc] initWithContentsOfFile:path] autorelease];
#else
	NSImage *image = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];	
#endif
	
	GHAssertNotNil(image,@"Failed to download data to a file");
}


- (void)testCompressedResponseDownloadToFile
{
	NSString *path = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"testfile"];
	
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/first"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setDownloadDestinationPath:path];
	[request start];
	
	NSString *tempPath = [request temporaryFileDownloadPath];
	GHAssertNil(tempPath,@"Failed to clean up temporary download file");		
	
	//BOOL success = (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]);
	//GHAssertTrue(success,@"Failed to remove file from temporary location");	
	
	BOOL success = [[NSString stringWithContentsOfURL:[NSURL fileURLWithPath:path] encoding:NSUTF8StringEncoding error:NULL] isEqualToString:@"This is the expected content for the first string"];
	GHAssertTrue(success,@"Failed to download data to a file");
	
}


- (void)testDownloadProgress
{
	progress = 0;
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/i/logo.png"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setDownloadProgressDelegate:self];
	[request start];
	
	// Wait for the progress to catch up
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	
	BOOL success = (progress > 0.95);
	GHAssertTrue(success,@"Failed to properly increment download progress %f != 1.0",progress);	
}


- (void)testUploadProgress
{
	progress = 0;
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ignore"]] autorelease];
	[request setPostBody:(NSMutableData *)[@"This is the request body" dataUsingEncoding:NSUTF8StringEncoding]];
	[request setUploadProgressDelegate:self];
	[request start];
	
	// Wait for the progress to catch up
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	
	BOOL success = (progress > 0.95);
	GHAssertTrue(success,@"Failed to properly increment upload progress %f != 1.0",progress);	
}

- (void)testPostBodyStreamedFromDisk
{
	NSURL *url = [NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/print_request_body"];
	NSString *requestBody = @"This is the request body";
	NSString *requestContentPath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"testfile.txt"];
	[[requestBody dataUsingEncoding:NSUTF8StringEncoding] writeToFile:requestContentPath atomically:NO];

	
	// Test using a user-specified file as the request body (useful for PUT)
	progress = 0;
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setRequestMethod:@"PUT"];
	[request setShouldStreamPostDataFromDisk:YES];
	[request setUploadProgressDelegate:self];
	[request setPostBodyFilePath:requestContentPath];
	[request start];
	
	// Wait for the progress to catch up
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	
	BOOL success = (progress > 0.95);
	GHAssertTrue(success,@"Failed to properly increment upload progress %f != 1.0",progress);
	
	success = [[request responseString] isEqualToString:requestBody];
	GHAssertTrue(success,@"Failed upload the correct request body");
	
	
	// Test building a request body by appending data
	progress = 0;
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setShouldStreamPostDataFromDisk:YES];
	[request setRequestMethod:@"PUT"];
	[request setUploadProgressDelegate:self];
	[request appendPostDataFromFile:requestContentPath];
	[request start];
	
	// Wait for the progress to catch up
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	
	success = (progress > 0.95);
	GHAssertTrue(success,@"Failed to properly increment upload progress %f != 1.0",progress);
	
	success = [[request responseString] isEqualToString:requestBody];
	GHAssertTrue(success,@"Failed upload the correct request body");
}




- (void)testCookies
{
	BOOL success;
	
	// Set setting a cookie
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/set_cookie"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseCookiePersistance:YES];
	[request start];
	NSString *html = [request responseString];
	success = [html isEqualToString:@"I have set a cookie"];
	GHAssertTrue(success,@"Failed to set a cookie");
	
	// Test a cookie is stored in responseCookies
	NSArray *cookies = [request responseCookies];
	GHAssertNotNil(cookies,@"Failed to store cookie data in responseCookies");
	

	// Test the cookie contains the correct data
	NSHTTPCookie *cookie = nil;
	BOOL foundCookie = NO;
	for (cookie in cookies) {
		if ([[cookie name] isEqualToString:@"ASIHTTPRequestTestCookie"]) {
			foundCookie = YES;
			success = [[[cookie value] decodedCookieValue] isEqualToString:@"This is the value"];
			GHAssertTrue(success,@"Failed to store the correct value for a cookie");
			success = [[cookie domain] isEqualToString:@"allseeing-i.com"];
			GHAssertTrue(success,@"Failed to store the correct domain for a cookie");
			success = [[cookie path] isEqualToString:@"/ASIHTTPRequest/tests"];
			GHAssertTrue(success,@"Failed to store the correct path for a cookie");
			break;
		}
	}
	GHAssertTrue(foundCookie,@"Failed store a particular cookie - can't continue with the rest of the tests");
	
	if (!foundCookie) {
		return;
	}
	// Test a cookie is presented when manually added to the request
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/read_cookie"] autorelease];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseCookiePersistance:NO];
	[request setRequestCookies:[NSMutableArray arrayWithObject:cookie]];
	[request start];
	html = [request responseString];
	success = [html isEqualToString:@"I have 'This is the value' as the value of 'ASIHTTPRequestTestCookie'"];
	GHAssertTrue(success,@"Cookie not presented to the server with cookie persistance OFF");

	// Test a cookie is presented from the persistent store
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/read_cookie"] autorelease];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseCookiePersistance:YES];
	[request start];
	html = [request responseString];
	success = [html isEqualToString:@"I have 'This is the value' as the value of 'ASIHTTPRequestTestCookie'"];
	GHAssertTrue(success,@"Cookie not presented to the server with cookie persistance ON");
	
	// Test removing a cookie
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/remove_cookie"] autorelease];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request start];
	html = [request responseString];
	success = [html isEqualToString:@"I have removed a cookie"];
	GHAssertTrue(success,@"Failed to remove a cookie");

	// Test making sure cookie was properly removed
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/read_cookie"] autorelease];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request start];
	html = [request responseString];
	success = [html isEqualToString:@"No cookie exists"];
	GHAssertTrue(success,@"Cookie presented to the server when it should have been removed");
	
	// Test setting a custom cookie works
	NSDictionary *cookieProperties = [[[NSMutableDictionary alloc] init] autorelease];
	
	// We'll add a line break to our cookie value to test it gets correctly encoded
	[cookieProperties setValue:[@"Test\r\nValue" encodedCookieValue] forKey:NSHTTPCookieValue];
	[cookieProperties setValue:@"ASIHTTPRequestTestCookie" forKey:NSHTTPCookieName];
	[cookieProperties setValue:@"allseeing-i.com" forKey:NSHTTPCookieDomain];
	[cookieProperties setValue:[NSDate dateWithTimeIntervalSinceNow:60*60*4] forKey:NSHTTPCookieExpires];
	[cookieProperties setValue:@"/ASIHTTPRequest/tests" forKey:NSHTTPCookiePath];
	cookie = [[[NSHTTPCookie alloc] initWithProperties:cookieProperties] autorelease];
	
	GHAssertNotNil(cookie,@"Failed to create a cookie - cookie value was not correctly encoded?");

	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/read_cookie"] autorelease];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseCookiePersistance:NO];
	[request setRequestCookies:[NSMutableArray arrayWithObject:cookie]];
	[request start];
	html = [request responseString];
	success = [html isEqualToString:@"I have 'Test\r\nValue' as the value of 'ASIHTTPRequestTestCookie'"];
	GHAssertTrue(success,@"Custom cookie not presented to the server with cookie persistance OFF");
	

	// Test removing all cookies works
	[ASIHTTPRequest clearSession];
	NSArray *sessionCookies = [ASIHTTPRequest sessionCookies];
	success = ([sessionCookies count] == 0);
	GHAssertTrue(success,@"Cookies not removed");

	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/read_cookie"] autorelease];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseCookiePersistance:YES];
	[request start];
	html = [request responseString];
	success = [html isEqualToString:@"No cookie exists"];
	GHAssertTrue(success,@"Cookie presented to the server when it should have been removed");
}

// Test fix for a crash if you tried to remove credentials that didn't exist
- (void)testRemoveCredentialsFromKeychain
{
	[ASIHTTPRequest removeCredentialsForHost:@"apple.com" port:0 protocol:@"http" realm:@"Nothing to see here"];
	[ASIHTTPRequest removeCredentialsForProxy:@"apple.com" port:0 realm:@"Nothing to see here"];
	
}


- (void)testBasicAuthentication
{
	[ASIHTTPRequest removeCredentialsForHost:@"allseeing-i.com" port:0 protocol:@"http" realm:@"SECRET_STUFF"];
	[ASIHTTPRequest clearSession];

	NSURL *url = [NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/basic-authentication"];
	ASIHTTPRequest *request;
	BOOL success;
	NSError *err;
	
	// Test authentication needed when no credentials supplied
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:NO];
	[request start];
	success = [[request error] code] == ASIAuthenticationErrorType;
	GHAssertTrue(success,@"Failed to generate permission denied error with no credentials");
	
	// Test wrong credentials supplied
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:NO];
	[request setUsername:@"wrong"];
	[request setPassword:@"wrong"];
	[request start];
	success = [[request error] code] == ASIAuthenticationErrorType;
	GHAssertTrue(success,@"Failed to generate permission denied error with wrong credentials");
	
	// Test correct credentials supplied
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:YES];
	[request setUseKeychainPersistance:YES];
	[request setShouldPresentCredentialsBeforeChallenge:NO];
	[request setUsername:@"secret_username"];
	[request setPassword:@"secret_password"];
	[request start];
	err = [request error];
	GHAssertNil(err,@"Failed to supply correct username and password");
	
	// Ensure credentials are not reused
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:NO];
	[request setUseKeychainPersistance:NO];
	[request start];
	success = [[request error] code] == ASIAuthenticationErrorType;
	GHAssertTrue(success,@"Reused credentials when we shouldn't have");

	// Ensure credentials stored in the session are reused
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:YES];
	[request setUseKeychainPersistance:NO];
	[request start];
	err = [request error];
	GHAssertNil(err,@"Failed to reuse credentials");
	
	[ASIHTTPRequest clearSession];
	
	// Ensure credentials stored in the session were wiped
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:NO];
	[request start];
	success = [[request error] code] == ASIAuthenticationErrorType;
	GHAssertTrue(success,@"Failed to clear credentials");
	
	// Ensure credentials stored in the keychain are reused
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:YES];
	[request start];
	err = [request error];
	GHAssertNil(err,@"Failed to use stored credentials");
	
	[ASIHTTPRequest removeCredentialsForHost:@"allseeing-i.com" port:0 protocol:@"http" realm:@"SECRET_STUFF"];
	
	// Ensure credentials stored in the keychain were wiped
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:YES];
	[request setUseSessionPersistance:NO];
	[request start];
	success = [[request error] code] == ASIAuthenticationErrorType;
	GHAssertTrue(success,@"Failed to clear credentials");
	
	// Tests shouldPresentCredentialsBeforeChallenge with credentials stored in the session
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:YES];
	[request start];
	success = [request authenticationRetryCount] == 0;
	GHAssertTrue(success,@"Didn't supply credentials before being asked for them when talking to the same server with shouldPresentCredentialsBeforeChallenge == YES");	
	
	// Ensure credentials stored in the session were not presented to the server before it asked for them
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:YES];
	[request setShouldPresentCredentialsBeforeChallenge:NO];
	[request start];
	success = [request authenticationRetryCount] == 1;
	GHAssertTrue(success,@"Supplied session credentials before being asked for them");	
	
	[ASIHTTPRequest clearSession];
	
	// Test credentials set on the request are sent before the server asks for them
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:NO];
	[request setUsername:@"secret_username"];
	[request setPassword:@"secret_password"];
	[request setShouldPresentCredentialsBeforeChallenge:YES];
	[request start];
	success = [request authenticationRetryCount] == 0;
	GHAssertTrue(success,@"Didn't supply credentials before being asked for them, even though they were set on the request and shouldPresentCredentialsBeforeChallenge == YES");	
	
	// Test credentials set on the request aren't sent before the server asks for them
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:NO];
	[request setUsername:@"secret_username"];
	[request setPassword:@"secret_password"];
	[request setShouldPresentCredentialsBeforeChallenge:NO];
	[request start];
	success = [request authenticationRetryCount] == 1;
	GHAssertTrue(success,@"Supplied request credentials before being asked for them");	
	
	
	// Test credentials presented before a challenge are stored in the session store
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUsername:@"secret_username"];
	[request setPassword:@"secret_password"];
	[request setShouldPresentCredentialsBeforeChallenge:YES];
	[request start];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request start];
	err = [request error];
	GHAssertNil(err,@"Failed to use stored credentials");	
	
	
	// Ok, now let's test on a different server to sanity check that the credentials from out previous requests are not being used
	url = [NSURL URLWithString:@"https://selfsigned.allseeing-i.com/ASIHTTPRequest/tests/basic-authentication"];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:YES];
	[request setUseKeychainPersistance:NO];
	[request setValidatesSecureCertificate:NO];
	[request start];
	success = [[request error] code] == ASIAuthenticationErrorType;
	GHAssertTrue(success,@"Reused credentials when we shouldn't have");	
	
}



- (void)testDigestAuthentication
{
	[ASIHTTPRequest removeCredentialsForHost:@"allseeing-i.com" port:0 protocol:@"http" realm:@"Keep out"];
	[ASIHTTPRequest clearSession];
	
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/digest-authentication"] autorelease];
	ASIHTTPRequest *request;
	BOOL success;
	NSError *err;
	
	// Test authentication needed when no credentials supplied
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:NO];
	[request start];
	success = [[request error] code] == ASIAuthenticationErrorType;
	GHAssertTrue(success,@"Failed to generate permission denied error with no credentials");
	
	// Test wrong credentials supplied
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:NO];
	[request setUsername:@"wrong"];
	[request setPassword:@"wrong"];
	[request start];
	success = [[request error] code] == ASIAuthenticationErrorType;
	GHAssertTrue(success,@"Failed to generate permission denied error with wrong credentials");
	
	// Test correct credentials supplied
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:YES];
	[request setUseKeychainPersistance:YES];
	[request setUsername:@"secret_username"];
	[request setPassword:@"secret_password"];
	[request start];
	err = [request error];
	GHAssertNil(err,@"Failed to supply correct username and password");
	
	// Ensure credentials are not reused
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:NO];
	[request setUseKeychainPersistance:NO];
	[request start];
	success = [[request error] code] == ASIAuthenticationErrorType;
	GHAssertTrue(success,@"Reused credentials when we shouldn't have");
	
	// Ensure credentials stored in the session are reused
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:YES];
	[request setUseKeychainPersistance:NO];
	[request start];
	err = [request error];
	GHAssertNil(err,@"Failed to reuse credentials");
	
	[ASIHTTPRequest clearSession];
	
	// Ensure credentials stored in the session were wiped
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:NO];
	[request start];
	success = [[request error] code] == ASIAuthenticationErrorType;
	GHAssertTrue(success,@"Failed to clear credentials");
	
	// Ensure credentials stored in the keychain are reused
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:YES];
	[request start];
	err = [request error];
	GHAssertNil(err,@"Failed to reuse credentials");
	
	[ASIHTTPRequest removeCredentialsForHost:@"allseeing-i.com" port:0 protocol:@"http" realm:@"Keep out"];
	
	// Ensure credentials stored in the keychain were wiped
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:YES];
	[request setUseSessionPersistance:NO];
	[request start];
	success = [[request error] code] == ASIAuthenticationErrorType;
	GHAssertTrue(success,@"Failed to clear credentials");	
	
	
	// Test credentials set on the request are sent before the server asks for them
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:YES];
	[request setShouldPresentCredentialsBeforeChallenge:YES];
	[request start];
	success = [request authenticationRetryCount] == 0;
	GHAssertTrue(success,@"Didn't supply credentials before being asked for them, even though they were set in the session and shouldPresentCredentialsBeforeChallenge == YES");	
	
}

- (void)testNTLMHandshake
{
	// This test connects to a script that masquerades as an NTLM server
	// It tests that the handshake seems sane, but doesn't actually authenticate
	
	[ASIHTTPRequest clearSession];
	
	NSURL *url = [NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/pretend-ntlm-handshake"];
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setUseKeychainPersistance:NO];
	[request setUseSessionPersistance:NO];
	[request start];
	BOOL success = [[request error] code] == ASIAuthenticationErrorType;
	GHAssertTrue(success,@"Failed to generate permission denied error with no credentials");


	request = [ASIHTTPRequest requestWithURL:url];
	[request setUseSessionPersistance:YES];
	[request setUseKeychainPersistance:NO];
	[request setUsername:@"king"];
	[request setPassword:@"fink"];
	[request setDomain:@"Castle.Kingdom"];
	[request start];

	GHAssertNil([request error],@"Got an error when credentials were supplied");
	
	// NSProcessInfo returns a lower case string for host name, while CFNetwork will send a mixed case string for host name, so we'll compare by lowercasing everything
	NSString *hostName = [[NSProcessInfo processInfo] hostName];
	NSString *expectedResponse = [[NSString stringWithFormat:@"You are %@ from %@/%@",@"king",@"Castle.Kingdom",hostName] lowercaseString];
	success = [[[request responseString] lowercaseString] isEqualToString:expectedResponse];
	GHAssertTrue(success,@"Failed to send credentials correctly? (Expected: '%@', got '%@')",expectedResponse,[[request responseString] lowercaseString]);
}

- (void)testCompressedResponse
{
	// allseeing-i.com does not gzip png images
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/i/logo.png"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request start];
	NSString *encoding = [[request responseHeaders] objectForKey:@"Content-Encoding"];
	BOOL success = (!encoding || [encoding rangeOfString:@"gzip"].location != NSNotFound);
	GHAssertTrue(success,@"Got incorrect request headers from server");
	
	success = ([request rawResponseData] == [request responseData]);
	GHAssertTrue(success,@"Attempted to uncompress data that was not compressed");	
	
	url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/first"] autorelease];
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request start];
	success = ([request rawResponseData] != [request responseData]);
	GHAssertTrue(success,@"Uncompressed data is the same as compressed data");	
	
	success = [[request responseString] isEqualToString:@"This is the expected content for the first string"];
	GHAssertTrue(success,@"Failed to decompress data correctly?");
}


- (void)testPartialFetch
{
	NSString *downloadPath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"testfile.txt"];
	NSString *tempPath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"tempfile.txt"];
	NSString *partialContent = @"This file should be exactly 163 bytes long when encoded as UTF8, Unix line breaks with no BOM.\n";
	[partialContent writeToFile:tempPath atomically:NO encoding:NSASCIIStringEncoding error:nil];
	
	progress = 0;
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/test_partial_download.txt"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setDownloadDestinationPath:downloadPath];
	[request setTemporaryFileDownloadPath:tempPath];
	[request setAllowResumeForFileDownloads:YES];
	[request setDownloadProgressDelegate:self];
	[request start];
	

	
	BOOL success = ([request contentLength] == 68);
	GHAssertTrue(success,@"Failed to download a segment of the data");
	
	NSString *content = [NSString stringWithContentsOfFile:downloadPath encoding:NSUTF8StringEncoding error:NULL];
	
	NSString *newPartialContent = [content substringFromIndex:95];
	success = ([newPartialContent isEqualToString:@"This is the content we ought to be getting if we start from byte 95."]);
	GHAssertTrue(success,@"Failed to append the correct data to the end of the file?");

	// Wait for the progress to catch up
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	
	success = (progress > 0.95);
	GHAssertTrue(success,@"Failed to correctly display increment progress for a partial download");
}

// The '000' is to ensure this test runs first, as another test may connect to https://selfsigned.allseeing-i.com and accept the certificate
- (void)test000SSL
{
	NSURL *url = [NSURL URLWithString:@"https://selfsigned.allseeing-i.com"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request start];
	
	GHAssertNotNil([request error],@"Failed to generate an error for a self-signed certificate (Will fail on the second run in the same session!)");		
	
	// Just for testing the request generated a custom error description - don't do this! You should look at the domain / code of the underlyingError in your own programs.
	BOOL success = ([[[request error] localizedDescription] isEqualToString:@"A connection failure occurred: SSL problem (possibily a bad/expired/self-signed certificate)"]);
	GHAssertTrue(success,@"Generated the wrong error for a self signed cert");
	
	// Turn off certificate validation, and try again
	request = [ASIHTTPRequest requestWithURL:url];
	[request setValidatesSecureCertificate:NO];
	[request start];
	
	GHAssertNil([request error],@"Failed to accept a self-signed certificate");	
}

- (void)testRedirectPreservesSession
{
	// Remove any old session cookies
	[ASIHTTPRequest clearSession];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/session_redirect"]];
	[request start];
	BOOL success = [[request responseString] isEqualToString:@"Take me to your leader"];
	GHAssertTrue(success,@"Failed to redirect preserving session cookies");	
}

- (void)testTooMuchRedirection
{
	// This url will simply send a 302 redirect back to itself
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/one_infinite_loop"]];
	[request start];
	GHAssertNotNil([request error],@"Failed to generate an error when redirection occurs too many times");
	BOOL success = ([[request error] code] == ASITooMuchRedirectionErrorType);
	GHAssertTrue(success,@"Generated the wrong error for a redirection loop");		
}

- (void)testRedirectToNewDomain
{
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/redirect_to_new_domain"]];
	[request start];
	BOOL success = [[[request url] absoluteString] isEqualToString:@"http://www.apple.com/"];
	GHAssertTrue(success,@"Failed to redirect to a different domain");		
}

// Ensure request method changes to get
- (void)test303Redirect
{
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/redirect_303"]];
	[request setRequestMethod:@"PUT"];
	[request appendPostData:[@"Fuzzy" dataUsingEncoding:NSUTF8StringEncoding]];
	[request start];
	BOOL success = [[[request url] absoluteString] isEqualToString:@"http://allseeing-i.com/ASIHTTPRequest/tests/request-method"];
	GHAssertTrue(success,@"Failed to redirect to correct location");
	success = [[request responseString] isEqualToString:@"GET"];
	GHAssertTrue(success,@"Failed to use GET on new URL");
}

- (void)testCompression
{
	NSString *content = @"This is the test content. This is the test content. This is the test content. This is the test content.";
	
	// Test in memory compression / decompression
	NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
	NSData *compressedData = [ASIHTTPRequest compressData:data];
	NSData *uncompressedData = [ASIHTTPRequest uncompressZippedData:compressedData];
	NSString *newContent = [[[NSString alloc] initWithBytes:[uncompressedData bytes] length:[uncompressedData length] encoding:NSUTF8StringEncoding] autorelease];
	
	BOOL success = [newContent isEqualToString:content];
	GHAssertTrue(success,@"Failed compress or decompress the correct data");	
	
	// Test file to file compression / decompression
	
	NSString *basePath = [self filePathForTemporaryTestFiles];
	NSString *sourcePath = [basePath stringByAppendingPathComponent:@"text.txt"];
	NSString *destPath = [basePath stringByAppendingPathComponent:@"text.txt.compressed"];
	NSString *newPath = [basePath stringByAppendingPathComponent:@"text2.txt"];
	
	[content writeToFile:sourcePath atomically:NO encoding:NSUTF8StringEncoding error:NULL];
	[ASIHTTPRequest compressDataFromFile:sourcePath toFile:destPath];
	[ASIHTTPRequest uncompressZippedDataFromFile:destPath toFile:newPath];
	success = [[NSString stringWithContentsOfFile:newPath encoding:NSUTF8StringEncoding error:NULL] isEqualToString:content];
	GHAssertTrue(success,@"Failed compress or decompress the correct data");
	
	// Test compressed body
	// Body is deflated by ASIHTTPRequest, sent, inflated by the server, printed, deflated by mod_deflate, response is inflated by ASIHTTPRequest
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/compressed_post_body"]];
	[request setRequestMethod:@"PUT"];
	[request setShouldCompressRequestBody:YES];
	[request appendPostData:data];
	[request start];
	
	success = [[request responseString] isEqualToString:content];
	GHAssertTrue(success,@"Failed to compress the body, or server failed to decompress it");	
	
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/compressed_post_body"]];
	[request setRequestMethod:@"PUT"];
	[request setShouldCompressRequestBody:YES];
	[request setShouldStreamPostDataFromDisk:YES];
	[request setUploadProgressDelegate:self];
	[request setPostBodyFilePath:sourcePath];
	[request start];

	success = [[request responseString] isEqualToString:content];
	GHAssertTrue(success,@"Failed to compress the body, or server failed to decompress it");		
	
}


// Ensure class convenience constructor returns an instance of our subclass
- (void)testSubclass
{
	ASIHTTPRequestSubclass *instance = [ASIHTTPRequestSubclass requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com"]];
	BOOL success = [instance isKindOfClass:[ASIHTTPRequestSubclass class]];
	GHAssertTrue(success,@"Convenience constructor failed to return an instance of the correct class");	
}


- (void)testThrottlingDownloadBandwidth
{
	[ASIHTTPRequest setMaxBandwidthPerSecond:0];
	
	// This content is around 128KB in size, and it won't be gzipped, so it should take more than 8 seconds to download at 14.5KB / second
	// We'll test first without throttling
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/the_great_american_novel_%28abridged%29.txt"]];
	NSDate *date = [NSDate date];
	[request start];	
	
	NSTimeInterval interval =[date timeIntervalSinceNow];
	BOOL success = (interval > -7);
	GHAssertTrue(success,@"Downloaded the file too slowly - either this is a bug, or your internet connection is too slow to run this test (must be able to download 128KB in less than 7 seconds, without throttling)");
	
	// Now we'll test with throttling
	[ASIHTTPRequest setMaxBandwidthPerSecond:ASIWWANBandwidthThrottleAmount];
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/the_great_american_novel_%28abridged%29.txt"]];
	date = [NSDate date];
	[request start];	
	
	[ASIHTTPRequest setMaxBandwidthPerSecond:0];
	
	interval =[date timeIntervalSinceNow];
	success = (interval < -7);
	GHAssertTrue(success,@"Failed to throttle download");		
	GHAssertNil([request error],@"Request generated an error - timeout?");	
	
}

- (void)testThrottlingUploadBandwidth
{
	[ASIHTTPRequest setMaxBandwidthPerSecond:0];
	
	// Create a 64KB request body
	NSData *data = [[[NSMutableData alloc] initWithLength:64*1024] autorelease];
	
	// We'll test first without throttling
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ignore"]];
	[request appendPostData:data];
	NSDate *date = [NSDate date];
	[request start];	
	
	NSTimeInterval interval =[date timeIntervalSinceNow];
	BOOL success = (interval > -3);
	GHAssertTrue(success,@"Uploaded the data too slowly - either this is a bug, or your internet connection is too slow to run this test (must be able to upload 64KB in less than 3 seconds, without throttling)");
	
	// Now we'll test with throttling
	[ASIHTTPRequest setMaxBandwidthPerSecond:ASIWWANBandwidthThrottleAmount];
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ignore"]];
	[request appendPostData:data];
	date = [NSDate date];
	[request start];	
	
	[ASIHTTPRequest setMaxBandwidthPerSecond:0];
	
	interval =[date timeIntervalSinceNow];
	success = (interval < -3);
	GHAssertTrue(success,@"Failed to throttle upload");		
	GHAssertNil([request error],@"Request generated an error - timeout?");	
	
}

- (void)authenticationNeededForRequest:(ASIHTTPRequest *)request
{
	GHAssertTrue(NO,@"Delegate asked for authentication when running on the main thread");
}

- (void)testMainThreadDelegateAuthenticationFailure
{
	[ASIHTTPRequest clearSession];
	//GHUnit will not run this function on the main thread, so we'll need to move it there
	[self performSelectorOnMainThread:@selector(fetchOnMainThread) withObject:nil waitUntilDone:YES];
		
}

- (void)fetchOnMainThread
{
	// Ensure the delegate is not called when we are running on the main thread
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/basic-authentication"]];
	[request setDelegate:self];
	[request start];
	GHAssertNotNil([request error],@"Failed to generate an authentication error");		
}

- (void)testFetchToInvalidPath
{
	// Test gzipped content
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL	URLWithString:@"http://allseeing-i.com"]];
	[request setDownloadDestinationPath:@"/an/invalid/location.html"];
	[request start];
	GHAssertNotNil([request error],@"Failed to generate an authentication when attempting to write to an invalid location");	
	
	//Test non-gzipped content
	request = [ASIHTTPRequest requestWithURL:[NSURL	URLWithString:@"http://allseeing-i.com/i/logo.png"]];
	[request setDownloadDestinationPath:@"/an/invalid/location.png"];
	[request start];
	GHAssertNotNil([request error],@"Failed to generate an authentication when attempting to write to an invalid location");		
}

- (void)testResponseStatusMessage
{
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL	URLWithString:@"http://allseeing-i.com/the-meaning-of-life"]];
	[request start];	
	BOOL success = [[request responseStatusMessage] isEqualToString:@"HTTP/1.0 404 Not Found"];
	GHAssertTrue(success,@"Got wrong response status message");
}

- (void)testAsynchronousWithGlobalQueue
{
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/first"]];
	[request setUserInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"RequestNumber"]];
	[request setDidFailSelector:@selector(asyncFail:)];
	[request setDidFinishSelector:@selector(asyncSuccess:)];
	[request setDelegate:self];
	[request startAsynchronous];
	
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/second"]];
	[request setUserInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:2] forKey:@"RequestNumber"]];
	[request setDidFailSelector:@selector(asyncFail:)];
	[request setDidFinishSelector:@selector(asyncSuccess:)];
	[request setDelegate:self];
	[request startAsynchronous];
	
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/third"]];
	[request setUserInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:3] forKey:@"RequestNumber"]];
	[request setDidFailSelector:@selector(asyncFail:)];
	[request setDidFinishSelector:@selector(asyncSuccess:)];
	[request setDelegate:self];
	[request startAsynchronous];	
	
	request = [ASIHTTPRequest requestWithURL:nil];
	[request setUserInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:4] forKey:@"RequestNumber"]];
	[request setDidFailSelector:@selector(asyncFail:)];
	[request setDidFinishSelector:@selector(asyncSuccess:)];
	[request setDelegate:self];
	[request startAsynchronous];	
}


- (void)asyncFail:(ASIHTTPRequest *)request
{
	int requestNumber = [[[request userInfo] objectForKey:@"RequestNumber"] intValue];
	GHAssertEquals(requestNumber,4,@"Wrong request failed");	
}

- (void)asyncSuccess:(ASIHTTPRequest *)request
{
	int requestNumber = [[[request userInfo] objectForKey:@"RequestNumber"] intValue];
	GHAssertNotEquals(requestNumber,4,@"Request succeeded when it should have failed");
	
	BOOL success;
	switch (requestNumber) {
		case 1:
			success = [[request responseString] isEqualToString:@"This is the expected content for the first string"];
			break;
		case 2:
			success = [[request responseString] isEqualToString:@"This is the expected content for the second string"];
			break;
		case 3:
			success = [[request responseString] isEqualToString:@"This is the expected content for the third string"];
			break;
	}
	GHAssertTrue(success,@"Got wrong request content - very bad!");
	
}

- (void)setProgress:(float)newProgress;
{
	progress = newProgress;
}

@end