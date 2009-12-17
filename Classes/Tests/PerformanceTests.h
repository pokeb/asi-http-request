//
//  PerformanceTests.h
//  Mac
//
//  Created by Ben Copsey on 17/12/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ASITestCase.h"

@interface PerformanceTests : ASITestCase {
	NSDate *testStartDate;
	int requestsComplete;
	NSMutableArray *responseData;
	unsigned long bytesDownloaded;
}

- (void)testASIHTTPRequestAsyncPerformance;
- (void)testNSURLConnectionAsyncPerformance;

@property (retain,nonatomic) NSDate *testStartDate;
@property (assign,nonatomic) int requestsComplete;
@property (retain,nonatomic) NSMutableArray *responseData;
@end
