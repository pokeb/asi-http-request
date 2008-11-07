//
//  ASIProgressQueue.m
//  asi-http-request
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import "ASIProgressQueue.h"
#import "ASIHTTPRequest.h"


@implementation ASIProgressQueue

- (id)init
{
	self = [super init];
	uploadProgressDelegate = nil;
	uploadProgressBytes = 0;
	uploadProgressTotalBytes = 0;
	
	downloadProgressDelegate = nil;
	downloadProgressBytes = 0;
	downloadProgressTotalBytes = 0;	
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

- (void)addOperation:(NSOperation *)operation
{
	if ([operation isKindOfClass:[ASIHTTPRequest class]]) {
		[(ASIHTTPRequest *)operation setUploadProgressDelegate:self];
		[(ASIHTTPRequest *)operation setDownloadProgressDelegate:self];
	}
	[super addOperation:operation];
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

@synthesize uploadProgressDelegate;
@synthesize downloadProgressDelegate;
@end
