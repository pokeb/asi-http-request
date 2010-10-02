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

static xmlChar *xpathExpr = (xmlChar *)"//link/@href|//script/@src|//img/@src|//frame/@src|//iframe/@src|//*/@style";

static NSLock *xmlParsingLock = nil;
static NSMutableArray *requestsUsingXMLParser = nil;

@interface ASIWebPageRequest ()
- (void)readResourceURLs;
- (void)updateResourceURLs;
- (void)parseAsHTML;
- (void)parseAsCSS;
- (void)addURLToFetch:(NSString *)newURL;
+ (NSArray *)CSSURLsFromString:(NSString *)string;
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
	complete = NO;
	if ([self mainRequest]) {
		[super requestFinished];
		[super markAsFinished];
		return;
	}
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
	[super markAsFinished];
}

- (void)parseAsCSS
{
	webContentType = ASICSSWebContentType;

	NSString *responseCSS = nil;
	NSError *err = nil;
	if ([self downloadDestinationPath]) {
		responseCSS = [NSString stringWithContentsOfFile:[self downloadDestinationPath] encoding:[self responseEncoding] error:&err];
	} else {
		responseCSS = [self responseString];
	}
	if (err) {
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:100 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unable to read HTML string from response",NSLocalizedDescriptionKey,err,NSUnderlyingErrorKey,nil]]];
		return;
	} else if (!responseCSS) {
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:100 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unable to read HTML string from response",NSLocalizedDescriptionKey,nil]]];
		return;
	}
	NSArray *urls = [[self class] CSSURLsFromString:responseCSS];

	[self setResourceList:[NSMutableDictionary dictionary]];

	for (NSString *theURL in urls) {
		[self addURLToFetch:theURL];
	}
	if (![[self resourceList] count]) {
		[super requestFinished];
		[super markAsFinished];
		return;
	}

	// Create a new request for every item in the queue
	[[self externalResourceQueue] cancelAllOperations];
	[self setExternalResourceQueue:[ASINetworkQueue queue]];
	[[self externalResourceQueue] setDelegate:self];
	[[self externalResourceQueue] setQueueDidFinishSelector:@selector(finishedFetchingExternalResources:)];
	[[self externalResourceQueue] setRequestDidFinishSelector:@selector(externalResourceFetchSucceeded:)];
	[[self externalResourceQueue] setRequestDidFailSelector:@selector(externalResourceFetchFailed:)];
	for (NSString *theURL in [[self resourceList] keyEnumerator]) {
		ASIWebPageRequest *externalResourceRequest = [ASIWebPageRequest requestWithURL:[NSURL URLWithString:theURL relativeToURL:[self url]]];
		[externalResourceRequest setRequestHeaders:[self requestHeaders]];
		[externalResourceRequest setDownloadCache:[self downloadCache]];
		[externalResourceRequest setCachePolicy:[self cachePolicy]];
		[externalResourceRequest setUserInfo:[NSDictionary dictionaryWithObject:theURL forKey:@"Path"]];
		[externalResourceRequest setParentRequest:self];
		[externalResourceRequest setShouldResetDownloadProgress:NO];
		if ([self downloadDestinationPath]) {
			[externalResourceRequest setDownloadDestinationPath:[self cachePathForRequest:externalResourceRequest]];
		}
		[[self externalResourceQueue] addOperation:externalResourceRequest];
		[externalResourceRequest setShowAccurateProgress:YES];
	}

	// Remove external resources
	[[self externalResourceQueue] go];

}

