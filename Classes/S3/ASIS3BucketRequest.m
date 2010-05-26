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
@property (retain, nonatomic) ASIS3BucketObject *currentObject;
@property (retain) NSMutableArray *objects;
@property (retain) NSMutableArray *commonPrefixes;
@property (assign) BOOL isTruncated;
@end

@implementation ASIS3BucketRequest

- (id)initWithURL:(NSURL *)newURL
{
	self = [super initWithURL:newURL];
	[self setObjects:[[[NSMutableArray alloc] init] autorelease]];
	[self setCommonPrefixes:[[[NSMutableArray alloc] init] autorelease]];
	return self;
}

+ (id)requestWithBucket:(NSString *)bucket
{
	ASIS3BucketRequest *request = [[[self alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@.s3.amazonaws.com",bucket]]] autorelease];
	[request setBucket:bucket];
	return request;
}

+ (id)requestWithBucket:(NSString *)bucket subResource:(NSString *)subResource
{
	ASIS3BucketRequest *request = [[[self alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@.s3.amazonaws.com/?%@",bucket,subResource]]] autorelease];
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
	[objects release];
	[commonPrefixes release];
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
		[queryParts addObject:[NSString stringWithFormat:@"max-keys=%hi",[self maxResultCount]]];
	}
	if ([queryParts count]) 
    {
		NSString* template = @"%@?%@";
		if ([[self subResource] length] > 0) {
			template = @"%@&%@";
		}
		[self setURL:[NSURL URLWithString:[NSString stringWithFormat:template,[[self url] absoluteString],[queryParts componentsJoinedByString:@"&"]]]];
	}
}

- (void)main
{
	[self createQueryString];
	[super main];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"Contents"]) {
		[self setCurrentObject:[ASIS3BucketObject objectWithBucket:[self bucket]]];
	}
	[super parser:parser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if ([elementName isEqualToString:@"Contents"]) {
		[objects addObject:currentObject];
		[self setCurrentObject:nil];
	} else if ([elementName isEqualToString:@"Key"]) {
		[[self currentObject] setKey:[self currentXMLElementContent]];
	} else if ([elementName isEqualToString:@"LastModified"]) {
		[[self currentObject] setLastModified:[[ASIS3Request S3ResponseDateFormatter] dateFromString:[self currentXMLElementContent]]];
	} else if ([elementName isEqualToString:@"ETag"]) {
		[[self currentObject] setETag:[self currentXMLElementContent]];
	} else if ([elementName isEqualToString:@"Size"]) {
		[[self currentObject] setSize:(unsigned long long)[[self currentXMLElementContent] longLongValue]];
	} else if ([elementName isEqualToString:@"ID"]) {
		[[self currentObject] setOwnerID:[self currentXMLElementContent]];
	} else if ([elementName isEqualToString:@"DisplayName"]) {
		[[self currentObject] setOwnerName:[self currentXMLElementContent]];
	} else if ([elementName isEqualToString:@"Prefix"] && [[self currentXMLElementStack] count] > 2 && [[[self currentXMLElementStack] objectAtIndex:[[self currentXMLElementStack] count]-2] isEqualToString:@"CommonPrefixes"]) {
		[[self commonPrefixes] addObject:[self currentXMLElementContent]];
	} else if ([elementName isEqualToString:@"IsTruncated"]) {
		[self setIsTruncated:[[self currentXMLElementContent] isEqualToString:@"true"]];
	} else {
		// Let ASIS3Request look for error messages
		[super parser:parser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
	}
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
@synthesize currentObject;
@synthesize objects;
@synthesize commonPrefixes;
@synthesize prefix;
@synthesize marker;
@synthesize maxResultCount;
@synthesize delimiter;
@synthesize isTruncated;

@end
