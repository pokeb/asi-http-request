//
//  ASINetworkQueue.m
//  asi-http-request
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008-2009 All-Seeing Interactive. All rights reserved.
//

#import "ASINetworkQueue.h"
#import "ASIHTTPRequest.h"

// Private stuff
@interface ASINetworkQueue ()
	@property (assign) int requestsCount;
@end

@implementation ASINetworkQueue

- (id)init
{
	self = [super init];
	[self setShouldCancelAllRequestsOnFailure:YES];
	[self setMaxConcurrentOperationCount:4];
	[self setSuspended:YES];
	
	return self;
}

+ (id)queue
{
	return [[[self alloc] init] autorelease];
}

- (void)dealloc
{
	//We need to clear the queue on any requests that haven't got around to cleaning up yet, as otherwise they'll try to let us know if something goes wrong, and we'll be long gone by then
	for (ASIHTTPRequest *request in [self operations]) {
		[request setQueue:nil];
	}
	[userInfo release];
	[super dealloc];
}

- (BOOL)isNetworkActive
{
	return ([self requestsCount] > 0 && ![self isSuspended]);
}

- (void)updateNetworkActivityIndicator
{
#if TARGET_OS_IPHONE
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:[self isNetworkActive]];
#endif
}

- (void)setSuspended:(BOOL)suspend
{
	[super setSuspended:suspend];
	[self updateNetworkActivityIndicator];
}


- (void)go
{
	if (![self showAccurateProgress]) {
		if ([self downloadProgressDelegate]) {
			[self incrementDownloadSizeBy:[self requestsCount]];
		}
		if ([self uploadProgressDelegate]) {
			[self incrementUploadSizeBy:[self requestsCount]];
		}		
	}
	[self setSuspended:NO];
}

- (void)cancelAllOperations
{
	[self setRequestsCount:0];
	[self setBytesUploadedSoFar:0];
	[self setTotalBytesToUpload:0];
	[self setBytesDownloadedSoFar:0];
	[self setTotalBytesToDownload:0];
	[super cancelAllOperations];
	[self updateNetworkActivityIndicator];
}

- (void)setUploadProgressDelegate:(id)newDelegate
{
	uploadProgressDelegate = newDelegate;

#if !TARGET_OS_IPHONE
	// If the uploadProgressDelegate is an NSProgressIndicator, we set it's MaxValue to 1.0 so we can treat it similarly to UIProgressViews
	SEL selector = @selector(setMaxValue:);
	if ([[self uploadProgressDelegate] respondsToSelector:selector]) {
		double max = 1.0;
		NSMethodSignature *signature = [[[self uploadProgressDelegate] class] instanceMethodSignatureForSelector:selector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setSelector:selector];
		[invocation setArgument:&max atIndex:2];
		[invocation invokeWithTarget:[self uploadProgressDelegate]];
	}
#endif
}


- (void)setDownloadProgressDelegate:(id)newDelegate
{
	downloadProgressDelegate = newDelegate;

#if !TARGET_OS_IPHONE
	// If the downloadProgressDelegate is an NSProgressIndicator, we set it's MaxValue to 1.0 so we can treat it similarly to UIProgressViews
	SEL selector = @selector(setMaxValue:);
	if ([[self downloadProgressDelegate] respondsToSelector:selector]) {
		double max = 1.0;
		NSMethodSignature *signature = [[[self downloadProgressDelegate] class] instanceMethodSignatureForSelector:selector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setSelector:@selector(setMaxValue:)];
		[invocation setArgument:&max atIndex:2];
		[invocation invokeWithTarget:[self downloadProgressDelegate]];
	}
#endif
}

- (void)addHEADOperation:(NSOperation *)operation
{
	if ([operation isKindOfClass:[ASIHTTPRequest class]]) {
		
		ASIHTTPRequest *request = (ASIHTTPRequest *)operation;
		[request setRequestMethod:@"HEAD"];
		[request setQueuePriority:10];
		[request setShowAccurateProgress:YES];
		[request setQueue:self];
		
		// Important - we are calling NSOperation's add method - we don't want to add this as a normal request!
		[super addOperation:request];
	}
}

