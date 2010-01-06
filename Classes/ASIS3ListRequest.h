//
//  ASIS3ListRequest.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 13/07/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIS3Request.h"
@class ASIS3BucketObject;

@interface ASIS3ListRequest : ASIS3Request <NSCopying> {
	
	// Options for filtering list requests
	// See http://docs.amazonwebservices.com/AmazonS3/2006-03-01/index.html?RESTBucketGET.html
	NSString *prefix;
	NSString *marker;
	int maxResultCount;
	NSString *delimiter;	
	
	// Internally used while parsing the response
	NSString *currentContent;
	NSString *currentElement;
	ASIS3BucketObject *currentObject;
	NSMutableArray *objects;	
}
// Create a list request
+ (id)listRequestWithBucket:(NSString *)bucket;


// Returns an array of ASIS3BucketObjects created from the XML response
- (NSArray *)bucketObjects;

//Builds a query string out of the list parameters we supplied
- (void)createQueryString;

@property (retain) NSString *prefix;
@property (retain) NSString *marker;
@property (assign) int maxResultCount;
@property (retain) NSString *delimiter;	
@end
