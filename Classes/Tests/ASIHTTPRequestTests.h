//
//  ASIHTTPRequestTests.h
//  asi-http-request
//
//  Created by Ben Copsey on 01/08/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import "ASITestCase.h"

@interface ASIHTTPRequestTests : ASITestCase {
	float progress;
}

- (void)testBasicDownload;
- (void)testTimeOut;
- (void)testRequestMethod;
- (void)testHTTPVersion;
- (void)testUserAgent;
- (void)testUploadContentLength;
- (void)testDownloadContentLength;
- (void)testFileDownload;
- (void)testDownloadProgress;
- (void)testUploadProgress;
- (void)testCookies;
- (void)testBasicAuthentication;
- (void)testDigestAuthentication;
//- (void)testNTLMAuthentication;
- (void)testCharacterEncoding;
- (void)testCompressedResponse;
- (void)testCompressedResponseDownloadToFile;
- (void)testSSL;
- (void)testRedirectPreservesSession;
- (void)testTooMuchRedirection;
- (void)testRedirectToNewDomain;
- (void)test303Redirect;
- (void)testCompression;
- (void)testSubclass;

@end
