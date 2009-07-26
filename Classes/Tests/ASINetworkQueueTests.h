//
//  ASINetworkQueueTests.h
//  asi-http-request
//
//  Created by Ben Copsey on 08/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import "ASITestCase.h"

/*
IMPORTANT
Code that appears in these tests is not for general purpose use. 
You should not use [networkQueue waitUntilAllOperationsAreFinished] or [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]] in your own software.
They are used here to force a queue to operate synchronously to simplify writing the tests.
IMPORTANT
*/

@class ASIHTTPRequest;
@class ASINetworkQueue;

@interface ASINetworkQueueTests : ASITestCase {
	ASIHTTPRequest *requestThatShouldFail;
	BOOL complete;
	BOOL request_didfail;
	BOOL request_succeeded;
	float progress;
	
	NSOperationQueue *immediateCancelQueue;
	NSMutableArray *failedRequests;
	NSMutableArray *finishedRequests;
	
	ASINetworkQueue *releaseTestQueue;
}

- (void)testFailure;
- (void)testFailureCancelsOtherRequests;
- (void)testProgress;
- (void)testUploadProgress;
- (void)testProgressWithAuthentication;
- (void)testWithNoListener;
- (void)testPartialResume;
- (void)testImmediateCancel;

- (void)setProgress:(float)newProgress;
- (void)testSubclass;
- (void)testQueueReleaseOnRequestComplete;
- (void)testQueueReleaseOnQueueComplete;

@property (retain) NSOperationQueue *immediateCancelQueue;
@property (retain) NSMutableArray *failedRequests;
@property (retain) NSMutableArray *finishedRequests;
@property (retain) ASINetworkQueue *releaseTestQueue;
@end
