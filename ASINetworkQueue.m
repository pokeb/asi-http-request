//
//  ASINetworkQueue.m
//  asi-http-request
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import "ASINetworkQueue.h"
#import "ASIHTTPRequest.h"


@implementation ASINetworkQueue

- (id)init
{
	self = [super init];
	
	delegate = NULL;
	requestDidFinishSelector = NULL;
	requestDidFailSelector = NULL;
	queueDidFinishSelector = NULL;
	shouldCancelAllRequestsOnFailure = YES;
	
	uploadProgressDelegate = nil;
	uploadProgressBytes = 0;
	uploadProgressTotalBytes = 0;
	
	downloadProgressDelegate = nil;
	downloadProgressBytes = 0;
	downloadProgressTotalBytes = 0;
	
	requestsCount = 0;
	
	showAccurateProgress = NO;
	
	[self setSuspended:YES];
	
	return self;
}

- (void)go
{
	if (!showAccurateProgress) {
		if (downloadProgressDelegate) {
			[self incrementDownloadSizeBy:requestsCount];
		}
		if (uploadProgressDelegate) {
			[self incrementUploadSizeBy:requestsCount];
		}		
	}
	[self setSuspended:NO];
}

- (void)cancelAllOperations
{
	requestsCount = 0;
	uploadProgressBytes = 0;
	uploadProgressTotalBytes = 0;
	downloadProgressBytes = 0;
	downloadProgressTotalBytes = 0;
	[self setUploadProgressDelegate:nil];
	[self setDownloadProgressDelegate:nil];
	[self setDelegate:nil];
	[super cancelAllOperations];
}

- (void)setUploadProgressDelegate:(id)newDelegate
{
	uploadProgressDelegate = newDelegate;
	
	// If the uploadProgressDelegate is an NSProgressIndicator, we set it's MaxValue to 1.0 so we can treat it similarly to UIProgressViews
	SEL selector = @selector(setMaxValue:);
	if ([uploadProgressDelegate respondsToSelector:selector]) {
		double max = 1.0;
		NSMethodSignature *signature = [[uploadProgressDelegate class] instanceMethodSignatureForSelector:selector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setSelector:selector];
		[invocation setArgument:&max atIndex:2];
		[invocation invokeWithTarget:uploadProgressDelegate];
	}	
}


- (void)setDownloadProgressDelegate:(id)newDelegate
{
	downloadProgressDelegate = newDelegate;
	
	// If the downloadProgressDelegate is an NSProgressIndicator, we set it's MaxValue to 1.0 so we can treat it similarly to UIProgressViews
	SEL selector = @selector(setMaxValue:);
	if ([downloadProgressDelegate respondsToSelector:selector]) {
		double max = 1.0;
		NSMethodSignature *signature = [[downloadProgressDelegate class] instanceMethodSignatureForSelector:selector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setSelector:@selector(setMaxValue:)];
		[invocation setArgument:&max atIndex:2];
		[invocation invokeWithTarget:downloadProgressDelegate];
	}	
}

- (void)addHEADOperation:(NSOperation *)operation
{
	if ([operation isKindOfClass:[ASIHTTPRequest class]]) {
		
		ASIHTTPRequest *request = (ASIHTTPRequest *)operation;
		[request setShowAccurateProgress:YES];
		if (uploadProgressDelegate) {
			[request setUploadProgressDelegate:self];
		} else {
			[request setUploadProgressDelegate:NULL];
		}
		if (downloadProgressDelegate) {
			[request setDownloadProgressDelegate:self];
		} else {
			[request setDownloadProgressDelegate:NULL];	
		}
		[request setDelegate:self];
		[super addOperation:request];
	}
}

