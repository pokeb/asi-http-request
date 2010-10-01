//
//  ASIWebPageRequest.m
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 29/06/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//
//  This is an EXPERIMENTAL class - use at your own risk!

#import "ASIWebPageRequest.h"
#import "ASINetworkQueue.h"

static xmlChar *xpathExpr = (xmlChar *)"//link[@rel = \"stylesheet\"]/@href|//script/@src|//img/@src";

static NSLock *xmlParsingLock = nil;
static NSMutableArray *requestsUsingXMLParser = nil;

@interface ASIWebPageRequest ()
- (void)readResourceURLs;
- (void)updateResourceURLs;
- (void)parseAsHTML;
- (void)parseAsCSS;
@property (retain, nonatomic) ASINetworkQueue *externalResourceQueue;
@property (retain, nonatomic) NSMutableDictionary *resourceList;
@end

@implementation ASIWebPageRequest

+ (void)initialize
{
	if (self == [ASIWebPageRequest class]) {
		xmlParsingLock = [[NSLock alloc] init];
		requestsUsingXMLParser = [[NSMutableArray alloc] init];
	}
}

- (void)markAsFinished
{
}

- (void)requestFinished
{
	webContentType = ASINotParsedWebContentType;
	NSString *contentType = [[[self responseHeaders] objectForKey:@"Content-Type"] lowercaseString];
	contentType = [[contentType componentsSeparatedByString:@";"] objectAtIndex:0];
	if ([contentType isEqualToString:@"text/html"] || [contentType isEqualToString:@"text/xhtml"] || [contentType isEqualToString:@"text/xhtml+xml"] || [contentType isEqualToString:@"application/xhtml+xml"]) {
		[self parseAsHTML];
		return;
	} else if ([contentType isEqualToString:@"text/css"]) {
		[self parseAsCSS];
		return;
	}
	[super requestFinished];
	[(id)super markAsFinished];
}

- (void)parseAsCSS
{
	webContentType = ASICSSWebContentType;
	NSString *responseCSS = [self responseString];
	if (!responseCSS) {
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:100 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unable to read HTML string from response",NSLocalizedDescriptionKey,nil]]];
		return;
	}
	NSMutableArray *urls = [NSMutableArray array];
	NSScanner *scanner = [NSScanner scannerWithString:responseCSS];
	[scanner setCaseSensitive:NO];
	while (1) {
		NSString *theURL = nil;
		[scanner scanUpToString:@"url(" intoString:NULL];
		[scanner scanString:@"url(" intoString:NULL];
		[scanner scanUpToString:@")" intoString:&theURL];
		if (!theURL) {
			break;
		}
		[urls addObject:theURL];
	}

	[self setResourceList:[NSMutableDictionary dictionary]];

	for (NSString *theURL in urls) {
		if (([[theURL substringToIndex:1] isEqualToString:@"'"] && [[theURL substringFromIndex:[theURL length]-1] isEqualToString:@"'"]) ||([[theURL substringToIndex:1] isEqualToString:@"\""] && [[theURL substringFromIndex:[theURL length]-1] isEqualToString:@"\""])) {
			theURL = [theURL substringWithRange:NSMakeRange(1,[theURL length]-2)];
		}
		NSURL *newURL = [NSURL URLWithString:theURL relativeToURL:[self url]];
		if (newURL) {
			[[self resourceList] setObject:[NSMutableDictionary dictionary] forKey:theURL];
		}
	}

	if (![[self resourceList] count]) {
		[super requestFinished];
		[(id)super markAsFinished];
		return;
	}

	// Create a new request for every item in the queue
	[[self externalResourceQueue] cancelAllOperations];
	[self setExternalResourceQueue:[ASINetworkQueue queue]];
	[[self externalResourceQueue] setDelegate:self];
	[[self externalResourceQueue] setQueueDidFinishSelector:@selector(finishedFetchingExternalResources:)];
	[[self externalResourceQueue] setRequestDidFinishSelector:@selector(externalResourceFetchSucceeded:)];
	[[self externalResourceQueue] setRequestDidFailSelector:@selector(externalResourceFetchFailed:)];
	[[self externalResourceQueue] setDownloadProgressDelegate:[self downloadProgressDelegate]];
	for (NSString *theURL in [[self resourceList] keyEnumerator]) {
		ASIWebPageRequest *externalResourceRequest = [ASIWebPageRequest requestWithURL:[NSURL URLWithString:theURL relativeToURL:[self url]]];
		[externalResourceRequest setRequestHeaders:[self requestHeaders]];
		[externalResourceRequest setDownloadCache:[self downloadCache]];
		[externalResourceRequest setUserInfo:[NSDictionary dictionaryWithObject:theURL forKey:@"Path"]];
		[[self externalResourceQueue] addOperation:externalResourceRequest];
	}

	[[self externalResourceQueue] go];

}

