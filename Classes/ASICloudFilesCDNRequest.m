//
//  ASICloudFilesCDNRequest.m
//  iPhone
//
//  Created by Michael Mayo on 1/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ASICloudFilesCDNRequest.h"


@implementation ASICloudFilesCDNRequest

@synthesize accountName, containerName;

+ (id)cdnRequestWithMethod:(NSString *)method query:(NSString *)query {
	NSString *urlString = [NSString stringWithFormat:@"%@%@", [ASICloudFilesRequest cdnManagementURL], query];
	ASICloudFilesCDNRequest *request = [[ASICloudFilesCDNRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
	[request setRequestMethod:method];
	[request addRequestHeader:@"X-Auth-Token" value:[ASICloudFilesRequest authToken]];
	return request;
}

+ (id)cdnRequestWithMethod:(NSString *)method containerName:(NSString *)containerName {
	NSString *urlString = [NSString stringWithFormat:@"%@/%@", [ASICloudFilesRequest cdnManagementURL], containerName];
	//NSLog(@"object request url: %@", urlString);
	ASICloudFilesCDNRequest *request = [[ASICloudFilesCDNRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
	[request setRequestMethod:method];
	[request addRequestHeader:@"X-Auth-Token" value:[ASICloudFilesRequest authToken]];
	request.containerName = containerName;
	return request;
}

#pragma mark -
#pragma mark HEAD - Container Info

+ (id)containerInfoRequest:(NSString *)containerName {
	ASICloudFilesCDNRequest *request = [ASICloudFilesCDNRequest cdnRequestWithMethod:@"HEAD" containerName:containerName];
	return request;
}

- (BOOL)cdnEnabled {
	return [[[self responseHeaders] objectForKey:@"X-Cdn-Enabled"] boolValue];
}

- (NSString *)cdnURI {
	return [[self responseHeaders] objectForKey:@"X-Cdn-Uri"];
}

- (NSUInteger)cdnTTL {
	return [[[self responseHeaders] objectForKey:@"X-Ttl"] intValue];
}

#pragma mark -
#pragma mark GET - CDN Container Lists

+ (id)listRequest {
	ASICloudFilesCDNRequest *request = [ASICloudFilesCDNRequest cdnRequestWithMethod:@"GET" query:nil];
	return request;
}

+ (id)listRequestWithLimit:(NSUInteger)limit marker:(NSString *)marker enabledOnly:(BOOL)enabledOnly  {
	NSString *query = @"?format=xml";
	
	if (limit > 0) {
		query = [query stringByAppendingString:[NSString stringWithFormat:@"&limit=%i", limit]];
	}
	
	if (marker) {
		query = [query stringByAppendingString:[NSString stringWithFormat:@"&marker=%@", marker]];
	}
	
	if (limit > 0) {
		query = [query stringByAppendingString:[NSString stringWithFormat:@"&limit=%i", limit]];
	}
	
	ASICloudFilesCDNRequest *request = [ASICloudFilesCDNRequest cdnRequestWithMethod:@"GET" query:query];
	return request;
}

- (NSArray *)containers {
	return nil;
}

// GET /<api version>/<account>
// limit, marker, format, enabled_only=true
// + (id)getObjectRequestWithContainer:(NSString *)containerName objectPath:(NSString *)objectPath;


// PUT /<api version>/<account>/<container>
// PUT operations against a Container are used to CDN-enable that Container.
// Include an HTTP header of X-TTL to specify a custom TTL.

// POST /<api version>/<account>/<container>
// POST operations against a CDN-enabled Container are used to adjust CDN attributes.
// The POST operation can be used to set a new TTL cache expiration or to enable/disable public sharing over the CDN.
// X-TTL: 86400
// X-CDN-Enabled: True


#pragma mark -
#pragma mark Memory Management

-(void)dealloc {
	[accountName release];
	[containerName release];
	[super dealloc];
}

@end