// Only add ASIHTTPRequests to this queue!!
- (void)addOperation:(NSOperation *)operation
{
	if ([operation isKindOfClass:[ASIHTTPRequest class]]) {
		
		requestsCount++;
		
		ASIHTTPRequest *request = (ASIHTTPRequest *)operation;
		
		if (showAccurateProgress) {
			
			//If this is a GET request and we want accurate progress, perform a HEAD request first to get the content-length
			if ([[request requestMethod] isEqualToString:@"GET"]) {
				ASIHTTPRequest *HEADRequest = [[[ASIHTTPRequest alloc] initWithURL:[request url]] autorelease];
				[HEADRequest setRequestMethod:@"HEAD"];
				[HEADRequest setQueuePriority:10];
				[HEADRequest setMainRequest:request];
				[self addHEADOperation:HEADRequest];
				
				[request setUseCachedContentLength:YES];
				[request addDependency:HEADRequest];
			
			//If we want to track uploading for this request accurately, we need to add the size of the post content to the total
			} else if (uploadProgressDelegate) {
				[request buildPostBody];
				uploadProgressTotalBytes += [request postLength];
			}
		}
		[request setShowAccurateProgress:showAccurateProgress];
		
		if (uploadProgressDelegate) {
			[request setUploadProgressDelegate:self];
		} else {
			[request setUploadProgressDelegate:NULL];
		}
		if (downloadProgressDelegate) {
			[request setDownloadProgressDelegate:self];
		} else {
			[request setDownloadProgressDelegate:NULL];	
		}
		[request setDelegate:self];
		[request setDidFailSelector:@selector(requestDidFail:)];
		[request setDidFinishSelector:@selector(requestDidFinish:)];
		[super addOperation:request];
	}
	
}

- (void)requestDidFail:(ASIHTTPRequest *)request
{
	requestsCount--;
	if (requestDidFailSelector) {
		[delegate performSelector:requestDidFailSelector withObject:request];
	}
	if (shouldCancelAllRequestsOnFailure) {
		[self cancelAllOperations];
	}
}

- (void)requestDidFinish:(ASIHTTPRequest *)request
{
	requestsCount--;
	if (requestDidFinishSelector) {
		[delegate performSelector:requestDidFinishSelector withObject:request];
	}
	if (requestsCount == 0) {
		if (queueDidFinishSelector) {
			[delegate performSelector:queueDidFinishSelector withObject:self];
		}
	}
}

- (void)incrementUploadSizeBy:(int)bytes
{
	if (!uploadProgressDelegate) {
		return;
	}
	uploadProgressTotalBytes += bytes;
	[self incrementUploadProgressBy:0];
}

- (void)incrementUploadProgressBy:(int)bytes
{
	if (!uploadProgressDelegate || uploadProgressTotalBytes == 0) {
		return;
	}
	uploadProgressBytes += bytes;
	
	double progress = (uploadProgressBytes*1.0)/(uploadProgressTotalBytes*1.0);
	[ASIHTTPRequest setProgress:progress forProgressIndicator:uploadProgressDelegate];
}

- (void)incrementDownloadSizeBy:(int)bytes
{
	if (!downloadProgressDelegate) {
		return;
	}
	downloadProgressTotalBytes += bytes;
	[self incrementDownloadProgressBy:0];
}

- (void)incrementDownloadProgressBy:(int)bytes
{
	if (!downloadProgressDelegate || downloadProgressTotalBytes == 0) {
		return;
	}
	downloadProgressBytes += bytes;
	//NSLog(@"%hu/%hu",downloadProgressBytes,downloadProgressTotalBytes);
	double progress = (downloadProgressBytes*1.0)/(downloadProgressTotalBytes*1.0);
	[ASIHTTPRequest setProgress:progress forProgressIndicator:downloadProgressDelegate];
}

// Since this queue takes over as the delegate for all requests it contains, it should forward authorisation requests to its own delegate
- (void)authorizationNeededForRequest:(ASIHTTPRequest *)request
{
	if ([delegate respondsToSelector:@selector(authorizationNeededForRequest:)]) {
		[delegate performSelector:@selector(authorizationNeededForRequest:) withObject:request];
	}
}



@synthesize uploadProgressDelegate;
@synthesize downloadProgressDelegate;
@synthesize requestDidFinishSelector;
@synthesize requestDidFailSelector;
@synthesize queueDidFinishSelector;
@synthesize shouldCancelAllRequestsOnFailure;
@synthesize delegate;
@synthesize showAccurateProgress;

@end
