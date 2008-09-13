//
//  ASIHTTPRequestTests.h
//  asi-http-request
//
//  Created by Ben Copsey on 01/08/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>


@interface ASIHTTPRequestTests : SenTestCase {
}

- (void)testBasicDownload;
- (void)testTimeOut;
- (void)testOperationQueue;
- (void)testCookies;
@end
