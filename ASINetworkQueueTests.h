//
//  ASINetworkQueueTests.h
//  asi-http-request
//
//  Created by Ben Copsey on 08/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import "GHUnit.h"

@class ASIHTTPRequest;
@class ASINetworkQueue;

@interface ASINetworkQueueTests : GHTestCase {
	ASIHTTPRequest *requestThatShouldFail;
	ASINetworkQueue *networkQueue;
	BOOL complete;
	float progress;
}

- (void)testFailure;
- (void)testFailureCancelsOtherRequests;
- (void)testProgress;
- (void)testProgressWithAuthentication;

- (void)setProgress:(float)newProgress;

@end
