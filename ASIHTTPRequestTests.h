//
//  ASIHTTPRequestTests.h
//  asi-http-request
//
//  Created by Ben Copsey on 01/08/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>


@interface ASIHTTPRequestTests : SenTestCase {
	float progress;
}

- (void)testBasicDownload;
- (void)testTimeOut;
- (void)testRequestMethod;
- (void)testContentLength;
- (void)testFileDownload;
- (void)testDownloadProgress;
- (void)testUploadProgress;
- (void)testCookies;
- (void)testBasicAuthentication;
- (void)testDigestAuthentication;

@end
