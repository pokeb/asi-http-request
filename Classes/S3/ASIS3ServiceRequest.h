//
//  ASIS3ServiceRequest.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 16/03/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//
//  Create an ASIS3ServiceRequest to obtain a list of your buckets

#import <Foundation/Foundation.h>
#import "ASIS3Request.h"

@class ASIS3Bucket;

@interface ASIS3ServiceRequest : ASIS3Request {
	
	// Internally used while parsing the response
	NSString *currentContent;
	NSString *currentElement;
	ASIS3Bucket *currentBucket;
	NSMutableArray *buckets;	
	NSString *ownerName;
	NSString *ownerID;
}

// Perform a GET request on the S3 service
// This will fetch a list of the buckets attached to the S3 account
+ (id)serviceRequest;

// Parse the XML response from S3, and return an array of ASIS3Bucket objects
- (NSArray *)allBuckets;

@end
