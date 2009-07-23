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

// Used for subclass test
@interface ASIHTTPRequestSubclass : ASIHTTPRequest {}
@end
@implementation ASIHTTPRequestSubclass;
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
}

- (void)testHTTPVersion
{
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/http-version"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request start];
	
	BOOL success = [[request responseString] isEqualToString:@"HTTP/1.1"];
	GHAssertTrue(success,@"Wrong HTTP version used");
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseHTTPVersionOne:YES];
	[request start];
	
	success = [[request responseString] isEqualToString:@"HTTP/1.0"];
	GHAssertTrue(success,@"Wrong HTTP version used");	
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
	NSString *path = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"testimage.png"];
	
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/i/logo.png"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setDownloadDestinationPath:path];
	[request start];
	
	NSString *tempPath = [request temporaryFileDownloadPath];
	GHAssertNotNil(tempPath,@"Failed to download file to temporary location");		
	
	BOOL success = (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]);
	GHAssertTrue(success,@"Failed to remove file from temporary location");	
	
#if TARGET_OS_IPHONE
	UIImage *image = [[[UIImage alloc] initWithContentsOfFile:path] autorelease];
#else
	NSImage *image = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];	
#endif
	
	GHAssertNotNil(image,@"Failed to download data to a file");
}

- (void)testCompressedResponseDownloadToFile
{
	NSString *path = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"testfile"];
	
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/first"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setDownloadDestinationPath:path];
	[request start];
	
	NSString *tempPath = [request temporaryFileDownloadPath];
	GHAssertNil(tempPath,@"Failed to clean up temporary download file");		
	
	//BOOL success = (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]);
	//GHAssertTrue(success,@"Failed to remove file from temporary location");	
	
	BOOL success = [[NSString stringWithContentsOfURL:[NSURL fileURLWithPath:path]] isEqualToString:@"This is the expected content for the first string"];
	GHAssertTrue(success,@"Failed to download data to a file");
	
}


- (void)testDownloadProgress
{
	progress = 0;
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/i/logo.png"] autorelease];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setDownloadProgressDelegate:self];
	[request start];
	
	BOOL success = (progress > 0.95);
	GHAssertTrue(success,@"Failed to properly increment download progress %f != 1.0",progress);	
}




- (void)setProgress:(float)newProgress;
{
	progress = newProgress;
}


- (void)testUploadProgress
{
	progress = 0;
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ignore"]] autorelease];
	[request setPostBody:(NSMutableData *)[@"This is the request body" dataUsingEncoding:NSUTF8StringEncoding]];
	[request setUploadProgressDelegate:self];
	[request start];
	
	BOOL success = (progress > 0.95);
	GHAssertTrue(success,@"Failed to properly increment upload progress %f != 1.0",progress);	
}

- (void)testPostBodyStreamedFromDisk
{
	NSURL *url = [NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/print_request_body"];
	NSString *requestBody = @"This is the request body";
	NSString *requestContentPath = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"testfile.txt"];
	[[requestBody dataUsingEncoding:NSUTF8StringEncoding] writeToFile:requestContentPath atomically:NO];

	
	// Test using a user-specified file as the request body (useful for PUT)
	progress = 0;
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setRequestMethod:@"PUT"];
	[request setShouldStreamPostDataFromDisk:YES];
	[request setUploadProgressDelegate:self];
	[request setPostBodyFilePath:requestContentPath];
	[request start];
	
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


- (void)testBasicAuthentication
{

	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/basic-authentication"] autorelease];
	ASIHTTPRequest *request;
	BOOL success;
	NSError *err;
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:NO];
	[request start];
	
	success = [[request error] code] == ASIAuthenticationErrorType;
	GHAssertTrue(success,@"Failed to generate permission denied error with no credentials");
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:NO];
	[request setUsername:@"wrong"];
	[request setPassword:@"wrong"];
	[request start];
	success = [[request error] code] == ASIAuthenticationErrorType;
	GHAssertTrue(success,@"Failed to generate permission denied error with wrong credentials");
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:YES];
	[request setUseKeychainPersistance:YES];
	[request setUsername:@"secret_username"];
	[request setPassword:@"secret_password"];
	[request start];
	err = [request error];
	GHAssertNil(err,@"Failed to supply correct username and password");
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:NO];
	[request setUseKeychainPersistance:NO];
	[request start];
	success = [[request error] code] == ASIAuthenticationErrorType;
	GHAssertTrue(success,@"Reused credentials when we shouldn't have");

	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:YES];
	[request setUseKeychainPersistance:NO];
	[request start];
	err = [request error];
	GHAssertNil(err,@"Failed to reuse credentials");
	
	[ASIHTTPRequest clearSession];
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:NO];
	[request start];
	success = [[request error] code] == ASIAuthenticationErrorType;
	GHAssertTrue(success,@"Failed to clear credentials");
	
	// This test may show a dialog!
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:YES];
	[request start];
	err = [request error];
	GHAssertNil(err,@"Failed to use stored credentials");
}



