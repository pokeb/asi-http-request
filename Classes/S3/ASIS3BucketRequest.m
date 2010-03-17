//
//  ASIS3BucketRequest.m
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 16/03/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//

#import "ASIS3BucketRequest.h"
#import "ASIS3BucketObject.h"


// Private stuff
@interface ASIS3BucketRequest ()
@property (retain, nonatomic) NSString *currentContent;
@property (retain, nonatomic) NSString *currentElement;
@property (retain, nonatomic) ASIS3BucketObject *currentObject;
@property (retain, nonatomic) NSMutableArray *objects;
@end

@implementation ASIS3BucketRequest

+ (id)requestWithBucket:(NSString *)bucket
{
	ASIS3ObjectRequest *request = [[[self alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@.s3.amazonaws.com",bucket]]] autorelease];
	[request setBucket:bucket];
	return request;
}

+ (id)requestWithBucket:(NSString *)bucket subResource:(NSString *)subResource
{
	ASIS3ObjectRequest *request = [[[self alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@.s3.amazonaws.com/?%@",bucket,subResource]]] autorelease];
	[request setBucket:bucket];
	[request setSubResource:subResource];
	return request;
}


+ (id)PUTRequestWithBucket:(NSString *)bucket
{
	ASIS3BucketRequest *request = [self requestWithBucket:bucket];
	[request setRequestMethod:@"PUT"];
	return request;
}


+ (id)DELETERequestWithBucket:(NSString *)bucket
{
	ASIS3BucketRequest *request = [self requestWithBucket:bucket];
	[request setRequestMethod:@"DELETE"];
	return request;
}

- (void)dealloc
{
	[currentObject release];
	[currentElement release];
	[currentContent release];
	[objects release];
	[prefix release];
	[marker release];
	[delimiter release];
	[subResource release];
	[bucket release];
	[super dealloc];
}

- (NSString *)canonicalizedResource
{
	if ([self subResource]) {
		return [NSString stringWithFormat:@"/%@/?%@",[self bucket],[self subResource]];
	} 
	return [NSString stringWithFormat:@"/%@/",[self bucket]];
}

- (void)createQueryString
{
	NSMutableArray *queryParts = [[[NSMutableArray alloc] init] autorelease];
	if ([self prefix]) {
		[queryParts addObject:[NSString stringWithFormat:@"prefix=%@",[[self prefix] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	}
	if ([self marker]) {
		[queryParts addObject:[NSString stringWithFormat:@"marker=%@",[[self marker] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	}
	if ([self delimiter]) {
		[queryParts addObject:[NSString stringWithFormat:@"delimiter=%@",[[self delimiter] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	}
	if ([self maxResultCount] > 0) {
		[queryParts addObject:[NSString stringWithFormat:@"delimiter=%hi",[self maxResultCount]]];
	}
	if ([queryParts count]) {
		[self setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",[[self url] absoluteString],[queryParts componentsJoinedByString:@"&"]]]];
	}
}

- (void)main
{
	[self createQueryString];
	[super main];
}

- (NSArray *)bucketObjects
{
	if ([self objects]) {
		return [self objects];
	}
	[self setObjects:[[[NSMutableArray alloc] init] autorelease]];
	NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:[self responseData]] autorelease];
	[parser setDelegate:self];
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	[parser parse];
	return [self objects];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	[self setCurrentElement:elementName];
	
	if ([elementName isEqualToString:@"Contents"]) {
		[self setCurrentObject:[ASIS3BucketObject objectWithBucket:[self bucket]]];
	}
	[self setCurrentContent:@""];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if ([elementName isEqualToString:@"Contents"]) {
		[objects addObject:currentObject];
		[self setCurrentObject:nil];
	} else if ([elementName isEqualToString:@"Key"]) {
		[[self currentObject] setKey:[self currentContent]];
	} else if ([elementName isEqualToString:@"LastModified"]) {
		[[self currentObject] setLastModified:[[ASIS3Request dateFormatter] dateFromString:[self currentContent]]];
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

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	[self setCurrentContent:[[self currentContent] stringByAppendingString:string]];
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
	ASIS3BucketRequest *newRequest = [super copyWithZone:zone];
	[newRequest setBucket:[self bucket]];
	[newRequest setSubResource:[self subResource]];
	[newRequest setPrefix:[self prefix]];
	[newRequest setMarker:[self marker]];
	[newRequest setMaxResultCount:[self maxResultCount]];
	[newRequest setDelimiter:[self delimiter]];
	return newRequest;
}

@synthesize bucket;
@synthesize subResource;
@synthesize currentContent;
@synthesize currentElement;
@synthesize currentObject;
@synthesize objects;
@synthesize prefix;
@synthesize marker;
@synthesize maxResultCount;
@synthesize delimiter;
@end
