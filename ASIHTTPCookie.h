//
//  ASIHTTPCookie.h
//  asi-http-request
//
//  Created by Ben Copsey on 25/08/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ASIHTTPCookie : NSObject {
	NSString *name;
	NSString *value;
	NSDate *expires;
	NSString *path;
	NSString *domain;
	BOOL requiresHTTPS;
}

- (void)setValue:(NSString *)newValue forProperty:(NSString *)property;

+ (NSMutableArray *)cookiesFromHeader:(NSString *)header;
+ (NSString *)urlEncodedValue:(NSString *)string;
+ (NSString *)urlDecodedValue:(NSString *)string;

@property (retain) NSString *name;
@property (retain) NSString *value;
@property (retain) NSDate *expires;
@property (retain) NSString *path;
@property (retain) NSString *domain;
@property (assign) BOOL requiresHTTPS;

@end
