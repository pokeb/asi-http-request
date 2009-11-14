//
//  ASINetworkQueue.h
//  asi-http-request
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008-2009 All-Seeing Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ASINetworkQueue : NSOperationQueue {
	
	// Delegate will get didFail + didFinish messages (if set)
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
	unsigned long long bytesUploadedSoFar;
	
	// Total amount to be uploaded for all requests in this queue - requests add to this figure as they work out how much data they have to transmit
	unsigned long long totalBytesToUpload;

	// Download progress indicator, probably an NSProgressIndicator or UIProgressView
	id downloadProgressDelegate;
	
	// Total amount downloaded so far for all requests in this queue
	unsigned long long bytesDownloadedSoFar;
	
	// Total amount to be downloaded for all requests in this queue - requests add to this figure as they receive Content-Length headers
	unsigned long long totalBytesToDownload;
	
	// When YES, the queue will cancel all requests when a request fails. Default is YES
	BOOL shouldCancelAllRequestsOnFailure;
	
	//Number of real requests (excludes HEAD requests created to manage showAccurateProgress)
	int requestsCount;
	
	// When NO, this request will only update the progress indicator when it completes
	// When YES, this request will update the progress indicator according to how much data it has recieved so far
	// When YES, the queue will first perform HEAD requests for all GET requests in the queue, so it can calculate the total download size before it starts
	// NO means better performance, because it skips this step for GET requests, and it won't waste time updating the progress indicator until a request completes 
	// Set to YES if the size of a requests in the queue varies greatly for much more accurate results
	// Default for requests in the queue is NO
	BOOL showAccurateProgress;

	// Storage container for additional queue information.
	NSDictionary *userInfo;
}

// Convenience constructor
+ (id)queue;

// Used internally to manage HEAD requests when showAccurateProgress is YES, do not use!
- (void)addHEADOperation:(NSOperation *)operation;

// Called at the start of a request to add on the size of this upload to the total
- (void)incrementUploadSizeBy:(unsigned long long)bytes;

// Called during a request when data is written to the upload stream to increment the progress indicator
- (void)incrementUploadProgressBy:(unsigned long long)bytes;

// Called at the start of a request to add on the size of this download to the total
- (void)incrementDownloadSizeBy:(unsigned long long)bytes;

// Called during a request when data is received to increment the progress indicator
- (void)incrementDownloadProgressBy:(unsigned long long)bytes;

// Called during a request when authorisation fails to cancel any progress so far
- (void)decrementUploadProgressBy:(unsigned long long)bytes;

// Called when the first chunk of data is written to the upload buffer
// We ignore the first part chunk when tracking upload progress, as kCFStreamPropertyHTTPRequestBytesWrittenCount reports the amount of data written to the buffer, not the amount sent
// This is to workaround the first 128KB of data appearing in an upload progress delegate immediately
- (void)setUploadBufferSize:(unsigned long long)bytes;

// All ASINetworkQueues are paused when created so that total size can be calculated before the queue starts
// This method will start the queue
- (void)go;

// Used on iPhone platform to show / hide the network activity indicator (in the status bar)
// On mac, you could subclass to do something else
- (void)updateNetworkActivityIndicator;

// Returns YES if the queue is in progress
- (BOOL)isNetworkActive;


@property (assign,setter=setUploadProgressDelegate:) id uploadProgressDelegate;
@property (assign,setter=setDownloadProgressDelegate:) id downloadProgressDelegate;

@property (assign) SEL requestDidFinishSelector;
@property (assign) SEL requestDidFailSelector;
@property (assign) SEL queueDidFinishSelector;
@property (assign) BOOL shouldCancelAllRequestsOnFailure;
@property (assign) id delegate;
@property (assign) BOOL showAccurateProgress;
@property (assign, readonly) int requestsCount;
@property (retain) NSDictionary *userInfo;

@property (assign) unsigned long long bytesUploadedSoFar;
@property (assign) unsigned long long totalBytesToUpload;
@property (assign) unsigned long long bytesDownloadedSoFar;
@property (assign) unsigned long long totalBytesToDownload;

@end
