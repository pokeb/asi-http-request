//
//  ASIS3ServiceRequest.m
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 16/03/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//

#import "ASIS3ServiceRequest.h"
#import "ASIS3Bucket.h"

// Private stuff
@interface ASIS3ServiceRequest ()
@property (retain, nonatomic) NSMutableArray *buckets;
@property (retain, nonatomic) NSString *currentContent;
@property (retain, nonatomic) NSString *currentElement;
@property (retain, nonatomic) ASIS3Bucket *currentBucket;
@property (retain, nonatomic) NSString *ownerID;
@property (retain, nonatomic) NSString *ownerName;
@end

@implementation ASIS3ServiceRequest

+ (id)serviceRequest
{
	return [[[self alloc] initWithURL:[NSURL URLWithString:@"http://s3.amazonaws.com"]] autorelease];
}

- (void)dealloc
{
	[buckets release];
	[currentContent release];
	[currentElement release];
	[currentBucket release];
	[ownerID release];
	[ownerName release];
	[super dealloc];
}

- (NSArray *)allBuckets
{
	if ([self buckets]) {
		return [self buckets];
	}
	[self setBuckets:[[[NSMutableArray alloc] init] autorelease]];
	NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:[self responseData]] autorelease];
	[parser setDelegate:self];
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	[parser parse];
	return [self buckets];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	[self setCurrentElement:elementName];
	
	if ([elementName isEqualToString:@"Bucket"]) {
		[self setCurrentBucket:[ASIS3Bucket bucketWithOwnerID:[self ownerID] ownerName:[self ownerName]]];
	}
	[self setCurrentContent:@""];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if ([elementName isEqualToString:@"Bucket"]) {
		[[self buckets] addObject:[self currentBucket]];
		[self setCurrentBucket:nil];
	} else if ([elementName isEqualToString:@"Name"]) {
		[[self currentBucket] setName:[self currentContent]];
	} else if ([elementName isEqualToString:@"CreationDate"]) {
		[[self currentBucket] setCreationDate:[[ASIS3Request dateFormatter] dateFromString:[self currentContent]]];
	} else if ([elementName isEqualToString:@"ID"]) {
		[self setOwnerID:[self currentContent]];
	} else if ([elementName isEqualToString:@"DisplayName"]) {
		[self setOwnerName:[self currentContent]];
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	[self setCurrentContent:[[self currentContent] stringByAppendingString:string]];
}

@synthesize buckets;
@synthesize currentContent;
@synthesize currentElement;
@synthesize currentBucket;
@synthesize ownerID;
@synthesize ownerName;
@end