- (void)parseAsHTML
{
	webContentType = ASIHTMLWebContentType;

	// Only allow parsing of a single document at a time
	[xmlParsingLock lock];

	if (![requestsUsingXMLParser count]) {
		xmlInitParser();
	}
	[requestsUsingXMLParser addObject:self];


    /* Load XML document */
	if ([self downloadDestinationPath]) {
		doc = htmlReadFile([[self downloadDestinationPath] cStringUsingEncoding:NSUTF8StringEncoding], NULL, HTML_PARSE_NONET | HTML_PARSE_NOWARNING | HTML_PARSE_NOERROR);
	} else {
		NSData *data = [self responseData];
		doc = htmlReadMemory([data bytes], (int)[data length], "", NULL, HTML_PARSE_NONET | HTML_PARSE_NOWARNING | HTML_PARSE_NOERROR);
	}
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
		[super markAsFinished];
		return;
	}
	
	// Create a new request for every item in the queue
	[[self externalResourceQueue] cancelAllOperations];
	[self setExternalResourceQueue:[ASINetworkQueue queue]];
	[[self externalResourceQueue] setDelegate:self];
	[[self externalResourceQueue] setQueueDidFinishSelector:@selector(finishedFetchingExternalResources:)];
	[[self externalResourceQueue] setRequestDidFinishSelector:@selector(externalResourceFetchSucceeded:)];
	[[self externalResourceQueue] setRequestDidFailSelector:@selector(externalResourceFetchFailed:)];
	for (NSString *theURL in [[self resourceList] keyEnumerator]) {
		ASIWebPageRequest *externalResourceRequest = [ASIWebPageRequest requestWithURL:[NSURL URLWithString:theURL relativeToURL:[self url]]];
		[externalResourceRequest setRequestHeaders:[self requestHeaders]];
		[externalResourceRequest setDownloadCache:[self downloadCache]];
		[externalResourceRequest setCachePolicy:[self cachePolicy]];
		[externalResourceRequest setUserInfo:[NSDictionary dictionaryWithObject:theURL forKey:@"Path"]];
		[externalResourceRequest setParentRequest:self];
		[externalResourceRequest setShouldResetDownloadProgress:NO];
		if ([self downloadDestinationPath]) {
			[externalResourceRequest setDownloadDestinationPath:[self cachePathForRequest:externalResourceRequest]];
		}
		[[self externalResourceQueue] addOperation:externalResourceRequest];
		[externalResourceRequest setShowAccurateProgress:YES];
		[self incrementDownloadSizeBy:1];
	}
	[[self externalResourceQueue] go];
}

- (void)updateDownloadProgress
{
	if ([self parentRequest]) {
		[[self parentRequest] updateDownloadProgress];
		return;
	}
	[super updateDownloadProgress];
}

- (void)setContentLength:(unsigned long long)newContentLength
{
	if ([self parentRequest]) {
		[[self parentRequest] setContentLength:[[self parentRequest] contentLength]+newContentLength-contentLength];
	}
	[super setContentLength:newContentLength];
}
- (void)setTotalBytesRead:(unsigned long long)bytes
{
	totalBytesRead = bytes;
	if ([self parentRequest]) {
		[[self parentRequest] setTotalBytesRead:[[self parentRequest] totalBytesRead]+totalBytesRead-lastBytesRead];
		lastBytesRead = totalBytesRead;
		return;
	}
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
	if ([self downloadDestinationPath]) {
		[requestResponse setObject:[externalResourceRequest downloadDestinationPath] forKey:@"DataPath"];
	} else {
		[requestResponse setObject:[externalResourceRequest responseData] forKey:@"Data"];
	}
}

- (void)externalResourceFetchFailed:(ASIHTTPRequest *)externalResourceRequest
{
	[self failWithError:[externalResourceRequest error]];
}

