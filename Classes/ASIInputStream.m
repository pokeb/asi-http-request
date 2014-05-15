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

+ (instancetype)inputStreamWithFileAtPath:(NSString *)path request:(ASIHTTPRequest *)theRequest
{
	ASIInputStream *theStream = [[self alloc] init];
	[theStream setRequest:theRequest];
	[theStream setStream:[NSInputStream inputStreamWithFileAtPath:path]];
	return theStream;
}

+ (instancetype)inputStreamWithData:(NSData *)data request:(ASIHTTPRequest *)theRequest
{
	ASIInputStream *theStream = [[self alloc] init];
	[theStream setRequest:theRequest];
	[theStream setStream:[NSInputStream inputStreamWithData:data]];
	return theStream;
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
		[_request performThrottling];
	}
	[readLock unlock];
	NSInteger rv = [_stream read:buffer maxLength:toRead];
	if (rv > 0)
		[ASIHTTPRequest incrementBandwidthUsedInLastSecond:rv];
	return rv;
}

/*
 * Implement NSInputStream mandatory methods to make sure they are implemented
 * (necessary for MacRuby for example) and avoid the overhead of method
 * forwarding for these common methods.
 */
- (void)open
{
    [_stream open];
}

- (void)close
{
    [_stream close];
}

- (id)delegate
{
    return [_stream delegate];
}

- (void)setDelegate:(id)delegate
{
    [_stream setDelegate:delegate];
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode
{
    [_stream scheduleInRunLoop:aRunLoop forMode:mode];
}

- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode
{
    [_stream removeFromRunLoop:aRunLoop forMode:mode];
}

- (id)propertyForKey:(NSString *)key
{
    return [_stream propertyForKey:key];
}

- (BOOL)setProperty:(id)property forKey:(NSString *)key
{
    return [_stream setProperty:property forKey:key];
}

- (NSStreamStatus)streamStatus
{
    return [_stream streamStatus];
}

- (NSError *)streamError
{
    return [_stream streamError];
}

// If we get asked to perform a method we don't have (probably internal ones),
// we'll just forward the message to our stream

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	return [_stream methodSignatureForSelector:aSelector];
}
	 
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	[anInvocation invokeWithTarget:_stream];
}

@end
