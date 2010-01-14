//
//  ASICloudFilesRequest.m
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Michael Mayo on 22/12/09.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//
// A class for accessing data stored on Rackspace's Cloud Files Service
// http://www.rackspacecloud.com/cloud_hosting_products/files
// 
// Cloud Files Developer Guide:
// http://docs.rackspacecloud.com/servers/api/cs-devguide-latest.pdf

#import "ASICloudFilesRequest.h"

static NSString *username = nil;
static NSString *apiKey = nil;
static NSString *authToken = nil;
static NSString *storageURL = nil;
static NSString *cdnManagementURL = nil;
static NSString *rackspaceCloudAuthURL = @"https://auth.api.rackspacecloud.com/v1.0";

@implementation ASICloudFilesRequest

#pragma mark -
#pragma mark Attributes and Service URLs

+ (NSString *)authToken {
	return authToken;
}

+ (NSString *)storageURL {
	return storageURL;
}

+ (NSString *)cdnManagementURL {
	return cdnManagementURL;
}

#pragma mark -
#pragma mark Authentication

+ (id)authenticationRequest {
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:rackspaceCloudAuthURL]] autorelease];
	[request addRequestHeader:@"X-Auth-User" value:username];
	[request addRequestHeader:@"X-Auth-Key" value:apiKey];
	return request;
}

+ (void)authenticate {
	ASIHTTPRequest *request = [ASICloudFilesRequest authenticationRequest];
	[request startSynchronous];
	
	if (![request error]) {
		NSDictionary *responseHeaders = [request responseHeaders];
		authToken = [responseHeaders objectForKey:@"X-Auth-Token"];
		storageURL = [responseHeaders objectForKey:@"X-Storage-Url"];
		cdnManagementURL = [responseHeaders objectForKey:@"X-Cdn-Management-Url"];
	}
}

+ (NSString *)username {
	return username;
}

+ (void)setUsername:(NSString *)newUsername {
	[username release];
	username = [newUsername retain];
}

+ (NSString *)apiKey {
	return apiKey;
}

+ (void)setApiKey:(NSString *)newApiKey {
	[apiKey release];
	apiKey = [newApiKey retain];
}

#pragma mark -
#pragma mark Date Parser

-(NSDate *)dateFromString:(NSString *)dateString {
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease]];
	// example: 2009-11-04T19:46:20.192723
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'H:mm:ss.SSSSSS"];
	NSDate *date = [dateFormatter dateFromString:dateString];
	[dateFormatter release];
	
	return date;
}

@end
