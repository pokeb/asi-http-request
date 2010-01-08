//
//  ASICloudFilesContainerRequest.m
//  iPhone
//
//  Created by Michael Mayo on 1/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ASICloudFilesContainerRequest.h"
#import "ASICloudFilesContainer.h"


@implementation ASICloudFilesContainerRequest

@synthesize currentElement, currentContent, currentObject;

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
	if (containerObjects) {
		return containerObjects;
	}
	containerObjects = [[[NSMutableArray alloc] init] autorelease];
	
	//NSLog(@"list response data: %@", [self responseString]);
	
	NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:[self responseData]] autorelease];
	[parser setDelegate:self];
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	[parser parse];
	return containerObjects;
}

#pragma mark -
#pragma mark XML Parser Delegate

/*
<account name="MossoCloudFS_56ad0327-43d6-4ac4-9883-797f5690238e">
	<container><name>bigdir</name><count>1536</count><bytes>10752</bytes></container>
	<container><name>cf_service</name><count>35</count><bytes>66151933</bytes></container>
	<container><name>elcamino</name><count>15</count><bytes>162457114</bytes></container>
	<container><name>laptop&#32;migration</name><count>15</count><bytes>225656510</bytes></container>
	<container><name>mike&#32;mayo</name><count>2</count><bytes>499581</bytes></container>
	<container><name>overhrd.com</name><count>12</count><bytes>205775052</bytes></container>
	<container><name>personal</name><count>2</count><bytes>14158285</bytes></container>
	<container><name>playground</name><count>4</count><bytes>2040999</bytes></container>
	<container><name>pubcamino</name><count>1</count><bytes>219946</bytes></container>
	<container><name>pubtest2</name><count>0</count><bytes>0</bytes></container>
	<container><name>refreshtest</name><count>0</count><bytes>0</bytes></container>
	<container><name>testfromapp</name><count>1</count><bytes>234288</bytes></container>
	<container><name>wadecrash</name><count>5</count><bytes>19839804</bytes></container>
</account>
*/
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	[self setCurrentElement:elementName];
	
	if ([elementName isEqualToString:@"container"]) {
		[self setCurrentObject:[ASICloudFilesContainer container]];
	}
	[self setCurrentContent:@""];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	if ([elementName isEqualToString:@"name"]) {
		[self currentObject].name = [self currentContent];
	} else if ([elementName isEqualToString:@"count"]) {
		//[[self currentObject] setKey:[self currentContent]];
		[self currentObject].count = [[self currentContent] intValue];
	} else if ([elementName isEqualToString:@"bytes"]) {
		[self currentObject].bytes = [[self currentContent] intValue];
	} else if ([elementName isEqualToString:@"container"]) {
		// we're done with this container.  time to move on to the next
		[containerObjects addObject:currentObject];
		[self setCurrentObject:nil];
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	[self setCurrentContent:[[self currentContent] stringByAppendingString:string]];
}

- (void)dealloc {
	[currentElement release];
	[currentContent release];
	[currentObject release];
	[super dealloc];
}

@end
