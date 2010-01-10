//
//  ASICloudFilesContainerXMLParserDelegate.m
//  iPhone
//
//  Created by Michael Mayo on 1/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ASICloudFilesContainerXMLParserDelegate.h"
#import "ASICloudFilesContainer.h"


@implementation ASICloudFilesContainerXMLParserDelegate

@synthesize containerObjects, currentElement, currentContent, currentObject;

#pragma mark -
#pragma mark XML Parser Delegate

/*
 
 <container>
 <name>playground</name>
 <cdn_enabled>True</cdn_enabled>
 <ttl>259200</ttl>
 <cdn_url>http://c0023891.cdn.cloudfiles.rackspacecloud.com</cdn_url>
 <log_retention>True</log_retention>
 <referrer_acl></referrer_acl>
 <useragent_acl></useragent_acl>
 </container>
 
 
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
	
	NSLog(@"start %@", elementName);
	
	if ([elementName isEqualToString:@"container"]) {
		[self setCurrentObject:[ASICloudFilesContainer container]];
	}
	[self setCurrentContent:@""];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {

	NSLog(@"end %@", elementName);

	if ([elementName isEqualToString:@"name"]) {
		[self currentObject].name = [self currentContent];
	} else if ([elementName isEqualToString:@"count"]) {
		//[[self currentObject] setKey:[self currentContent]];
		[self currentObject].count = [[self currentContent] intValue];
	} else if ([elementName isEqualToString:@"bytes"]) {
		[self currentObject].bytes = [[self currentContent] intValue];
	} else if ([elementName isEqualToString:@"container"]) {
		// we're done with this container.  time to move on to the next
		if (containerObjects == nil) {
			containerObjects = [[NSMutableArray alloc] init];
		}
		[containerObjects addObject:currentObject];
		[self setCurrentObject:nil];
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	[self setCurrentContent:[[self currentContent] stringByAppendingString:string]];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
	[containerObjects release];
	[currentElement release];
	[currentContent release];
	[currentObject release];
	[super dealloc];
}

@end
