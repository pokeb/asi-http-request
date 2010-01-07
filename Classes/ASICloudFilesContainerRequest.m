//
//  ASICloudFilesContainerRequest.m
//  iPhone
//
//  Created by Michael Mayo on 1/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ASICloudFilesContainerRequest.h"


@implementation ASICloudFilesContainerRequest

//ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:rackspaceCloudAuthURL]];
//NSMutableDictionary *headers = [[NSMutableDictionary alloc] initWithCapacity:2];
//[headers setObject:username forKey:@"X-Auth-User"];
//[headers setObject:apiKey   forKey:@"X-Auth-Key"];	
//[request setRequestHeaders:headers];
//[headers release];
//return request;

#pragma mark -
#pragma mark Constructors

+ (id)storageRequestWithMethod:(NSString *)method {
	//ASICloudFilesRequest *request = [ASICloudFilesRequest storageRequest];
	ASICloudFilesContainerRequest *request = [[ASICloudFilesContainerRequest alloc] initWithURL:[NSURL URLWithString:[ASICloudFilesRequest storageURL]]];
	[request setRequestMethod:method];
	NSMutableDictionary *headers = [[NSMutableDictionary alloc] initWithCapacity:1];
	[headers setObject:[ASICloudFilesRequest authToken] forKey:@"X-Auth-Token"];
	[request setRequestHeaders:headers];
	[headers release];
	return request;
}

// HEAD /<api version>/<account>
// HEAD operations against an account are performed to retrieve the number of Containers and the total bytes stored in Cloud Files for the account. This information is returned in two custom headers, X-Account-Container-Count and X-Account-Bytes-Used.
+ (id)accountInfoRequest {
	ASICloudFilesContainerRequest *request = [ASICloudFilesContainerRequest storageRequestWithMethod:@"HEAD"];
	return request;
}

// GET /<api version>/<account>/<container>
// Create a request to list all containers
+ (id)listRequest {
	ASICloudFilesContainerRequest *request = [ASICloudFilesContainerRequest storageRequestWithMethod:@"GET"];
	return request;
}

// PUT /<api version>/<account>/<container>
+ (id)createContainerRequest:(NSString *)containerName {
	ASICloudFilesContainerRequest *request = [ASICloudFilesContainerRequest storageRequestWithMethod:@"PUT"];
	return request;
}

// DELETE /<api version>/<account>/<container>
+ (id)deleteContainerRequest:(NSString *)containerName {
	ASICloudFilesContainerRequest *request = [ASICloudFilesContainerRequest storageRequestWithMethod:@"DELETE"];
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
	if (containerNames) {
		return containerNames;
	}
	containerNames = [[[NSMutableArray alloc] init] autorelease];
	NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:[self responseData]] autorelease];
	[parser setDelegate:self];
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	[parser parse];
	return containerNames;
}

#pragma mark -
#pragma mark XML Parser Delegate

/*
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	[self setCurrentElement:elementName];
	
	if ([elementName isEqualToString:@"Contents"]) {
		[self setCurrentObject:[ASIS3BucketObject objectWithBucket:[self bucket]]];
	}
	[self setCurrentContent:@""];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	if ([elementName isEqualToString:@"Contents"]) {
		[objects addObject:currentObject];
		[self setCurrentObject:nil];
	} else if ([elementName isEqualToString:@"Key"]) {
		[[self currentObject] setKey:[self currentContent]];
	} else if ([elementName isEqualToString:@"LastModified"]) {
		[[self currentObject] setLastModified:[dateFormatter dateFromString:[self currentContent]]];
	} else if ([elementName isEqualToString:@"ETag"]) {
		[[self currentObject] setETag:[self currentContent]];
	} else if ([elementName isEqualToString:@"Size"]) {
		[[self currentObject] setSize:(unsigned long long)[[self currentContent] longLongValue]];
	} else if ([elementName isEqualToString:@"ID"]) {
		[[self currentObject] setOwnerID:[self currentContent]];
	} else if ([elementName isEqualToString:@"DisplayName"]) {
		[[self currentObject] setOwnerName:[self currentContent]];
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	[self setCurrentContent:[[self currentContent] stringByAppendingString:string]];
}
*/

@end
