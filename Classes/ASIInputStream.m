//
//  ASIInputStream.m
//  asi-http-request
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

+ (id)inputStreamWithFileAtPath:(NSString *)path
{
	ASIInputStream *stream = [[[self alloc] init] autorelease];
	[stream setStream:[NSInputStream inputStreamWithFileAtPath:path]];
	return stream;
}

+ (id)inputStreamWithData:(NSData *)data
{
	ASIInputStream *stream = [[[self alloc] init] autorelease];
	[stream setStream:[NSInputStream inputStreamWithData:data]];
	return stream;
}

- (void)dealloc
{
	[stream release];
	[super dealloc];
}


// Ok, so this works, but I don't really understand why.
// Ideally, we'd just return the stream's hasBytesAvailable, but CFNetwork seems to want to monopolise our run loop until (presumably) its buffer is full, which will cause timeouts if we're throttling the bandwidth
// We return NO when we shouldn't be uploading any more data because our bandwidth limit has run out (for now)
// The call to maxUploadReadLength will recognise that we've run out of our allotted bandwidth limit, and sleep this thread for the rest of the measurement period
// This method will be called again, but we'll almost certainly return YES the next time around, because we'll have more limit to use up
// The NO returns seem to snap CFNetwork out of its reverie, and return control to the main loop in loadRequest, so that we can manage timeouts and progress delegate updates
- (BOOL)hasBytesAvailable
{
	
	if ([ASIHTTPRequest isBandwidthThrottled]) {
		[readLock lock];
		if ([ASIHTTPRequest maxUploadReadLength] == 0) {
			[readLock unlock];
			return NO;
		}
		[readLock unlock];
	}
	return [[self stream] hasBytesAvailable];
	
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
		
		// Hopefully this won't happen because hasBytesAvailable will have returned NO, but just in case - we need to read at least 1 byte, or bad things might happen
		} else if (toRead == 0) {
			toRead = 1;
		}
		//NSLog(@"Throttled read %u",toRead);
	} else {
		//NSLog(@"Unthrottled read %u",toRead);
	}
	[ASIHTTPRequest incrementBandwidthUsedInLastSecond:toRead];
	[readLock unlock];
	return [[self stream] read:buffer maxLength:toRead];
}

// If we get asked to perform a method we don't have (which is almost all of them), we'll just forward the message to our stream

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	return [[self stream] methodSignatureForSelector:aSelector];
}
	 
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	[anInvocation invokeWithTarget:[self stream]];
}

@synthesize stream;
@end