- (void)finishedFetchingExternalResources:(ASINetworkQueue *)queue
{
	if (webContentType == ASICSSWebContentType) {
		NSMutableString *parsedResponse;
		NSError *err = nil;
		if ([self downloadDestinationPath]) {
			parsedResponse = [NSMutableString stringWithContentsOfFile:[self downloadDestinationPath] encoding:[self responseEncoding] error:&err];
		} else {
			parsedResponse = [[[self responseString] mutableCopy] autorelease];
		}
		if (err) {
			[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:101 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Error: unable to read response CSS from disk",NSLocalizedDescriptionKey,nil]]];
			return;
		}
		if (![self error]) {
			for (NSString *resource in [[self resourceList] keyEnumerator]) {
				if ([parsedResponse rangeOfString:resource].location != NSNotFound) {
					NSString *newURL = [self contentForExternalURL:resource];
					if (newURL) {
						[parsedResponse replaceOccurrencesOfString:resource withString:newURL options:0 range:NSMakeRange(0, [parsedResponse length])];
					}
				}
			}
		}
		if ([self downloadDestinationPath]) {
			[parsedResponse writeToFile:[self downloadDestinationPath] atomically:NO encoding:[self responseEncoding] error:&err];
			if (err) {
				[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:101 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Error: unable to write response CSS to disk",NSLocalizedDescriptionKey,nil]]];
				return;
			}
		} else {
			[self setRawResponseData:(id)[parsedResponse dataUsingEncoding:[self responseEncoding]]];
		}
	} else {
		[xmlParsingLock lock];

		[self updateResourceURLs];
		xmlChar *bytes = nil;
		int size = 0;
		FILE *file = NULL;
		if ([self downloadDestinationPath]) {
			file = fdopen([[NSFileHandle fileHandleForWritingAtPath:[self downloadDestinationPath]] fileDescriptor], "w");
			xmlDocDump(file, doc);
		} else {
			xmlDocDumpMemory(doc,&bytes,&size);
			[self setRawResponseData:[[[NSMutableData alloc] initWithBytes:bytes length:size] autorelease]];
		}

		xmlFreeDoc(doc);
		doc = nil;

		if (file) {
			fclose(file);
		}

		[requestsUsingXMLParser removeObject:self];
		if (![requestsUsingXMLParser count]) {
			xmlCleanupParser();
		}
		[xmlParsingLock unlock];
	}

	if (![self parentRequest]) {
		[[self class] updateProgressIndicator:&downloadProgressDelegate withProgress:totalDownloadProgress ofTotal:totalDownloadSize];
	}

	NSMutableDictionary *newHeaders = [[[self responseHeaders] mutableCopy] autorelease];
	[newHeaders removeObjectForKey:@"Content-Encoding"];
	[self setResponseHeaders:newHeaders];

	[super requestFinished];
	[[self downloadCache] storeResponseForRequest:self maxAge:[self secondsToCache]];
	[super markAsFinished];
}

- (void)readResourceURLs
{
	// Create xpath evaluation context
    xmlXPathContextPtr xpathCtx = xmlXPathNewContext(doc);
    if(xpathCtx == NULL) {
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:101 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Error: unable to create new XPath context",NSLocalizedDescriptionKey,nil]]];
		return;
    }

    // Evaluate xpath expression
    xmlXPathObjectPtr xpathObj = xmlXPathEvalExpression(xpathExpr, xpathCtx);
    if(xpathObj == NULL) {
        xmlXPathFreeContext(xpathCtx); 
        xmlFreeDoc(doc); 
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:101 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Error: unable to evaluate XPath expression!",NSLocalizedDescriptionKey,nil]]];
		return;
    }
	
	// Now loop through our matches
	xmlNodeSetPtr nodes = xpathObj->nodesetval;

    int size = (nodes) ? nodes->nodeNr : 0;
	int i;
    for(i = size - 1; i >= 0; i--) {
		assert(nodes->nodeTab[i]);
		NSString *parentName  = [NSString stringWithCString:(char *)nodes->nodeTab[i]->parent->name encoding:[self responseEncoding]];
		NSString *nodeName = [NSString stringWithCString:(char *)nodes->nodeTab[i]->name encoding:[self responseEncoding]];
		NSString *value = [NSString stringWithCString:(char *)xmlNodeGetContent(nodes->nodeTab[i]) encoding:[self responseEncoding]];

		// Our xpath query matched all <link> elements, but we're only interested in stylesheets
		// We do the work here rather than in the xPath query because the query is case-sensitive, and we want to match on 'stylesheet', 'StyleSHEEt' etc
		if ([[parentName lowercaseString] isEqualToString:@"link"]) {
			NSString *rel = [NSString stringWithCString:(char *)xmlGetNoNsProp(nodes->nodeTab[i]->parent,(xmlChar *)"rel") encoding:[self responseEncoding]];
			if ([[rel lowercaseString] isEqualToString:@"stylesheet"]) {
				[self addURLToFetch:value];
			}
		} else if ([[nodeName lowercaseString] isEqualToString:@"style"]) {
			NSArray *externalResources = [[self class] CSSURLsFromString:value];
			for (NSString *theURL in externalResources) {
				[self addURLToFetch:theURL];
			}
		} else {
			[self addURLToFetch:value];
		}
		if (nodes->nodeTab[i]->type != XML_NAMESPACE_DECL) {
			nodes->nodeTab[i] = NULL;
		}
    }
	
	xmlXPathFreeObject(xpathObj);
    xmlXPathFreeContext(xpathCtx); 
}

- (void)addURLToFetch:(NSString *)newURL
{
	// Get rid of any surrounding whitespace
	newURL = [newURL stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	// Don't attempt to fetch data URIs
	if ([newURL length] > 4) {
		if (![[[newURL substringToIndex:5] lowercaseString] isEqualToString:@"data:"]) {
			NSURL *theURL = [NSURL URLWithString:newURL relativeToURL:[self url]];
			if (theURL) {
				if (![[self resourceList] objectForKey:newURL]) {
					[[self resourceList] setObject:[NSMutableDictionary dictionary] forKey:newURL];
				}
			}
		}
	}
}


- (void)updateResourceURLs
{
	// Create xpath evaluation context
	xmlXPathContextPtr xpathCtx = xmlXPathNewContext(doc);
	if(xpathCtx == NULL) {
		xmlFreeDoc(doc);
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:101 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Error: unable to create new XPath context",NSLocalizedDescriptionKey,nil]]];
		return;
	}

 	// Evaluate xpath expression
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
		NSString *nodeName  = [NSString stringWithCString:(char *)nodes->nodeTab[i]->name encoding:[self responseEncoding]];
		NSString *value = [NSString stringWithCString:(char *)xmlNodeGetContent(nodes->nodeTab[i]) encoding:[self responseEncoding]];
		if ([[nodeName lowercaseString] isEqualToString:@"style"]) {
			NSArray *externalResources = [[self class] CSSURLsFromString:value];
			for (NSString *theURL in externalResources) {
				if ([value rangeOfString:theURL].location != NSNotFound) {
					NSString *newURL = [self contentForExternalURL:theURL];
					if (newURL) {
						value = [value stringByReplacingOccurrencesOfString:theURL withString:newURL];
					}
				}
			}
			xmlNodeSetContent(nodes->nodeTab[i], (xmlChar *)[value cStringUsingEncoding:[self responseEncoding]]);
		} else {
			NSString *newURL = [self contentForExternalURL:value];
			if (newURL) {
				xmlNodeSetContent(nodes->nodeTab[i], (xmlChar *)[newURL cStringUsingEncoding:[self responseEncoding]]);
			}
		}

		if (nodes->nodeTab[i]->type != XML_NAMESPACE_DECL) {
			nodes->nodeTab[i] = NULL;
		}
	}
	xmlXPathFreeObject(xpathObj);
	xmlXPathFreeContext(xpathCtx);
}

+ (NSArray *)CSSURLsFromString:(NSString *)string
{
	NSMutableArray *urls = [NSMutableArray array];
	NSScanner *scanner = [NSScanner scannerWithString:string];
	[scanner setCaseSensitive:NO];
	while (1) {
		NSString *theURL = nil;
		[scanner scanUpToString:@"url(" intoString:NULL];
		[scanner scanString:@"url(" intoString:NULL];
		[scanner scanUpToString:@")" intoString:&theURL];
		if (!theURL) {
			break;
		}
		// Remove any quotes or whitespace around the url
		theURL = [theURL stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		theURL = [theURL stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\"'"]];
		theURL = [theURL stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		[urls addObject:theURL];
	}
	return urls;
}

- (NSString *)contentForExternalURL:(NSString *)theURL
{
	NSData *data;
	if ([[resourceList objectForKey:theURL] objectForKey:@"DataPath"]) {
		data = [NSData dataWithContentsOfFile:[[resourceList objectForKey:theURL] objectForKey:@"DataPath"]];
	} else {
		data = [[resourceList objectForKey:theURL] objectForKey:@"Data"];
	}
	NSString *contentType = [[resourceList objectForKey:theURL] objectForKey:@"ContentType"];
	if (data && contentType) {
		NSString *dataURI = [NSString stringWithFormat:@"data:%@;base64,",contentType];
		dataURI = [dataURI stringByAppendingString:[ASIHTTPRequest base64forData:data]];
		return dataURI;
	}
	return nil;
}

static int resourceNum = 0;
- (NSString *)cachePathForRequest:(ASIWebPageRequest *)theRequest
{
	resourceNum++;
	return [NSString stringWithFormat:@"/Users/ben/Desktop/%i",resourceNum];
}

@synthesize externalResourceQueue;
@synthesize resourceList;
@synthesize parentRequest;
@end
