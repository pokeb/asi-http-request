//
//  ASIS3Request.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 30/06/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//
// A (basic) class for accessing data stored on Amazon's Simple Storage Service (http://aws.amazon.com/s3/) using the REST API

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"

// See http://docs.amazonwebservices.com/AmazonS3/2006-03-01/index.html?RESTAccessPolicy.html for what these mean
extern NSString *const ASIS3AccessPolicyPrivate; // This is the default in S3 when no access policy header is provided
extern NSString *const ASIS3AccessPolicyPublicRead;
extern NSString *const ASIS3AccessPolicyPublicReadWrote;
extern NSString *const ASIS3AccessPolicyAuthenticatedRead;

typedef enum _ASIS3ErrorType {
    ASIS3ResponseParsingFailedType = 1,
    ASIS3ResponseErrorType = 2
	
} ASIS3ErrorType;

// Prevent warning about missing NSXMLParserDelegate on Leopard and iPhone
#if !TARGET_OS_IPHONE && MAC_OS_X_VERSION_10_5 < MAC_OS_X_VERSION_MAX_ALLOWED
@interface ASIS3Request : ASIHTTPRequest <NSCopying, NSXMLParserDelegate> {
#else
@interface ASIS3Request : ASIHTTPRequest <NSCopying> {

#endif
	// Your S3 access key. Set it on the request, or set it globally using [ASIS3Request setSharedAccessKey:]
	NSString *accessKey;
	
	// Your S3 secret access key. Set it on the request, or set it globally using [ASIS3Request setSharedSecretAccessKey:]
	NSString *secretAccessKey;
	
	// Name of the bucket to talk to
	NSString *bucket;
	
	// Path to the resource you want to access on S3. Leave empty for the bucket root
	NSString *path;
	
	// The string that will be used in the HTTP date header. Generally you'll want to ignore this and let the class add the current date for you, but the accessor is used by the tests
	NSString *dateString;
	
	// The mime type of the content for PUT requests
	// Set this if having the correct mime type returned to you when you GET the data is important (eg it will be served by a web-server)
	// Will be set to 'application/octet-stream' otherwise in iPhone apps, or autodetected on Mac OS X
	NSString *mimeType;
	
	// The access policy to use when PUTting a file (see the string constants at the top of this header)
	NSString *accessPolicy;
	
	// The bucket + path of the object to be copied (used with COPYRequestFromBucket:path:toBucket:path:)
	NSString *sourceBucket;
	NSString *sourcePath;
	
	// Internally used while parsing errors
	NSString *currentErrorString;
	
}

#pragma mark Constructors

// Create a request, building an appropriate url
+ (id)requestWithBucket:(NSString *)bucket path:(NSString *)path;

// Create a PUT request using the file at filePath as the body
+ (id)PUTRequestForFile:(NSString *)filePath withBucket:(NSString *)bucket path:(NSString *)path;

// Create a PUT request using the supplied NSData as the body (set the mime-type manually with setMimeType: if necessary)
+ (id)PUTRequestForData:(NSData *)data withBucket:(NSString *)bucket path:(NSString *)path;
	
// Create a DELETE request for the object at path
+ (id)DELETERequestWithBucket:(NSString *)bucket path:(NSString *)path;

// Create a PUT request to copy an object from one location to another
// Clang will complain because it thinks this method should return an object with +1 retain :(
+ (id)COPYRequestFromBucket:(NSString *)sourceBucket path:(NSString *)sourcePath toBucket:(NSString *)bucket path:(NSString *)path;

// Creates a HEAD request for the object at path
+ (id)HEADRequestWithBucket:(NSString *)bucket path:(NSString *)path;


// Uses the supplied date to create a Date header string
- (void)setDate:(NSDate *)date;

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
@property (retain) NSString *accessPolicy;
@property (retain) NSString *sourceBucket;
@property (retain) NSString *sourcePath;
@end
