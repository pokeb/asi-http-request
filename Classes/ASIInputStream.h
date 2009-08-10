//
//  ASIInputStream.h
//  Mac
//
//  Created by Ben Copsey on 10/08/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ASIInputStream : NSObject {
	NSInputStream *stream;
}
+ (id)inputStreamWithFileAtPath:(NSString *)path;

@property (retain) NSInputStream *stream;
@end