- (void)parseAsHTML
{
	webContentType = ASIHTMLWebContentType;
	NSString *responseHTML = [self responseString];
	if (!responseHTML) {
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:100 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unable to read HTML string from response",NSLocalizedDescriptionKey,nil]]];
		return;
	}

	NSError *err = nil;
	responseHTML = [ASIWebPageRequest XHTMLForString:responseHTML error:&err];
	if (err) {
		[self failWithError:err];
		return;
	} else if (!responseHTML) {
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:101 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unable to convert response string to XHTML",NSLocalizedDescriptionKey,nil]]];
		return;	
	}

	// Only allow parsing of a single document at a time
	[xmlParsingLock lock];

	if (![requestsUsingXMLParser count]) {
		xmlInitParser();
	}
	[requestsUsingXMLParser addObject:self];

	// Strip the namespace, because it makes the xpath query a pain
	responseHTML = [responseHTML stringByReplacingOccurrencesOfString:@" xmlns=\"http://www.w3.org/1999/xhtml\"" withString:@""];

	NSData *data = [responseHTML dataUsingEncoding:NSUTF8StringEncoding];

    /* Load XML document */
    doc = xmlParseMemory([data bytes], [data length]);
    if (doc == NULL) {
		xmlFreeDoc(doc);
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:101 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Error: unable to parse reponse XML",NSLocalizedDescriptionKey,nil]]];
		return;
    }
	
	[self setResourceList:[NSMutableDictionary dictionary]];

    // Populate the list of URLS to download
    [self readResourceURLs];

	[xmlParsingLock unlock];

	if (![[self resourceList] count]) {
		[super requestFinished];
		[(id)super markAsFinished];
		return;
	}
	
	// Create a new request for every item in the queue
	[[self externalResourceQueue] cancelAllOperations];
	[self setExternalResourceQueue:[ASINetworkQueue queue]];
	[[self externalResourceQueue] setDelegate:self];
	[[self externalResourceQueue] setQueueDidFinishSelector:@selector(finishedFetchingExternalResources:)];
	[[self externalResourceQueue] setRequestDidFinishSelector:@selector(externalResourceFetchSucceeded:)];
	[[self externalResourceQueue] setRequestDidFailSelector:@selector(externalResourceFetchFailed:)];
	[[self externalResourceQueue] setDownloadProgressDelegate:[self downloadProgressDelegate]];
	for (NSString *theURL in [[self resourceList] keyEnumerator]) {
		ASIWebPageRequest *externalResourceRequest = [ASIWebPageRequest requestWithURL:[NSURL URLWithString:theURL relativeToURL:[self url]]];
		[externalResourceRequest setRequestHeaders:[self requestHeaders]];
		[externalResourceRequest setDownloadCache:[self downloadCache]];
		[externalResourceRequest setUserInfo:[NSDictionary dictionaryWithObject:theURL forKey:@"Path"]];
		[[self externalResourceQueue] addOperation:externalResourceRequest];
	}

	[[self externalResourceQueue] go];
}


- (void)externalResourceFetchSucceeded:(ASIHTTPRequest *)externalResourceRequest
{
	NSString *originalPath = [[externalResourceRequest userInfo] objectForKey:@"Path"];
	NSMutableDictionary *requestResponse = [[self resourceList] objectForKey:originalPath];
	NSString *contentType = [[externalResourceRequest responseHeaders] objectForKey:@"Content-Type"];
	if (!contentType) {
		contentType = @"application/octet-stream";
	}
	[requestResponse setObject:contentType forKey:@"ContentType"];
	[requestResponse setObject:[externalResourceRequest responseData] forKey:@"Data"];
}

