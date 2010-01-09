//
//  ASICloudFilesObjectRequest.m
//  iPhone
//
//  Created by Michael Mayo on 1/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ASICloudFilesObjectRequest.h"
#import "ASICloudFilesObject.h"


@implementation ASICloudFilesObjectRequest

@synthesize currentElement, currentContent, currentObject;
@synthesize accountName, containerName;

+ (id)storageRequestWithMethod:(NSString *)method containerName:(NSString *)containerName {
	NSString *urlString = [NSString stringWithFormat:@"%@/%@", [ASICloudFilesRequest storageURL], containerName];
	//NSLog(@"object request url: %@", urlString);
	ASICloudFilesObjectRequest *request = [[ASICloudFilesObjectRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
	[request setRequestMethod:method];
	[request addRequestHeader:@"X-Auth-Token" value:[ASICloudFilesRequest authToken]];
	request.containerName = containerName;
	return request;
}

+ (id)storageRequestWithMethod:(NSString *)method containerName:(NSString *)containerName queryString:(NSString *)queryString {
	NSString *urlString = [NSString stringWithFormat:@"%@/%@%@", [ASICloudFilesRequest storageURL], containerName, queryString];
	//NSLog(@"object request url: %@", urlString);
	ASICloudFilesObjectRequest *request = [[ASICloudFilesObjectRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
	[request setRequestMethod:method];
	[request addRequestHeader:@"X-Auth-Token" value:[ASICloudFilesRequest authToken]];
	request.containerName = containerName;
	return request;
}

+ (id)storageRequestWithMethod:(NSString *)method containerName:(NSString *)containerName objectPath:(NSString *)objectPath {
	NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@", [ASICloudFilesRequest storageURL], containerName, objectPath];
	//NSLog(@"object request url: %@", urlString);
	ASICloudFilesObjectRequest *request = [[ASICloudFilesObjectRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
	[request setRequestMethod:method];
	[request addRequestHeader:@"X-Auth-Token" value:[ASICloudFilesRequest authToken]];
	request.containerName = containerName;
	return request;
}

#pragma mark -
#pragma mark Container Info

+ (id)containerInfoRequest:(NSString *)containerName {
	ASICloudFilesObjectRequest *request = [ASICloudFilesObjectRequest storageRequestWithMethod:@"HEAD" containerName:containerName];
	return request;
}

- (NSUInteger)containerObjectCount {
	return [[[self responseHeaders] objectForKey:@"X-Container-Object-Count"] intValue];
}

- (NSUInteger)containerBytesUsed {
	return [[[self responseHeaders] objectForKey:@"X-Container-Bytes-Used"] intValue];
}

#pragma mark -
#pragma mark Object Info

+ (id)objectInfoRequest:(NSString *)containerName objectPath:(NSString *)objectPath {
	ASICloudFilesObjectRequest *request = [ASICloudFilesObjectRequest storageRequestWithMethod:@"HEAD" containerName:containerName objectPath:objectPath];
	return request;
}

#pragma mark -
#pragma mark List Requests

+ (NSString *)queryStringWithContainer:(NSString *)container limit:(NSUInteger)limit marker:(NSString *)marker prefix:(NSString *)prefix path:(NSString *)path {
	NSString *queryString = @"?format=xml";
	
	if (limit && limit > 0) {
		queryString = [queryString stringByAppendingString:[NSString stringWithFormat:@"&limit=%i", limit]];
	}
	if (marker) {
		queryString = [queryString stringByAppendingString:[NSString stringWithFormat:@"&marker=%@", [marker stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	}
	if (path) {
		queryString = [queryString stringByAppendingString:[NSString stringWithFormat:@"&path=%@", [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	}
	
	return queryString;
}

+ (id)listRequestWithContainer:(NSString *)containerName limit:(NSUInteger)limit marker:(NSString *)marker prefix:(NSString *)prefix path:(NSString *)path {
	NSString *queryString = [ASICloudFilesObjectRequest queryStringWithContainer:containerName limit:limit marker:marker prefix:prefix path:path];
	ASICloudFilesObjectRequest *request = [ASICloudFilesObjectRequest storageRequestWithMethod:@"GET" containerName:containerName queryString:queryString];
	return request;
}

+ (id)listRequestWithContainer:(NSString *)containerName {
	return [ASICloudFilesObjectRequest listRequestWithContainer:containerName limit:0 marker:nil prefix:nil path:nil];
}

+ (id)listRequestWithContainer:(NSString *)containerName limit:(NSUInteger)limit {
	return [ASICloudFilesObjectRequest listRequestWithContainer:containerName limit:limit marker:nil prefix:nil path:nil];
}

+ (id)listRequestWithContainer:(NSString *)containerName limit:(NSUInteger)limit marker:(NSString *)marker {
	return [ASICloudFilesObjectRequest listRequestWithContainer:containerName limit:limit marker:marker prefix:nil path:nil];
}

+ (id)listRequestWithContainer:(NSString *)containerName limit:(NSUInteger)limit marker:(NSString *)marker prefix:(NSString *)prefix {
	return [ASICloudFilesObjectRequest listRequestWithContainer:containerName limit:limit marker:marker prefix:prefix path:nil];
}

+ (id)listRequestWithContainer:(NSString *)containerName limit:(NSUInteger)limit marker:(NSString *)marker path:(NSString *)path {
	return [ASICloudFilesObjectRequest listRequestWithContainer:containerName limit:limit marker:marker prefix:nil path:path];
}

+ (id)listRequestWithContainer:(NSString *)containerName limit:(NSUInteger)limit prefix:(NSString *)prefix {
	return [ASICloudFilesObjectRequest listRequestWithContainer:containerName limit:limit marker:nil prefix:prefix path:nil];
}

+ (id)listRequestWithContainer:(NSString *)containerName limit:(NSUInteger)limit prefix:(NSString *)prefix path:(NSString *)path {
	return [ASICloudFilesObjectRequest listRequestWithContainer:containerName limit:limit marker:nil prefix:prefix path:path];
}

+ (id)listRequestWithContainer:(NSString *)containerName limit:(NSUInteger)limit path:(NSString *)path {
	return [ASICloudFilesObjectRequest listRequestWithContainer:containerName limit:limit marker:nil prefix:nil path:path];
}

+ (id)listRequestWithContainer:(NSString *)containerName marker:(NSString *)marker {
	return [ASICloudFilesObjectRequest listRequestWithContainer:containerName limit:0 marker:marker prefix:nil path:nil];
}

+ (id)listRequestWithContainer:(NSString *)containerName marker:(NSString *)marker prefix:(NSString *)prefix {
	return [ASICloudFilesObjectRequest listRequestWithContainer:containerName limit:0 marker:marker prefix:prefix path:nil];
}

+ (id)listRequestWithContainer:(NSString *)containerName marker:(NSString *)marker path:(NSString *)path {
	return [ASICloudFilesObjectRequest listRequestWithContainer:containerName limit:0 marker:marker prefix:nil path:path];
}

+ (id)listRequestWithContainer:(NSString *)containerName marker:(NSString *)marker prefix:(NSString *)prefix path:(NSString *)path {
	return [ASICloudFilesObjectRequest listRequestWithContainer:containerName limit:0 marker:marker prefix:prefix path:path];
}

+ (id)listRequestWithContainer:(NSString *)containerName prefix:(NSString *)prefix {
	return [ASICloudFilesObjectRequest listRequestWithContainer:containerName limit:0 marker:nil prefix:prefix path:nil];
}

+ (id)listRequestWithContainer:(NSString *)containerName prefix:(NSString *)prefix path:(NSString *)path {
	return [ASICloudFilesObjectRequest listRequestWithContainer:containerName limit:0 marker:nil prefix:prefix path:path];
}

+ (id)listRequestWithContainer:(NSString *)containerName path:(NSString *)path {
	return [ASICloudFilesObjectRequest listRequestWithContainer:containerName limit:0 marker:nil prefix:nil path:path];
}

#pragma mark -
#pragma mark Object List

- (NSArray *)objects {
	if (objects) {
		return objects;
	}
	objects = [[[NSMutableArray alloc] init] autorelease];
	
	//NSLog(@"object list response data: %@", [self responseString]);
	
	NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:[self responseData]] autorelease];
	[parser setDelegate:self];
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	[parser parse];
	return objects;
}

#pragma mark -
#pragma mark GET Object

+ (id)getObjectRequestWithContainer:(NSString *)containerName objectPath:(NSString *)objectPath {
	return [ASICloudFilesObjectRequest storageRequestWithMethod:@"GET" containerName:containerName objectPath:objectPath];
}

- (ASICloudFilesObject *)object {
	ASICloudFilesObject *object = [ASICloudFilesObject object];
	
	NSString *path = [self url].path;
	NSRange range = [path rangeOfString:self.containerName];
	path = [path substringFromIndex:range.location + range.length + 1];
	
	object.name = path;
	object.hash = [[self responseHeaders] objectForKey:@"ETag"];
	object.bytes = [[[self responseHeaders] objectForKey:@"Content-Length"] intValue];
	object.contentType = [[self responseHeaders] objectForKey:@"Content-Type"];
	object.lastModified = [[self responseHeaders] objectForKey:@"Last-Modified"];
	object.metadata = [[NSMutableDictionary alloc] init];
	
	NSDictionary *headers = [self responseHeaders];
	NSArray *keys = [headers allKeys];
	for (int i = 0; i < [keys count]; i++) {
		NSString *key = [keys objectAtIndex:i];
		NSString *value = [headers objectForKey:key];
		NSRange range = [key rangeOfString:@"X-Object-Meta-"];
		
		if (range.location == 0) {
			[object.metadata setObject:value forKey:[key substringFromIndex:range.length]];
		}
	}
	
	object.data = [self responseData];
	
	return object;
}

#pragma mark -
#pragma mark PUT Object

+ (id)putObjectRequestWithContainer:(NSString *)containerName object:(ASICloudFilesObject *)object {
	return [self putObjectRequestWithContainer:containerName objectPath:object.name contentType:object.contentType objectData:object.data metadata:object.metadata etag:nil];
}

+ (id)putObjectRequestWithContainer:(NSString *)containerName objectPath:(NSString *)objectPath contentType:(NSString *)contentType objectData:(NSData *)objectData metadata:(NSDictionary *)metadata etag:(NSString *)etag {
	
	// TODO: etag?
	
	ASICloudFilesObjectRequest *request = [ASICloudFilesObjectRequest storageRequestWithMethod:@"PUT" containerName:containerName objectPath:objectPath];
	[request addRequestHeader:@"Content-Type" value:contentType];
	[request addRequestHeader:@"Content-Length" value:[NSString stringWithFormat:@"%i", objectData.length]];

	// add metadata to headers
	if (metadata) {
		NSArray *keys = [metadata allKeys];
		for (int i = 0; i < [keys count]; i++) {
			NSString *key = [keys objectAtIndex:i];			
			NSString *value = [metadata objectForKey:key];
			[request addRequestHeader:[NSString stringWithFormat:@"X-Object-Meta-%@", key] value:value];
		}
	}	
	
	[request appendPostData:objectData];	
	return request;
}

#pragma mark -
#pragma mark POST Object Metadata

+ (id)postObjectRequestWithContainer:(NSString *)containerName object:(ASICloudFilesObject *)object {
	return [self postObjectRequestWithContainer:containerName objectPath:object.name metadata:object.metadata];
}

+ (id)postObjectRequestWithContainer:(NSString *)containerName objectPath:(NSString *)objectPath metadata:(NSDictionary *)metadata {
	ASICloudFilesObjectRequest *request = [ASICloudFilesObjectRequest storageRequestWithMethod:@"POST" containerName:containerName objectPath:objectPath];
	
	// add metadata to headers
	if (metadata) {
		NSArray *keys = [metadata allKeys];
		for (int i = 0; i < [keys count]; i++) {
			NSString *key = [keys objectAtIndex:i];			
			NSString *value = [metadata objectForKey:key];
			[request addRequestHeader:[NSString stringWithFormat:@"X-Object-Meta-%@", key] value:value];
		}
	}	
	
	return request;
}


#pragma mark -
#pragma mark Delete Object

+ (id)deleteObjectRequestWithContainer:(NSString *)containerName objectPath:(NSString *)objectPath {
	ASICloudFilesObjectRequest *request = [ASICloudFilesObjectRequest storageRequestWithMethod:@"DELETE" containerName:containerName objectPath:objectPath];
	return request;
}

#pragma mark -
#pragma mark XML Parser Delegate

/*
<container name="cf_service">
	<object>
		<name>10-17-2009&#32;9-23-54&#32;PM.png</name>
		<hash>fdc7b0fedf8f304dd02c468567acb6f8</hash>
		<bytes>1621</bytes>
		<content_type>image/png</content_type>
		<last_modified>2009-11-04T19:46:20.192723</last_modified>
	</object>
	<object><name>5253_513598038815_56400223_30531988_4542339_n-59.jpg</name><hash>ec133b3f8cf33cd036b351a85a093009</hash><bytes>36825</bytes><content_type>image/jpeg</content_type><last_modified>2009-09-01T22:46:40.851463</last_modified></object>
	<object><name>7-eguas-59.jpg</name><hash>3d6a1e77aecbe8a7416bab41e88cdfc9</hash><bytes>1234678</bytes><content_type>image/jpeg</content_type><last_modified>2009-09-01T23:21:37.589124</last_modified></object>
</container>
*/
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	[self setCurrentElement:elementName];
	
	if ([elementName isEqualToString:@"object"]) {
		[self setCurrentObject:[ASICloudFilesObject object]];
	}
	[self setCurrentContent:@""];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	if ([elementName isEqualToString:@"name"]) {
		[self currentObject].name = [self currentContent];
	} else if ([elementName isEqualToString:@"hash"]) {
		[self currentObject].hash = [self currentContent];
	} else if ([elementName isEqualToString:@"bytes"]) {
		[self currentObject].bytes = [[self currentContent] intValue];
	} else if ([elementName isEqualToString:@"content_type"]) {
		[self currentObject].contentType = [self currentContent];
	} else if ([elementName isEqualToString:@"last_modified"]) {
		[self currentObject].lastModified = [self dateFromString:[self currentContent]];
	} else if ([elementName isEqualToString:@"object"]) {
		// we're done with this object.  time to move on to the next
		[objects addObject:currentObject];
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
	[accountName release];
	[containerName release];
	[super dealloc];
}

@end
