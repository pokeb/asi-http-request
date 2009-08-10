//
//  ASIInputStream.m
//  Mac
//
//  Created by Ben Copsey on 10/08/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import "ASIInputStream.h"
#import "ASIHTTPRequest.h"

// This is a wrapper for NSInputStream that pretends to be an NSInputStream itself
// Subclassing NSInputStream seems to be tricky, and may involve overriding undocumented methods, so we'll cheat instead.

@implementation ASIInputStream

+ (id)inputStreamWithFileAtPath:(NSString *)path
{
	ASIInputStream *stream = [[[self alloc] init] autorelease];
	[stream setStream:[NSInputStream inputStreamWithFileAtPath:path]];
	return stream;
}

- (void)dealloc
{
	[stream release];
	[super dealloc];
}

- (BOOL)hasBytesAvailable
{
	if ([ASIHTTPRequest maxUploadReadLength] == 0) {
		return NO;
	}
	return [[self stream] hasBytesAvailable];
	
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len
{
	unsigned long toRead = [ASIHTTPRequest maxUploadReadLength];
	//NSLog(@"may read %lu",toRead);
	if (toRead > len) {
		toRead = len;
	} else if (toRead == 0) {
		toRead = 1;
	}
	//toRead = len;
	[ASIHTTPRequest incrementBandwidthUsedInLastSecond:toRead];
	//NSLog(@"will read %lu",toRead);
	return [[self stream] read:buffer maxLength:toRead];
}

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