- (void)externalResourceFetchFailed:(ASIHTTPRequest *)externalResourceRequest
{
	[self failWithError:[externalResourceRequest error]];
}

- (void)finishedFetchingExternalResources:(ASINetworkQueue *)queue
{
	if (webContentType == ASICSSWebContentType) {
		NSMutableString *parsedResponse = [[[self responseString] mutableCopy] autorelease];
		if (![self error]) {
			for (NSString *resource in [[self resourceList] keyEnumerator]) {
				NSDictionary *resourceInfo = [[self resourceList] objectForKey:resource];
				NSData *data = [resourceInfo objectForKey:@"Data"];
				NSString *contentType = [resourceInfo objectForKey:@"ContentType"];
				if (data && contentType) {
					if (data && contentType) {
						NSString *newData = [NSString stringWithFormat:@"data:%@;base64,",contentType];
						newData = [newData stringByAppendingString:[ASIHTTPRequest base64forData:data]];
						[parsedResponse replaceOccurrencesOfString:resource withString:newData options:0 range:NSMakeRange(0, [parsedResponse length])];
					}
				}
			}
		}
		[self setRawResponseData:(id)[parsedResponse dataUsingEncoding:NSUTF8StringEncoding]];

	} else {
		[xmlParsingLock lock];

		[self updateResourceURLs];
		xmlChar *bytes = nil;
		int size = 0;
		xmlDocDumpMemory(doc,&bytes,&size);
		[self setRawResponseData:[[[NSMutableData alloc] initWithBytes:bytes length:size] autorelease]];

		xmlFreeDoc(doc);
		doc = nil;

		[requestsUsingXMLParser removeObject:self];
		if (![requestsUsingXMLParser count]) {
			xmlCleanupParser();
		}
		[xmlParsingLock unlock];
	}

	[self setResponseEncoding:NSUTF8StringEncoding];
	NSMutableDictionary *newHeaders = [[[self responseHeaders] mutableCopy] autorelease];
	[newHeaders removeObjectForKey:@"Content-Encoding"];
	[self setResponseHeaders:newHeaders];

	[super requestFinished];
	[(id)super markAsFinished];
}

- (void)readResourceURLs
{
	/* Create xpath evaluation context */
    xmlXPathContextPtr xpathCtx = xmlXPathNewContext(doc);
    if(xpathCtx == NULL) {
		xmlFreeDoc(doc);
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:101 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Error: unable to create new XPath context",NSLocalizedDescriptionKey,nil]]];
		return;
    }
    
    /* Evaluate xpath expression */
    xmlXPathObjectPtr xpathObj = xmlXPathEvalExpression(xpathExpr, xpathCtx);
    if(xpathObj == NULL) {
        xmlXPathFreeContext(xpathCtx); 
        xmlFreeDoc(doc); 
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:101 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Error: unable to evaluate XPath expression!",NSLocalizedDescriptionKey,nil]]];
		return;
    }
	
	xmlNodeSetPtr nodes = xpathObj->nodesetval;

    int size = (nodes) ? nodes->nodeNr : 0;
	int i;
    for(i = size - 1; i >= 0; i--) {
		assert(nodes->nodeTab[i]);
		NSString *theURL = [NSString stringWithCString:(char *)xmlNodeGetContent(nodes->nodeTab[i]) encoding:NSUTF8StringEncoding];
		[resourceList setObject:[NSMutableDictionary dictionary] forKey:theURL];
		if (nodes->nodeTab[i]->type != XML_NAMESPACE_DECL) {
			nodes->nodeTab[i] = NULL;
		}
    }
	
	xmlXPathFreeObject(xpathObj);
    xmlXPathFreeContext(xpathCtx); 
}