// Only add ASIHTTPRequests to this queue!!
- (void)addOperation:(NSOperation *)operation
{
	if (![operation isKindOfClass:[ASIHTTPRequest class]]) {
		[NSException raise:@"AttemptToAddInvalidRequest" format:@"Attempted to add an object that was not an ASIHTTPRequest to an ASINetworkQueue"];
	}
		
	[self setRequestsCount:[self requestsCount]+1];
	
	ASIHTTPRequest *request = (ASIHTTPRequest *)operation;
	
	if ([self showAccurateProgress]) {
		
		// If this is a GET request and we want accurate progress, perform a HEAD request first to get the content-length
		// We'll only do this before the queue is started
		// If requests are added after the queue is started they will probably move the overall progress backwards anyway, so there's no value performing the HEAD requests first
		// Instead, they'll update the total progress if and when they recieve a content-length header
		if ([[request requestMethod] isEqualToString:@"GET"] && [self isSuspended]) {
			ASIHTTPRequest *HEADRequest = [request HEADRequest];
			[self addHEADOperation:HEADRequest];
			
			//Tell the request not to reset the progress indicator when it gets a content-length, as we will get the length from the HEAD request
			[request setShouldResetProgressIndicators:NO];
			
			[request addDependency:HEADRequest];
		
		// If we want to track uploading for this request accurately, we need to add the size of the post content to the total
		} else if (uploadProgressDelegate) {
			[request buildPostBody];
			[self setTotalBytesToUpload:[self totalBytesToUpload]+[request postLength]];
		}
	}
	[request setShowAccurateProgress:[self showAccurateProgress]];

	
	[request setQueue:self];
	[super addOperation:request];
	[self updateNetworkActivityIndicator];

}

- (void)requestDidFail:(ASIHTTPRequest *)request
{
	[self setRequestsCount:[self requestsCount]-1];
	[self updateNetworkActivityIndicator];
	if ([self requestDidFailSelector]) {
		[[self delegate] performSelector:[self requestDidFailSelector] withObject:request];
	}
	if ([self shouldCancelAllRequestsOnFailure] && [self requestsCount] > 0) {
		[self cancelAllOperations];
	}
	if ([self requestsCount] == 0) {
		if ([self queueDidFinishSelector]) {
			[[self delegate] performSelector:[self queueDidFinishSelector] withObject:self];
		}
	}
}

- (void)requestDidFinish:(ASIHTTPRequest *)request
{
	[self setRequestsCount:[self requestsCount]-1];
	[self updateNetworkActivityIndicator];
	if ([self requestDidFinishSelector]) {
		[[self delegate] performSelector:[self requestDidFinishSelector] withObject:request];
	}
	if ([self requestsCount] == 0) {
		if ([self queueDidFinishSelector]) {
			[[self delegate] performSelector:[self queueDidFinishSelector] withObject:self];
		}
	}
}


- (void)setUploadBufferSize:(unsigned long long)bytes
{
	if (![self uploadProgressDelegate]) {
		return;
	}
	[self setTotalBytesToUpload:[self totalBytesToUpload] - bytes];
	[self incrementUploadProgressBy:0];
}

- (void)incrementUploadSizeBy:(unsigned long long)bytes
{
	if (![self uploadProgressDelegate]) {
		return;
	}
	[self setTotalBytesToUpload:[self totalBytesToUpload] + bytes];
	[self incrementUploadProgressBy:0];
}

- (void)decrementUploadProgressBy:(unsigned long long)bytes
{
	if (![self uploadProgressDelegate] || [self totalBytesToUpload] == 0) {
		return;
	}
	[self setBytesUploadedSoFar:[self bytesUploadedSoFar] - bytes];
	
	double progress;
	//Workaround for an issue with converting a long to a double on iPhone OS 2.2.1 with a base SDK >= 3.0
	if ([ASIHTTPRequest isiPhoneOS2]) {
		progress = [[NSNumber numberWithUnsignedLongLong:[self bytesUploadedSoFar]] doubleValue]/[[NSNumber numberWithUnsignedLongLong:[self totalBytesToUpload]] doubleValue]; 
	} else {
		progress = ([self bytesUploadedSoFar]*1.0)/([self totalBytesToUpload]*1.0);
	}
	[ASIHTTPRequest setProgress:progress forProgressIndicator:[self uploadProgressDelegate]];
}


