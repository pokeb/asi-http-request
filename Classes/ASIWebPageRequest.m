//
//  ASIWebPageRequest.m
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 29/06/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//
//  EXPERIMENTAL PROOF OF CONCEPT - DO NOT USE

#import "ASIWebPageRequest.h"
#import "ASINetworkQueue.h"


static xmlChar *xpathExpr = (xmlChar *)"//link[@rel = \"stylesheet\"]/@href|//script/@src|//img/@src";

@interface ASIWebPageRequest ()
- (void)readResourceURLs;
- (void)updateResourceURLs;
- (void)cleanUp;
@property (retain, nonatomic) ASINetworkQueue *externalResourceQueue;
@property (retain, nonatomic) NSMutableDictionary *resourceList;
@end

@implementation ASIWebPageRequest

- (void)markAsFinished
{
}

- (void)requestFinished
{
	NSString *responseHTML = [self responseString];
	if (!responseHTML) {
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:100 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unable to read HTML string from response",NSLocalizedDescriptionKey,nil]]];
		return;
	}
	NSError *err = nil;
	responseHTML = [ASIWebPageRequest XHTMLForString:[self responseString] error:&err];
	if (err) {
		[self failWithError:err];
		return;
	} else if (!responseHTML) {
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:101 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unable to convert response string to XHTML",NSLocalizedDescriptionKey,nil]]];
		return;	
	}
	
	xmlInitParser();
	

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

	
	// Create a new request for every item in the queue
	[[self externalResourceQueue] cancelAllOperations];
	[self setExternalResourceQueue:[ASINetworkQueue queue]];
	[[self externalResourceQueue] setDelegate:self];
	[[self externalResourceQueue] setQueueDidFinishSelector:@selector(finishedFetchingExternalResources:)];
	[[self externalResourceQueue] setRequestDidFinishSelector:@selector(externalResourceFetchSucceeded:)];
	[[self externalResourceQueue] setRequestDidFailSelector:@selector(externalResourceFetchFailed:)];
	[[self externalResourceQueue] setDownloadProgressDelegate:[self downloadProgressDelegate]];
	[[self externalResourceQueue] setUploadProgressDelegate:[self uploadProgressDelegate]];
	for (NSString *theURL in [[self resourceList] keyEnumerator]) {
		ASIHTTPRequest *externalResourceRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:theURL]];
		[externalResourceRequest setRequestHeaders:[self requestHeaders]];
		[[self externalResourceQueue] addOperation:externalResourceRequest];
	}
	
	[[self externalResourceQueue] go];
}

- (void)externalResourceFetchSucceeded:(ASIHTTPRequest *)externalResourceRequest
{
	NSMutableDictionary *requestResponse = [NSMutableDictionary dictionary];
	NSString *contentType = [[externalResourceRequest responseHeaders] objectForKey:@"Content-Type"];
	if (!contentType) {
		contentType = @"application/octet-stream";
	}
	[requestResponse setObject:contentType forKey:@"ContentType"];
	[requestResponse setObject:[externalResourceRequest responseData] forKey:@"Data"];
	[[self resourceList] setObject:requestResponse forKey:[[externalResourceRequest originalURL] absoluteString]];
}

- (void)externalResourceFetchFailed:(ASIHTTPRequest *)externalResourceRequest
{
	[self failWithError:[externalResourceRequest error]];
}

- (void)finishedFetchingExternalResources:(ASINetworkQueue *)queue
{
	if (![self error]) {
		[self updateResourceURLs];
	}
	[self cleanUp];
	[super requestFinished];
	[(id)super markAsFinished];
}
	
- (void)cleanUp
{
	xmlDocDump(stdout, doc);
    xmlFreeDoc(doc); 
	xmlCleanupParser();
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
		//NSLog(@"%s",xmlNodeGetContent(nodes->nodeTab[i]));
		NSString *theURL = [[NSURL URLWithString:[NSString stringWithCString:(char *)xmlNodeGetContent(nodes->nodeTab[i]) encoding:NSUTF8StringEncoding] relativeToURL:[self url]] absoluteString];
		//NSLog(@"%@",theURL);
		[resourceList setObject:@"" forKey:theURL];
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
		
		NSString *theURL = [[NSURL URLWithString:[NSString stringWithCString:(char *)xmlNodeGetContent(nodes->nodeTab[i]) encoding:NSUTF8StringEncoding] relativeToURL:[self url]] absoluteString];
		
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
