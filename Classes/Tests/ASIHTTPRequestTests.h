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
- (void)testNTLMHandshake;
- (void)testCharacterEncoding;
- (void)testCompressedResponse;
- (void)testCompressedResponseDownloadToFile;
- (void)test000SSL;
- (void)testRedirectPreservesSession;
- (void)testTooMuchRedirection;
- (void)testRedirectToNewDomain;
- (void)test303Redirect;
- (void)testCompression;
- (void)testSubclass;
- (void)testTimeOutWithoutDownloadDelegate;
- (void)testThrottlingDownloadBandwidth;
- (void)testThrottlingUploadBandwidth;
- (void)testMainThreadDelegateAuthenticationFailure;
@end
