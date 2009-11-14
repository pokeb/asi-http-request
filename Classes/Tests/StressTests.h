//
//  StressTests.h
//  iPhone
//
//  Created by Ben Copsey on 30/10/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASITestCase.h"

@class ASIHTTPRequest;


@interface MyDelegate : NSObject {
	ASIHTTPRequest *request;
}
@property (retain) ASIHTTPRequest *request;
@end

@interface StressTests : ASITestCase {
	float progress;
	ASIHTTPRequest *cancelRequest;
	NSDate *cancelStartDate;
	MyDelegate *delegate;
	NSLock *createRequestLock;
}

- (void)testCancelStressTest;
- (void)performCancelRequest;

- (void)testRedirectStressTest;
- (void)performRedirectRequest;

- (void)testSetDelegate;
- (void)performSetDelegateRequest;

@property (retain) ASIHTTPRequest *cancelRequest;
@property (retain) NSDate *cancelStartDate;
@property (retain) MyDelegate *delegate;
@property (retain) NSLock *createRequestLock;
@end
