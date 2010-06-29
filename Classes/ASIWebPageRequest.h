//
//  ASIWebPageRequest.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 29/06/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//
//  EXPERIMENTAL PROOF OF CONCEPT - DO NOT USE

#import "ASIHTTPRequest.h"
#import <tidy/tidy.h>
#import <tidy/buffio.h>
#import <libxml/tree.h>
#import <libxml/parser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

@class ASINetworkQueue;

@interface ASIWebPageRequest : ASIHTTPRequest {
	ASINetworkQueue *externalResourceQueue;
	NSMutableDictionary *resourceList;
	xmlDocPtr doc;

}

+ (NSString *)XHTMLForString:(NSString *)inputHTML error:(NSError **)error;

@end
