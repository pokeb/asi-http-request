//
//  NSHTTPCookieAdditions.h
//  asi-http-request
//
//  Created by Ben Copsey on 12/09/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSHTTPCookie (ValueEncodingAdditions)

- (NSString *)encodedValue;
- (NSString *)decodedValue;

@end
