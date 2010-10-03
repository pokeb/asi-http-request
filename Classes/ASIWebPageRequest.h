//
//  ASIWebPageRequest.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 29/06/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//
//  This is an EXPERIMENTAL class - use at your own risk!
//  It is strongly recommend to set a downloadDestinationPath when using ASIWebPageRequest
//  Also, performance will be better if your ASIWebPageRequest has a downloadCache setup
//  Known issue: You cannot use startSychronous with an ASIWebPageRequest

#import "ASIHTTPRequest.h"
#import <libxml/HTMLparser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

@class ASINetworkQueue;

typedef enum _ASIWebContentType {
    ASINotParsedWebContentType = 0,
    ASIHTMLWebContentType = 1,
    ASICSSWebContentType = 2
} ASIWebContentType;


@interface ASIWebPageRequest : ASIHTTPRequest {

	// Each ASIWebPageRequest for an HTML or CSS file creates its own internal queue to download external resources
	ASINetworkQueue *externalResourceQueue;

	// This dictionary stores a list of external resources to download, along with their content-type data or a path to the data
	NSMutableDictionary *resourceList;

	// Used internally for parsing HTML (with libxml)
	xmlDocPtr doc;

	// If the response is an HTML or CSS file, this will be set so the content can be correctly parsed when it has finished fetching external resources
	ASIWebContentType webContentType;

	// Stores a reference to the ASIWebPageRequest that created this request
	// Note that a parentRequest can also have a parent request because ASIWebPageRequests parse their contents to look for external resources recursively
	// For example, a request for an image can be created by a request for a stylesheet which was created by a request for a web page
	ASIWebPageRequest *parentRequest;

	// If set to YES, ASIWebPageRequest will replace the urls of supported external resources with data urls that contain the the content of the external url
	// This allows you to cache a complete webpage in a single file
	// If set to NO, ASIWebPageRequest will still download the content of external resource URLS, but will not make changes to CSS or HTML
	// If you set an ASIDownloadCache for this request and also use it as NSURLCache's sharedCache, webViews and UIWebViews should still be able load many external resources from disk without fetching them again
	BOOL replaceURLsWithDataURLs;
}

// Will return a data URI that contains a base64 version of the content at this url
// This is used when replacing urls in the html and css with actual data
// If you subclass ASIWebPageRequest, you can override this function to return different content or a url pointing at another location
- (NSString *)contentForExternalURL:(NSString *)theURL;

// Returns the location that a downloaded external resource's content will be stored in
- (NSString *)cachePathForRequest:(ASIWebPageRequest *)theRequest;


@property (retain, nonatomic) ASIWebPageRequest *parentRequest;
@property (assign, nonatomic) BOOL replaceURLsWithDataURLs;
@end
