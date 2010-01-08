//
//  ASICloudFilesRequest.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Michael Mayo on 22/12/09.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//
// A (basic) class for accessing data stored on Rackspace's Cloud Files Service
// http://www.rackspacecloud.com/cloud_hosting_products/files
// 
// Cloud Files Developer Guide:
// http://docs.rackspacecloud.com/servers/api/cs-devguide-latest.pdf

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"


@interface ASICloudFilesRequest : ASIHTTPRequest {

	// GET operations against the X-CDN-Management-Url for an account are performed to retrieve a list of existing CDN-enabled Containers
	// GET /<api version>/<account>
	
	// list containers
	// list objects in a container
	// cdn operations
	
}

+ (NSString *)storageURL;
+ (NSString *)authToken;

#pragma mark Rackspace Cloud Authentication

+ (void)authenticate;

+ (NSString *)username;
+ (void)setUsername:(NSString *)username;
+ (NSString *)apiKey;
+ (void)setApiKey:(NSString *)apiKey;

-(NSDate *)dateFromString:(NSString *)dateString;

#pragma mark Constructors

+ (id)authenticationRequest;
+ (id)storageRequest;
+ (id)cdnRequest;

//+ (id)PUTRequestForFile:(NSString *)filePath withContainer:(NSString *)container path:(NSString *)path;


// Create a request to list all objects in a container
//+ (id)objectListRequestWithContainer:(NSString *)container;

// HEAD /<api version>/<account>/<container>
// HEAD operations against a storage Container are used to determine the number of Objects, and the total bytes of all Objects stored in the Container.
// The Object count and utilization are returned in the X-Container-Object-Count and X-Container-Bytes-Used headers respectively.

// HEAD /<api version>/<account>/<container>/<object>
// No response body is returned. Metadata is returned as HTTP headers. A status code of 204 (No Content) indicates success, status 404 (Not Found) is returned when the Object does not exist.

// CDN URL
// HEAD /<api version>/<account>/<container>
// HEAD operations against a CDN-enabled Container are used to determine the CDN attributes of the Container.

// PUT operations against a Container are used to CDN-enable that Container.
// POST operations against a CDN-enabled Container are used to adjust CDN attributes.



// Create a request, building an appropriate url
//+ (id)requestWithContainer:(NSString *)container path:(NSString *)path;
//
//// Create a PUT request using the file at filePath as the body
//+ (id)PUTRequestForFile:(NSString *)filePath withContainer:(NSString *)container path:(NSString *)path;
//
//// Create a PUT request using the supplied NSData as the body (set the mime-type manually with setMimeType: if necessary)
//+ (id)PUTRequestForData:(NSData *)data withContainer:(NSString *)container path:(NSString *)path;
//
//// Create a DELETE request for the object at path
//+ (id)DELETERequestWithContainer:(NSString *)container path:(NSString *)path;

// TODO: CDN toggle containers

@end
