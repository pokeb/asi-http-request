//
//  ASIInputStream.m
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 10/08/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import "ASIInputStream.h"
#import "ASIHTTPRequest.h"

// Used to ensure only one request can read data at once
static NSLock *readLock = nil;

@implementation ASIInputStream

+ (void)initialize
{
	if (self == [ASIInputStream class]) {
		readLock = [[NSLock alloc] init];
	}
}

+ (id)inputStreamWithFileAtPath:(NSString *)path request:(ASIHTTPRequest *)request
{
	ASIInputStream *stream = [[[self alloc] init] autorelease];
	[stream setRequest:request];
	[stream setStream:[NSInputStream inputStreamWithFileAtPath:path]];
	return stream;
}

+ (id)inputStreamWithData:(NSData *)data request:(ASIHTTPRequest *)request
{
	ASIInputStream *stream = [[[self alloc] init] autorelease];
	[stream setRequest:request];
	[stream setStream:[NSInputStream inputStreamWithData:data]];
	return stream;
}

- (void)dealloc
{
	[stream release];
	[super dealloc];
}

// Called when CFNetwork wants to read more of our request body
// When throttling is on, we ask ASIHTTPRequest for the maximum amount of data we can read
- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len
{
	[readLock lock];
	unsigned long toRead = len;
	if ([ASIHTTPRequest isBandwidthThrottled]) {
		toRead = [ASIHTTPRequest maxUploadReadLength];
		if (toRead > len) {
			toRead = len;
		} else if (toRead == 0) {
			toRead = 1;
		}
		[request performThrottling];
	}
	[ASIHTTPRequest incrementBandwidthUsedInLastSecond:toRead];
	[readLock unlock];
	return [stream read:buffer maxLength:toRead];
}

// If we get asked to perform a method we don't have (which is almost all of them), we'll just forward the message to our stream

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	return [stream methodSignatureForSelector:aSelector];
}
	 
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	[anInvocation invokeWithTarget:stream];
}

@synthesize stream;
@synthesize request;
@end
