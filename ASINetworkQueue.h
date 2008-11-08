//
//  ASINetworkQueue.h
//  asi-http-request
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//



@interface ASINetworkQueue : NSOperationQueue {
	id delegate;
	
	id uploadProgressDelegate;
	int uploadProgressBytes;
	int uploadProgressTotalBytes;

	id downloadProgressDelegate;
	int downloadProgressBytes;
	int downloadProgressTotalBytes;
	
	SEL requestDidFinishSelector;
	SEL requestDidFailSelector;
	SEL queueDidFinishSelector;
	
	BOOL shouldCancelAllRequestsOnFailure;
	
	int requestsCount;
	int requestsCompleteCount;
}

//

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
