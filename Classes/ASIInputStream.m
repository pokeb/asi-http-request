//
//  ASIInputStream.m
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 10/08/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import "ASIInputStream.h"
#import "ASIHTTPRequest.h"
#import <objc/runtime.h>

// Used to ensure only one request can read data at once
static NSLock *readLock = nil;

@implementation ASIInputStream
{
    NSInputStream *_stream;
    id<NSStreamDelegate> delegate;
    
    CFReadStreamClientCallBack copiedCallback;
    CFStreamClientContext copiedContext;
    CFOptionFlags requestedEvents;
}

+ (void)initialize
{
	if (self == [ASIInputStream class]) {
		readLock = [[NSLock alloc] init];
	}
}

+ (instancetype)inputStreamWithFileAtPath:(NSString *)path request:(ASIHTTPRequest *)theRequest
{
	ASIInputStream *theStream = [[ASIInputStream alloc] initWithInputStream:[NSInputStream inputStreamWithFileAtPath:path]];
	[theStream setRequest:theRequest];
	return theStream;
}

+ (instancetype)inputStreamWithData:(NSData *)data request:(ASIHTTPRequest *)theRequest
{
    ASIInputStream *theStream = [[ASIInputStream alloc] initWithInputStream:[NSInputStream inputStreamWithData:data]];
	[theStream setRequest:theRequest];
	return theStream;
}

#pragma mark - Object lifecycle

- (id)initWithInputStream:(NSInputStream *)aStream
{
    self = [super init];
    if (self) {
        // Initialization code here.
        _stream = aStream;
        [_stream setDelegate:self];
        
        [self setDelegate:self];
    }
    
    return self;
}

#pragma mark - NSStream subclass methods

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

- (id <NSStreamDelegate> )delegate
{
    return delegate;
}

- (void)setDelegate:(id<NSStreamDelegate>)aDelegate
{
    if (aDelegate == nil) {
        delegate = self;
    }
    else {
        delegate = aDelegate;
    }
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

#pragma mark - NSInputStream subclass methods

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
		[ASIHTTPRequest incrementBandwidthUsedInLastSecond:(NSUInteger)rv];
	return rv;
}


- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len
{
    // We cannot implement our character-counting in O(1) time,
    // so we return NO as indicated in the NSInputStream
    // documentation.
    return NO;
}

- (BOOL)hasBytesAvailable
{
    return [_stream hasBytesAvailable];
}

#pragma mark - Undocumented CFReadStream bridged methods

+ (BOOL)resolveInstanceMethod:(SEL) selector
{
    NSString *name = NSStringFromSelector(selector);
    
    if ([name hasPrefix:@"_"]){
        name = [name substringFromIndex:1];
        SEL aSelector = NSSelectorFromString(name);
        Method method = class_getInstanceMethod(self, aSelector);
        
        if (method)
        {
            class_addMethod(self,
                            selector,
                            method_getImplementation(method),
                            method_getTypeEncoding(method));
            return YES;
        }
    }
    return [super resolveInstanceMethod:selector];
}

- (void)scheduleInCFRunLoop:(CFRunLoopRef)aRunLoop forMode:(CFStringRef)aMode
{
    CFReadStreamScheduleWithRunLoop((CFReadStreamRef)_stream, aRunLoop, aMode);
}

- (BOOL)setCFClientFlags:(CFOptionFlags)inFlags callback:(CFReadStreamClientCallBack)inCallback context:(CFStreamClientContext *)inContext
{
    if (inCallback != NULL) {
        requestedEvents = inFlags;
        copiedCallback = inCallback;
        memcpy(&copiedContext, inContext, sizeof(CFStreamClientContext));
        
        if (copiedContext.info && copiedContext.retain) {
            copiedContext.retain(copiedContext.info);
        }
    }
    else {
        requestedEvents = kCFStreamEventNone;
        copiedCallback = NULL;
        if (copiedContext.info && copiedContext.release) {
            copiedContext.release(copiedContext.info);
        }
        
        memset(&copiedContext, 0, sizeof(CFStreamClientContext));
    }
    
    return YES;
}

- (void)unscheduleFromCFRunLoop:(CFRunLoopRef)aRunLoop forMode:(CFStringRef)aMode
{
    CFReadStreamUnscheduleFromRunLoop((CFReadStreamRef)_stream, aRunLoop, aMode);
}

#pragma mark - NSStreamDelegate methods

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    assert(aStream ==_stream);
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            if (requestedEvents & kCFStreamEventOpenCompleted) {
                copiedCallback((__bridge CFReadStreamRef)self,
                               kCFStreamEventOpenCompleted,
                               copiedContext.info);
            }
            break;
            
        case NSStreamEventHasBytesAvailable:
            if (requestedEvents & kCFStreamEventHasBytesAvailable) {
                copiedCallback((__bridge CFReadStreamRef)self,
                               kCFStreamEventHasBytesAvailable,
                               copiedContext.info);
            }
            break;
            
        case NSStreamEventErrorOccurred:
            if (requestedEvents & kCFStreamEventErrorOccurred) {
                copiedCallback((__bridge CFReadStreamRef)self,
                               kCFStreamEventErrorOccurred,
                               copiedContext.info);
            }
            break;
            
        case NSStreamEventEndEncountered:
            if (requestedEvents & kCFStreamEventEndEncountered) {
                copiedCallback((__bridge CFReadStreamRef)self,
                               kCFStreamEventEndEncountered,
                               copiedContext.info);
            }
            break;
            
        case NSStreamEventHasSpaceAvailable:
            // This doesn't make sense for a read stream
            break;
            
        default:
            break;
    }
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
