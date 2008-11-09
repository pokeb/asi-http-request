//
//  ASINetworkQueue.h
//  asi-http-request
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//



@interface ASINetworkQueue : NSOperationQueue {
	
	// Delegate will get didFail + didFinish messages (if set), as well as authorizationNeededForRequest messages
	id delegate;

	// Will be called when a request completes with the request as the argument
	SEL requestDidFinishSelector;
	
	// Will be called when a request fails with the request as the argument
	SEL requestDidFailSelector;
	
	// Will be called when the queue finishes with the queue as the argument
	SEL queueDidFinishSelector;
	
	// Upload progress indicator, probably an NSProgressIndicator or UIProgressView
	id uploadProgressDelegate;
	
	// Total amount uploaded so far for all requests in this queue
	int uploadProgressBytes;
	
	// Total amount to be uploaded for all requests in this queue - requests add to this figure as they work out how much data they have to transmit
	int uploadProgressTotalBytes;

	// Download progress indicator, probably an NSProgressIndicator or UIProgressView
	id downloadProgressDelegate;
	
	// Total amount downloaded so far for all requests in this queue
	int downloadProgressBytes;
	
	// Total amount to be downloaded for all requests in this queue - requests add to this figure as they receive Content-Length headers
	int downloadProgressTotalBytes;
	
	// When YES, the queue will cancel all requests when a request fails. Default is YES
	BOOL shouldCancelAllRequestsOnFailure;
	
	int requestsCount;
	int requestsCompleteCount;
}


// Called at the start of a request to add on the size of this upload to the total
- (void)incrementUploadSizeBy:(int)bytes;

// Called during a request when data is written to the upload stream to increment the progress indicator
- (void)incrementUploadProgressBy:(int)bytes;

// Called at the start of a request to add on the size of this download to the total
- (void)incrementDownloadSizeBy:(int)bytes;

// Called during a request when data is received to increment the progress indicator
- (void)incrementDownloadProgressBy:(int)bytes;

@property (assign,setter=setUploadProgressDelegate:) id uploadProgressDelegate;
@property (assign,setter=setDownloadProgressDelegate:) id downloadProgressDelegate;

@property (assign) SEL requestDidFinishSelector;
@property (assign) SEL requestDidFailSelector;
@property (assign) SEL queueDidFinishSelector;
@property (assign) BOOL shouldCancelAllRequestsOnFailure;
@property (assign) id delegate;
@end
