//
//  ASIInputStream.h
//  Mac
//
//  Created by Ben Copsey on 10/08/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

// This is a wrapper for NSInputStream that pretends to be an NSInputStream itself
// Subclassing NSInputStream seems to be tricky, and may involve overriding undocumented methods, so we'll cheat instead.

@interface ASIInputStream : NSObject {
	NSInputStream *stream;
}
+ (id)inputStreamWithFileAtPath:(NSString *)path;
+ (id)inputStreamWithData:(NSData *)data;

@property (retain) NSInputStream *stream;
@end
