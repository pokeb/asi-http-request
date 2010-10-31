//
//  BlocksTests.m
//  Mac
//
//  Created by Ben Copsey on 18/10/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//

#import "BlocksTests.h"
#import "ASIHTTPRequest.h"


@implementation BlocksTests

// ASIHTTPRequest always calls blocks on the main thread (just like it does with delegate methods)
// So, we'll force this request to run on the main thread so we can rely on blocks having been called before the request returns
- (BOOL)shouldRunOnMainThread { return YES; }

#if NS_BLOCKS_AVAILABLE
- (void)testBlocks
{
	NSData *dataToSend = [@"This is my post body" dataUsingEncoding:NSUTF8StringEncoding];
	
	__block BOOL started = NO;
	__block BOOL receivedHeaders = NO;
	__block BOOL complete = NO;
	__block BOOL failed = NO;
	__block unsigned long long totalBytesReceived = 0;
	__block unsigned long long totalDownloadSize = 0;
	__block unsigned long long totalBytesSent = 0;
	__block unsigned long long totalUploadSize = 0;	
	NSMutableData *dataReceived = [NSMutableData data];
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/blocks"]];
	[request setStartedBlock:^(ASIHTTPRequest *request) {
		started = YES;
	}];
	[request setHeadersReceivedBlock:^(ASIHTTPRequest *request) {
		receivedHeaders = YES;
	}];
	[request setCompletionBlock:^(ASIHTTPRequest *request) {
		complete = YES;
	}];
	[request setFailedBlock:^(ASIHTTPRequest *request) {
		failed = YES;
	}];
	[request setBytesReceivedBlock:^(ASIHTTPRequest *aRequest, unsigned long long length, unsigned long long total) {
		totalBytesReceived += length;
	}];
	[request setDownloadSizeIncrementedBlock:^(ASIHTTPRequest *aRequest, long long length){
		totalDownloadSize += length;
	}];
	[request setBytesSentBlock:^(ASIHTTPRequest *aRequest, unsigned long long length, unsigned long long total) {
		totalBytesSent += length;
	}];
	[request setUploadSizeIncrementedBlock:^(ASIHTTPRequest *aRequest, long long length){
		totalUploadSize += length;
	}];
	[request setDataReceivedBlock:^(ASIHTTPRequest *aRequest, NSData *data){
        [dataReceived appendData:data];
    }];
	
	[request setRequestMethod:@"PUT"];
	[request appendPostData:dataToSend];
	[request startSynchronous];
	
	GHAssertFalse(failed,@"Request failed, cannot proceed with test");
	GHAssertTrue(started,@"Failed to call started block");
	GHAssertTrue(receivedHeaders,@"Failed to call received headers block");
	GHAssertTrue(complete,@"Failed to call completed block");
	
	BOOL success = (totalBytesReceived == 130050);
	GHAssertTrue(success,@"Failed to call bytes received block, or got wrong amount of data");
	success = (totalDownloadSize == 130050);
	GHAssertTrue(success,@"Failed to call download size increment block");
	
	success = (totalBytesSent == [dataToSend length]);
	GHAssertTrue(success,@"Failed to call bytes sent block");
	success = (totalUploadSize == [dataToSend length]);
	GHAssertTrue(success,@"Failed to call upload size increment block");
	
	
	request = [ASIHTTPRequest requestWithURL:nil];
	[request setFailedBlock:^(ASIHTTPRequest *request) {
		failed = YES;
	}];
	[request startSynchronous];
	GHAssertTrue(failed,@"Failed to call request failure block");
}
#endif

@end
