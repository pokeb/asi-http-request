//
//  ASIS3Request.h
//
//  Created by Ben Copsey on 30/06/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//
// A (basic) class for accessing data stored on Amazon's Simple Storage Service (http://aws.amazon.com/s3/)
// It uses the REST API, with canned access policies rather than full support for ACLs (though if you build/parse them yourself you can still use ACLs)

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"

// See http://docs.amazonwebservices.com/AmazonS3/2006-03-01/index.html?RESTAccessPolicy.html for what these mean
extern NSString *const ASIS3AccessPolicyPrivate; // This is the default in S3 when no access policy header is provided
extern NSString *const ASIS3AccessPolicyPublicRead;
extern NSString *const ASIS3AccessPolicyPublicReadWrote;
extern NSString *const ASIS3AccessPolicyAuthenticatedRead;

@interface ASIS3Request : ASIHTTPRequest {

	// Your S3 access key. Set it on the request, or set it globally using [ASIS3Request setSharedAccessKey:]
	NSString *accessKey;
	
	// Your S3 secret access key. Set it on the request, or set it globally using [ASIS3Request setSharedSecretAccessKey:]
	NSString *secretAccessKey;
	
	// Name of the bucket to talk to
	NSString *bucket;
	
	// path to the resource you want to access on S3. Leave empty for the bucket root
	NSString *path;
	
	// The string that will be used in the HTTP date header. Generally you'll want to ignore this and let the class add the current date for you, but the accessor is used by the tests
	NSString *dateString;
	
	// The mime type of the content for PUT requests
	// Set this if having the correct mime type returned to you when you GET the data is important (eg it will be served by a web-server)
	// Will be set to 'application/octet-stream' otherwise in iPhone apps, or autodetected on Mac OS X
	NSString *mimeType;
	
	NSString *accessPolicy;
}

#pragma mark Constructors

// Create a request, building an appropriate url
+ (id)requestWithBucket:(NSString *)bucket path:(NSString *)path;

// Create a PUT request using the file at filePath as the body
+ (id)PUTRequestForFile:(NSString *)filePath withBucket:(NSString *)bucket path:(NSString *)path;

// Create a list request
+ (id)listRequestWithBucket:(NSString *)bucket prefix:(NSString *)prefix maxResults:(int)maxResults marker:(NSString *)marker;

// Generates the request headers S3 needs
// Automatically called before the request begins in startRequest
- (void)generateS3Headers;

// Uses the supplied date to create a Date header string
- (void)setDate:(NSDate *)date;

// Only works on Mac OS, will always return 'application/octet-stream' on iPhone
+ (NSString *)mimeTypeForFileAtPath:(NSString *)path;

#pragma mark Shared access keys

// Get and set the global access key, this will be used for all requests the access key hasn't been set for
+ (NSString *)sharedAccessKey;
+ (void)setSharedAccessKey:(NSString *)newAccessKey;
+ (NSString *)sharedSecretAccessKey;
+ (void)setSharedSecretAccessKey:(NSString *)newAccessKey;


@property (retain) NSString *bucket;
@property (retain) NSString *path;
@property (retain) NSString *dateString;
@property (retain) NSString *mimeType;
@property (retain) NSString *accessKey;
@property (retain) NSString *secretAccessKey;
@property (assign) NSString *accessPolicy;
@end
