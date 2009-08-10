//
//  ASIInputStream.m
//  Mac
//
//  Created by Ben Copsey on 10/08/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import "ASIInputStream.h"
#import "ASIHTTPRequest.h"

@implementation ASIInputStream

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

- (BOOL)hasBytesAvailable
{
	if ([ASIHTTPRequest maxUploadReadLength] == 0) {
		NSLog(@"no");
		return NO;
	}
	NSLog(@"yes");
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