- (void)incrementUploadProgressBy:(unsigned long long)bytes
{
	if (![self uploadProgressDelegate] || [self totalBytesToUpload] == 0) {
		return;
	}
	[self setBytesUploadedSoFar:[self bytesUploadedSoFar] + bytes];
	
	double progress;
	//Workaround for an issue with converting a long to a double on iPhone OS 2.2.1 with a base SDK >= 3.0
	if ([ASIHTTPRequest isiPhoneOS2]) {
		progress = [[NSNumber numberWithUnsignedLongLong:[self bytesUploadedSoFar]] doubleValue]/[[NSNumber numberWithUnsignedLongLong:[self totalBytesToUpload]] doubleValue]; 
	} else {
		progress = ([self bytesUploadedSoFar]*1.0)/([self totalBytesToUpload]*1.0);
	}
	[ASIHTTPRequest setProgress:progress forProgressIndicator:[self uploadProgressDelegate]];

}

- (void)incrementDownloadSizeBy:(unsigned long long)bytes
{
	if (![self downloadProgressDelegate]) {
		return;
	}
	[self setTotalBytesToDownload:[self totalBytesToDownload] + bytes];
	[self incrementDownloadProgressBy:0];
}

- (void)incrementDownloadProgressBy:(unsigned long long)bytes
{
	if (![self downloadProgressDelegate] || [self totalBytesToDownload] == 0) {
		return;
	}
	[self setBytesDownloadedSoFar:[self bytesDownloadedSoFar] + bytes];
	
	double progress;
	//Workaround for an issue with converting a long to a double on iPhone OS 2.2.1 with a base SDK >= 3.0
	if ([ASIHTTPRequest isiPhoneOS2]) {
		progress = [[NSNumber numberWithUnsignedLongLong:[self bytesDownloadedSoFar]] doubleValue]/[[NSNumber numberWithUnsignedLongLong:[self totalBytesToDownload]] doubleValue]; 
	} else {
		progress = ([self bytesDownloadedSoFar]*1.0)/([self totalBytesToDownload]*1.0);
	}
	[ASIHTTPRequest setProgress:progress forProgressIndicator:[self downloadProgressDelegate]];
}


// Since this queue takes over as the delegate for all requests it contains, it should forward authorisation requests to its own delegate
- (void)authenticationNeededForRequest:(ASIHTTPRequest *)request
{
	if ([[self delegate] respondsToSelector:@selector(authenticationNeededForRequest:)]) {
		[[self delegate] performSelector:@selector(authenticationNeededForRequest:) withObject:request];
	}
}

- (void)proxyAuthenticationNeededForRequest:(ASIHTTPRequest *)request
{
	if ([[self delegate] respondsToSelector:@selector(proxyAuthenticationNeededForRequest:)]) {
		[[self delegate] performSelector:@selector(proxyAuthenticationNeededForRequest:) withObject:request];
	}
}


- (BOOL)respondsToSelector:(SEL)selector
{
	if (selector == @selector(authenticationNeededForRequest:)) {
		if ([[self delegate] respondsToSelector:@selector(authenticationNeededForRequest:)]) {
			return YES;
		}
		return NO;
	} else if (selector == @selector(proxyAuthenticationNeededForRequest:)) {
		if ([[self delegate] respondsToSelector:@selector(proxyAuthenticationNeededForRequest:)]) {
			return YES;
		}
		return NO;
	}
	return [super respondsToSelector:selector];
}


@synthesize requestsCount;
@synthesize bytesUploadedSoFar;
@synthesize totalBytesToUpload;
@synthesize bytesDownloadedSoFar;
@synthesize totalBytesToDownload;
@synthesize shouldCancelAllRequestsOnFailure;
@synthesize uploadProgressDelegate;
@synthesize downloadProgressDelegate;
@synthesize requestDidFinishSelector;
@synthesize requestDidFailSelector;
@synthesize queueDidFinishSelector;
@synthesize delegate;
@synthesize showAccurateProgress;
@synthesize userInfo;

@end
