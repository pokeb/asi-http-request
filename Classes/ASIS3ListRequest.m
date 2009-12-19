//
//  ASIS3ListRequest.m
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 13/07/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//
#import "ASIS3ListRequest.h"
#import "ASIS3BucketObject.h"


static NSDateFormatter *dateFormatter = nil;

// Private stuff
@interface ASIS3ListRequest ()
	@property (retain, nonatomic) NSString *currentContent;
	@property (retain, nonatomic) NSString *currentElement;
	@property (retain, nonatomic) ASIS3BucketObject *currentObject;
	@property (retain, nonatomic) NSMutableArray *objects;
@end

@implementation ASIS3ListRequest

+ (void)initialize
{
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease]];
	[dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'.000Z'"];
}

+ (id)listRequestWithBucket:(NSString *)bucket
{
	ASIS3ListRequest *request = [[[self alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@.s3.amazonaws.com",bucket]]] autorelease];
	[request setBucket:bucket];
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
	[super dealloc];
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

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	[self setCurrentContent:[[self currentContent] stringByAppendingString:string]];
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
	ASIS3ListRequest *newRequest = [super copyWithZone:zone];
	[newRequest setPrefix:[self prefix]];
	[newRequest setMarker:[self marker]];
	[newRequest setMaxResultCount:[self maxResultCount]];
	[newRequest setDelimiter:[self path]];
	return newRequest;
}


@synthesize currentContent;
@synthesize currentElement;
@synthesize currentObject;
@synthesize objects;
@synthesize prefix;
@synthesize marker;
@synthesize maxResultCount;
@synthesize delimiter;
@end