- (void)updateResourceURLs
{
	/* Create xpath evaluation context */
	xmlXPathContextPtr xpathCtx = xmlXPathNewContext(doc);
	if(xpathCtx == NULL) {
		xmlFreeDoc(doc);
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:101 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Error: unable to create new XPath context",NSLocalizedDescriptionKey,nil]]];
		return;
	}

 	/* Evaluate xpath expression */
	xmlXPathObjectPtr xpathObj = xmlXPathEvalExpression(xpathExpr, xpathCtx);
	if(xpathObj == NULL) {
		xmlXPathFreeContext(xpathCtx);
		xmlFreeDoc(doc);
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:101 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Error: unable to evaluate XPath expression!",NSLocalizedDescriptionKey,nil]]];
		return;
	}

	xmlNodeSetPtr nodes = xpathObj->nodesetval;
	int size = (nodes) ? nodes->nodeNr : 0;
	int i;
	for(i = size - 1; i >= 0; i--) {
		assert(nodes->nodeTab[i]);
		NSString *theURL = [NSString stringWithCString:(char *)xmlNodeGetContent(nodes->nodeTab[i]) encoding:NSUTF8StringEncoding];
		NSData *data = [[resourceList objectForKey:theURL] objectForKey:@"Data"];
		NSString *contentType = [[resourceList objectForKey:theURL] objectForKey:@"ContentType"];
		if (data && contentType) {
			NSString *newData = [NSString stringWithFormat:@"data:%@;base64,",contentType];
			newData = [newData stringByAppendingString:[ASIHTTPRequest base64forData:data]];
			xmlNodeSetContent(nodes->nodeTab[i], (xmlChar *)[newData cStringUsingEncoding:NSUTF8StringEncoding]);
		}
		if (nodes->nodeTab[i]->type != XML_NAMESPACE_DECL) {
			nodes->nodeTab[i] = NULL;
		}
	}
	xmlXPathFreeObject(xpathObj);
	xmlXPathFreeContext(xpathCtx);
}

+ (NSString *)XHTMLForString:(NSString *)inputHTML error:(NSError **)error
{
	const char* input = [inputHTML cStringUsingEncoding:NSUTF8StringEncoding];
	TidyBuffer output = {0,0,0,0};
	TidyBuffer errbuf = {0,0,0,0};
	int rc = -1;
	Bool ok;
	
	TidyDoc tdoc = tidyCreate();
	
	ok = tidyOptSetBool(tdoc, TidyXhtmlOut, yes);
	if (ok) {
		rc = tidySetErrorBuffer(tdoc, &errbuf);
	}
	
	if (rc >= 0) {
		rc = (tidyOptSetBool(tdoc, TidyXmlDecl, yes) ? rc : -1 );
		rc = (tidyOptSetValue(tdoc, TidyCharEncoding, "utf8") ? rc : -1 );
		rc = (tidyOptSetValue(tdoc, TidyDoctype, "strict") ? rc : -1 );
		// Stop tidy stripping HTML 5 tags
		rc = (tidyOptSetValue(tdoc, TidyBlockTags, "header, section, nav, footer, article, audio, video") ? rc : -1);
	}
	
	if (rc >= 0) {
		rc = tidyParseString(tdoc, input);
	}
	if (rc >= 0) {
		rc = tidyCleanAndRepair(tdoc);
	}
	if (rc >= 0) {
		rc = tidyRunDiagnostics(tdoc);
	}
	
	if (rc > 1) {
		rc = (tidyOptSetBool(tdoc, TidyForceOutput, yes) ? rc : -1 );
	}
	if (rc >= 0) {
		rc = tidySaveBuffer(tdoc, &output);
	}
	
	if (rc < 0) {
		*error = [NSError errorWithDomain:NetworkRequestErrorDomain code:102 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Failed to tidy HTML with error code %d",rc],NSLocalizedDescriptionKey,nil]];
		return nil;
	}

	NSString *xhtml = [[[NSString alloc] initWithBytes:output.bp length:output.size encoding:NSUTF8StringEncoding] autorelease];
	
	tidyBufFree(&output);
	tidyBufFree(&errbuf);
	tidyRelease(tdoc);
	
	return xhtml;
}

@synthesize externalResourceQueue;
@synthesize resourceList;
@end
