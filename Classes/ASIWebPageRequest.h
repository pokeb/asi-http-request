//
//  ASIWebPageRequest.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 29/06/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//
//  This is an EXPERIMENTAL class - use at your own risk!
//  Known issue: You cannot use startSychronous with an ASIWebPageRequest

#import "ASIHTTPRequest.h"
#import <tidy/tidy.h>
#import <tidy/buffio.h>
#import <libxml/tree.h>
#import <libxml/parser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

@class ASINetworkQueue;

typedef enum _ASIWebContentType {
    ASINotParsedWebContentType = 0,
    ASIHTMLWebContentType = 1,
    ASICSSWebContentType = 2
} ASIWebContentType;

@interface ASIWebPageRequest : ASIHTTPRequest {
	ASINetworkQueue *externalResourceQueue;
	NSMutableDictionary *resourceList;
	xmlDocPtr doc;
	ASIWebContentType webContentType;
}

+ (NSString *)XHTMLForString:(NSString *)inputHTML error:(NSError **)error;


@end
