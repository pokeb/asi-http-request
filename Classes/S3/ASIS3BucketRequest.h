//
//  ASIS3BucketRequest.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 16/03/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//
//  Use this class to create buckets, fetch a list of their contents, and delete buckets

#import <Foundation/Foundation.h>
#import "ASIS3Request.h"

@class ASIS3BucketObject;

@interface ASIS3BucketRequest : ASIS3Request {
	
	// Name of the bucket to talk to
	NSString *bucket;
	
	// A parameter passed to S3 in the query string to tell it to return specialised information
	// Consult the S3 REST API documentation for more info
	NSString *subResource;
	
	// Options for filtering GET requests
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

// Fetch a bucket
+ (id)requestWithBucket:(NSString *)bucket;

// Create a bucket request, passing a parameter in the query string
// You'll need to parse the response XML yourself
// Examples:
// Fetch ACL:
// ASIS3BucketRequest *request = [ASIS3BucketRequest requestWithBucket:@"mybucket" parameter:@"acl"];
// Fetch Location:
// ASIS3BucketRequest *request = [ASIS3BucketRequest requestWithBucket:@"mybucket" parameter:@"location"];
// See the S3 REST API docs for more information about the parameters you can pass
+ (id)requestWithBucket:(NSString *)bucket subResource:(NSString *)subResource;

// Use for creating new buckets
+ (id)PUTRequestWithBucket:(NSString *)bucket;

// Use for deleting buckets - they must be empty for this to succeed
+ (id)DELETERequestWithBucket:(NSString *)bucket;

// Returns an array of ASIS3BucketObjects created from the XML response
- (NSArray *)bucketObjects;

//Builds a query string out of the list parameters we supplied
- (void)createQueryString;

@property (retain) NSString *bucket;
@property (retain) NSString *subResource;
@property (retain) NSString *prefix;
@property (retain) NSString *marker;
@property (assign) int maxResultCount;
@property (retain) NSString *delimiter;	
@end