- (void)testDigestAuthentication
{
	[ASIHTTPRequest clearSession];
	
	NSURL *url = [[[NSURL alloc] initWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/digest-authentication"] autorelease];
	ASIHTTPRequest *request;
	BOOL success;
	NSError *err;
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:NO];
	[request start];
	success = [[request error] code] == ASIAuthenticationErrorType;
	GHAssertTrue(success,@"Failed to generate permission denied error with no credentials");
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:NO];
	[request setUsername:@"wrong"];
	[request setPassword:@"wrong"];
	[request start];
	success = [[request error] code] == ASIAuthenticationErrorType;
	GHAssertTrue(success,@"Failed to generate permission denied error with wrong credentials");
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:YES];
	[request setUseKeychainPersistance:YES];
	[request setUsername:@"secret_username"];
	[request setPassword:@"secret_password"];
	[request start];
	err = [request error];
	GHAssertNil(err,@"Failed to supply correct username and password");
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:NO];
	[request setUseKeychainPersistance:NO];
	[request start];
	success = [[request error] code] == ASIAuthenticationErrorType;
	GHAssertTrue(success,@"Reused credentials when we shouldn't have");
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseSessionPersistance:YES];
	[request setUseKeychainPersistance:NO];
	[request start];
	err = [request error];
	GHAssertNil(err,@"Failed to reuse credentials");
	
	[ASIHTTPRequest clearSession];
	
	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	[request setUseKeychainPersistance:NO];
	[request start];
	success = [[request error] code] == ASIAuthenticationErrorType;
	GHAssertTrue(success,@"Failed to clear credentials");
}

// If you want to run this test, uncomment, and set your hostname, username, password and domain below.	
//- (void)testNTLMAuthentication
//{
//	NSString *theURL = @"";
//	NSString *username = @"";
//	NSString *password = @"";
//	NSString *domain = @"";
//	
//	if ([theURL isEqualToString:@""] || [username isEqualToString:@""] || [password isEqualToString:@""]) {
//		GHAssertFalse(true,@"Skipping NTLM test because no server details were supplied");
//	}
//	
//	[ASIHTTPRequest clearSession];
//	
//	NSURL *url = [[[NSURL alloc] initWithString:theURL] autorelease];
//	ASIHTTPRequest *request;
//	BOOL success;
//	NSError *err;
//	
//	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
//	[request setUseKeychainPersistance:NO];
//	[request setUseSessionPersistance:NO];
//	[request start];
//	success = [[request error] code] == ASIAuthenticationErrorType;
//	GHAssertTrue(success,@"Failed to generate permission denied error with no credentials");
//
//
//	request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
//	[request setUseSessionPersistance:YES];
//	[request setUseKeychainPersistance:NO];
//	[request setUsername:username];
//	[request setPassword:password];
//	[request setDomain:domain];
//	[request start];
//	err = [request error];
//	GHAssertNil(err,@"Got an error when correct credentials were supplied");
//}

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
	NSString *downloadPath = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"testfile.txt"];
	NSString *tempPath = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"tempfile.txt"];
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
	
	NSString *content = [NSString stringWithContentsOfFile:downloadPath];
	
	NSString *newPartialContent = [content substringFromIndex:95];
	success = ([newPartialContent isEqualToString:@"This is the content we ought to be getting if we start from byte 95."]);
	GHAssertTrue(success,@"Failed to append the correct data to the end of the file?");
	
	success = (progress > 0.95);
	GHAssertTrue(success,@"Failed to correctly display increment progress for a partial download");
}

- (void)testSSL
{
	NSURL *url = [NSURL URLWithString:@"https://selfsigned.allseeing-i.com"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request start];
	
	GHAssertNotNil([request error],@"Failed to generate an error for a self-signed certificate");		
	
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
	NSString *basePath = [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent];
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


@end


