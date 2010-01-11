//
//  ASICloudFilesContainerRequest.m
//  iPhone
//
//  Created by Michael Mayo on 1/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ASICloudFilesContainerRequest.h"
#import "ASICloudFilesContainer.h"
#import "ASICloudFilesContainerXMLParserDelegate.h"


@implementation ASICloudFilesContainerRequest

@synthesize currentElement, currentContent, currentObject;
@synthesize xmlParserDelegate;

//ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:rackspaceCloudAuthURL]];
//NSMutableDictionary *headers = [[NSMutableDictionary alloc] initWithCapacity:2];
//[headers setObject:username forKey:@"X-Auth-User"];
//[headers setObject:apiKey   forKey:@"X-Auth-Key"];	
//[request setRequestHeaders:headers];
//[headers release];
//return request;

#pragma mark -
#pragma mark Constructors

+ (id)storageRequestWithMethod:(NSString *)method containerName:(NSString *)containerName queryString:(NSString *)queryString {
	NSString *urlString = [NSString stringWithFormat:@"%@/%@%@", [ASICloudFilesRequest storageURL], containerName, queryString];
	//NSLog(@"container request url: %@", urlString);
	ASICloudFilesContainerRequest *request = [[ASICloudFilesContainerRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
	[request setRequestMethod:method];
	[request addRequestHeader:@"X-Auth-Token" value:[ASICloudFilesRequest authToken]];
	return request;
}

+ (id)storageRequestWithMethod:(NSString *)method queryString:(NSString *)queryString {
	//ASICloudFilesRequest *request = [ASICloudFilesRequest storageRequest];
	NSString *urlString = [NSString stringWithFormat:@"%@%@", [ASICloudFilesRequest storageURL], queryString];
	//NSLog(@"container request url: %@", urlString);
	ASICloudFilesContainerRequest *request = [[ASICloudFilesContainerRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
	[request setRequestMethod:method];
	[request addRequestHeader:@"X-Auth-Token" value:[ASICloudFilesRequest authToken]];
	return request;
}

+ (id)storageRequestWithMethod:(NSString *)method {
	return [ASICloudFilesContainerRequest storageRequestWithMethod:method queryString:@""];
}

// HEAD /<api version>/<account>
// HEAD operations against an account are performed to retrieve the number of Containers and the total bytes stored in Cloud Files for the account. This information is returned in two custom headers, X-Account-Container-Count and X-Account-Bytes-Used.
+ (id)accountInfoRequest {
	ASICloudFilesContainerRequest *request = [ASICloudFilesContainerRequest storageRequestWithMethod:@"HEAD"];
	return request;
}

+ (id)listRequestWithLimit:(NSUInteger)limit marker:(NSString *)marker {
	NSString *queryString = [NSString stringWithFormat:@"?format=xml&limit=%i&marker=%@", limit, [marker stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	ASICloudFilesContainerRequest *request = [ASICloudFilesContainerRequest storageRequestWithMethod:@"GET" queryString:queryString];
	return request;
}

+ (id)listRequestWithLimit:(NSUInteger)limit {
	NSString *queryString = [NSString stringWithFormat:@"?format=xml&limit=%i", limit];
	ASICloudFilesContainerRequest *request = [ASICloudFilesContainerRequest storageRequestWithMethod:@"GET" queryString:queryString];
	return request;
}

+ (id)listRequestWithMarker:(NSString *)marker {
	NSString *queryString = [NSString stringWithFormat:@"?format=xml&marker=%@", [marker stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	ASICloudFilesContainerRequest *request = [ASICloudFilesContainerRequest storageRequestWithMethod:@"GET" queryString:queryString];
	return request;
}

// GET /<api version>/<account>/<container>
// Create a request to list all containers
+ (id)listRequest {
	ASICloudFilesContainerRequest *request = [ASICloudFilesContainerRequest storageRequestWithMethod:@"GET" 
																			queryString:@"?format=xml"];
	return request;
}

// PUT /<api version>/<account>/<container>
+ (id)createContainerRequest:(NSString *)containerName {
	ASICloudFilesContainerRequest *request = [ASICloudFilesContainerRequest storageRequestWithMethod:@"PUT" containerName:containerName queryString:@""];
	return request;
}

// DELETE /<api version>/<account>/<container>
+ (id)deleteContainerRequest:(NSString *)containerName {
	ASICloudFilesContainerRequest *request = [ASICloudFilesContainerRequest storageRequestWithMethod:@"DELETE" containerName:containerName queryString:@""];
	return request;
}

#pragma mark -
#pragma mark Response Data

#pragma mark Account Info

- (NSUInteger)containerCount {
	return [[[self responseHeaders] objectForKey:@"X-Account-Container-Count"] intValue];
}

- (NSUInteger)bytesUsed {
	return [[[self responseHeaders] objectForKey:@"X-Account-Bytes-Used"] intValue];
}

#pragma mark Container List

- (NSArray *)containers {
	if (xmlParserDelegate.containerObjects) {
		return xmlParserDelegate.containerObjects;
	}
	
	//NSLog(@"list response data: %@", [self responseString]);
	
	NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:[self responseData]] autorelease];
	if (xmlParserDelegate == nil) {
		xmlParserDelegate = [[ASICloudFilesContainerXMLParserDelegate alloc] init];
	}
	
	[parser setDelegate:xmlParserDelegate];
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	[parser parse];
	
	return xmlParserDelegate.containerObjects;
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
	[currentElement release];
	[currentContent release];
	[currentObject release];
	[xmlParserDelegate release];
	[super dealloc];
}

@end
