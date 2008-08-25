//
//  ASIHTTPCookie.m
//  asi-http-request
//
//  Created by Ben Copsey on 25/08/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import "ASIHTTPCookie.h"

@implementation ASIHTTPCookie

- (void)setValue:(NSString *)newValue forProperty:(NSString *)property
{
	NSString *prop = [property lowercaseString];
	if ([prop isEqualToString:@"expires"]) {
		[self setExpires:[NSDate dateWithNaturalLanguageString:newValue]];
		return;
	} else if ([prop isEqualToString:@"domain"]) {
		[self setDomain:newValue];
		return;
	} else if ([prop isEqualToString:@"path"]) {
		[self setPath:newValue];
		return;
	} else if ([prop isEqualToString:@"secure"]) {
		[self setRequiresHTTPS:[newValue isEqualToString:@"1"]];
		return;
	}
	if (![self name] && ![self value]) {
		[self setName:property];
		[self setValue:newValue];
	}
}


// I know this looks like a really ugly way to parse the Set-Cookie header, but I'd guess this is probably one of the simplest methods!
// You can't rely on a comma being a cookie delimeter, since it's quite likely that the expiry date for a cookie will contain a comma


+ (NSMutableArray *)cookiesFromHeader:(NSString *)header
{
	NSMutableArray *cookies = [[[NSMutableArray alloc] init] autorelease];
	ASIHTTPCookie *cookie = [[[ASIHTTPCookie alloc] init] autorelease];
	
	NSArray *parts = [header componentsSeparatedByString:@"="];
	int i;
	NSString *name;
	NSString *value;
	NSArray *components;
	NSString *newKey;
	NSString *terminator;
	for (i=0; i<[parts count]; i++) {
		NSString *part = [parts objectAtIndex:i];
		if (i == 0) {
			name = part;
			continue;
		} else if (i == [parts count]-1) {
			[cookie setValue:[ASIHTTPCookie urlDecodedValue:part] forProperty:name];
			[cookies addObject:cookie];
			continue;
		}
		components = [part componentsSeparatedByString:@" "];
		newKey = [components lastObject];
		value = [part substringWithRange:NSMakeRange(0,[part length]-[newKey length]-2)];
		[cookie setValue:[ASIHTTPCookie urlDecodedValue:value] forProperty:name];
		
		terminator = [part substringWithRange:NSMakeRange([part length]-[newKey length]-2,1)];
		if ([terminator isEqualToString:@","]) {
			[cookies addObject:cookie];
			cookie = [[[ASIHTTPCookie alloc] init] autorelease];
		}
		name = newKey;
	}
	
	return cookies;
	
}

+ (NSString *)urlDecodedValue:(NSString *)string
{
	NSMutableString *s = [NSMutableString stringWithString:[string stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	//Also swap plus signs for spaces
	[s replaceOccurrencesOfString:@"+" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [s length])];
	return [NSString stringWithString:s];
}

+ (NSString *)urlEncodedValue:(NSString *)string
{
	return [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@synthesize name;
@synthesize value;
@synthesize expires;
@synthesize path;
@synthesize domain;
@synthesize requiresHTTPS;
@end


