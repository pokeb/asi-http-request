//
//  ASICloudFilesRequest.m
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Michael Mayo on 22/12/09.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//
// A (basic) class for accessing data stored on Rackspace's Cloud Files Service
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

+ (NSString *)authToken {
	return authToken;
}

+ (NSString *)storageURL {
	return storageURL;
}

+ (NSString *)cdnManagementURL {
	return cdnManagementURL;
}

+ (id)authenticationRequest {
	ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:rackspaceCloudAuthURL]];

	//[request addRequestHeader:[ASICloudFilesRequest authToken] value:@"X-Auth-Token"];
	//[request addRequestHeader:[ASICloudFilesRequest authToken] value:@"X-Auth-Token"];
	NSMutableDictionary *headers = [[NSMutableDictionary alloc] initWithCapacity:2];
	[headers setObject:username forKey:@"X-Auth-User"];
	[headers setObject:apiKey   forKey:@"X-Auth-Key"];	
	[request setRequestHeaders:headers];
	[headers release];
	return request;
}

+ (id)storageRequest {
	ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:storageURL]];
	return request;
}

+ (id)cdnRequest {
	ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:cdnManagementURL]];
	return request;
}

+ (void)authenticate {
	ASIHTTPRequest *request = [ASICloudFilesRequest authenticationRequest];
	
	[request start];
	
	if (![request error]) {
		NSDictionary *responseHeaders = [request responseHeaders];
		authToken = [responseHeaders objectForKey:@"X-Auth-Token"];
		storageURL = [responseHeaders objectForKey:@"X-Storage-Url"];
		cdnManagementURL = [responseHeaders objectForKey:@"X-Cdn-Management-Url"];
	} else {
		NSLog(@"%@",[[request error] localizedDescription]);
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
	NSDateFormatter *format = [[NSDateFormatter alloc] init];
	// example: 2009-11-04T19:46:20.192723
	[format setDateFormat:@"yyyy-MM-dd'T'H:mm:ss"];
	NSDate *date = [format dateFromString:dateString];
	[format release];
	
	return date;
}



@end
