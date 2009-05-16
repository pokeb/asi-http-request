//
//  ASINetworkQueueTests.h
//  asi-http-request
//
//  Created by Ben Copsey on 08/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#if TARGET_OS_IPHONE
	#import "GHUnit.h"
#else
	#import <GHUnit/GHUnit.h>
#endif

@class ASIHTTPRequest;
@class ASINetworkQueue;

@interface ASINetworkQueueTests : GHTestCase {
	ASIHTTPRequest *requestThatShouldFail;
	ASINetworkQueue *networkQueue;
	BOOL complete;
	BOOL request_didfail;
	BOOL request_succeeded;
	float progress;
}

- (void)testFailure;
- (void)testFailureCancelsOtherRequests;
- (void)testProgress;
- (void)testUploadProgress;
- (void)testProgressWithAuthentication;
- (void)testWithNoListener;
- (void)testPartialResume;

- (void)setProgress:(float)newProgress;

@end
