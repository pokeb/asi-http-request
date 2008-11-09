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
	requestsCompleteCount = 0;
	
	return self;
}

- (void)cancelAllOperations
{
	uploadProgressBytes = 0;
	uploadProgressTotalBytes = 0;
	downloadProgressBytes = 0;
	downloadProgressTotalBytes = 0;	
	[super cancelAllOperations];
}

- (void)setUploadProgressDelegate:(id)newDelegate
{
	uploadProgressDelegate = newDelegate;
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

//Only add ASIHTTPRequests to this queue
- (void)addOperation:(NSOperation *)operation
{
	if ([operation isKindOfClass:[ASIHTTPRequest class]]) {
		requestsCount++;
		if (uploadProgressDelegate) {
			[(ASIHTTPRequest *)operation setUploadProgressDelegate:self];
		} else {
			[(ASIHTTPRequest *)operation setUploadProgressDelegate:NULL];
		}
		if (downloadProgressDelegate) {
			[(ASIHTTPRequest *)operation setDownloadProgressDelegate:self];
		} else {
			[(ASIHTTPRequest *)operation setDownloadProgressDelegate:NULL];	
		}
		[(ASIHTTPRequest *)operation setDelegate:self];
		[(ASIHTTPRequest *)operation setDidFailSelector:@selector(requestDidFail:)];
		[(ASIHTTPRequest *)operation setDidFinishSelector:@selector(requestDidFinish:)];
		[super addOperation:operation];
	}
	
}

- (void)requestDidFail:(ASIHTTPRequest *)request
{
	if (requestDidFailSelector) {
		[delegate performSelector:requestDidFailSelector withObject:request];
	}
	if (shouldCancelAllRequestsOnFailure) {
		[self cancelAllOperations];
	}
	requestsCompleteCount++;
}

- (void)requestDidFinish:(ASIHTTPRequest *)request
{
	requestsCompleteCount++;
	if (requestDidFinishSelector) {
		[delegate performSelector:requestDidFinishSelector withObject:request];
	}
	if (queueDidFinishSelector && requestsCompleteCount == requestsCount) {
		[delegate performSelector:queueDidFinishSelector withObject:self];
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
	
	double progress = (downloadProgressBytes*1.0)/(downloadProgressTotalBytes*1.0);
	[ASIHTTPRequest setProgress:progress forProgressIndicator:downloadProgressDelegate];
}

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
@end
