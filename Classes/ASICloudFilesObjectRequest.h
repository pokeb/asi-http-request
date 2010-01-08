//
//  ASICloudFilesObjectRequest.h
//  iPhone
//
//  Created by Michael Mayo on 1/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ASICloudFilesRequest.h"

@class ASICloudFilesObject;

@interface ASICloudFilesObjectRequest : ASICloudFilesRequest {

	// Internally used while parsing the response
	NSString *currentContent;
	NSString *currentElement;
	ASICloudFilesObject *currentObject;
	NSMutableArray *objects;
	
}

@property (nonatomic, retain) NSString *currentElement;
@property (nonatomic, retain) NSString *currentContent;
@property (nonatomic, retain) ASICloudFilesObject *currentObject;


// HEAD /<api version>/<account>/<container>
// HEAD operations against an account are performed to retrieve the number of Containers and the total bytes stored in Cloud Files for the account. This information is returned in two custom headers, X-Account-Container-Count and X-Account-Bytes-Used.
+ (id)containerInfoRequest:(NSString *)containerName;
- (NSUInteger)containerObjectCount;
- (NSUInteger)containerBytesUsed;


// GET
- (NSArray *)objects;

// ASICloudFilesObjectListRequest
// GET on container (for objects)
// limit
// marker
// prefix - For a string value X, causes the results to be limited to Object names beginning with the substring X.
// path - Now issuing a GET request against the Container name coupled with the “path” query parameter of the directory to list can traverse these “directories”. GET /v1/AccountString/backups?path=photos/animals

// every possible combination of object list request
// TODO: consider an options dictionary argument instead of so many method signatures
+ (id)listRequestWithContainer:(NSString *)containerName;
+ (id)listRequestWithContainer:(NSString *)containerName limit:(NSUInteger)limit;
+ (id)listRequestWithContainer:(NSString *)containerName limit:(NSUInteger)limit marker:(NSString *)marker;
+ (id)listRequestWithContainer:(NSString *)containerName limit:(NSUInteger)limit marker:(NSString *)marker prefix:(NSString *)prefix;
+ (id)listRequestWithContainer:(NSString *)containerName limit:(NSUInteger)limit marker:(NSString *)marker path:(NSString *)path;
+ (id)listRequestWithContainer:(NSString *)containerName limit:(NSUInteger)limit prefix:(NSString *)prefix;
+ (id)listRequestWithContainer:(NSString *)containerName limit:(NSUInteger)limit prefix:(NSString *)prefix path:(NSString *)path;
+ (id)listRequestWithContainer:(NSString *)containerName limit:(NSUInteger)limit path:(NSString *)path;
+ (id)listRequestWithContainer:(NSString *)containerName marker:(NSString *)marker;
+ (id)listRequestWithContainer:(NSString *)containerName marker:(NSString *)marker prefix:(NSString *)prefix;
+ (id)listRequestWithContainer:(NSString *)containerName marker:(NSString *)marker path:(NSString *)path;
+ (id)listRequestWithContainer:(NSString *)containerName marker:(NSString *)marker prefix:(NSString *)prefix path:(NSString *)path;
+ (id)listRequestWithContainer:(NSString *)containerName prefix:(NSString *)prefix;
+ (id)listRequestWithContainer:(NSString *)containerName prefix:(NSString *)prefix path:(NSString *)path;
+ (id)listRequestWithContainer:(NSString *)containerName path:(NSString *)path;
+ (id)listRequestWithContainer:(NSString *)containerName limit:(NSUInteger)limit marker:(NSString *)marker prefix:(NSString *)prefix path:(NSString *)path;

// TODO: GET object with data and metadata
// Conditional GET headers: If-Match • If-None-Match • If-Modified-Since • If-Unmodified-Since
// HTTP Range header: “Range: bytes=0-5” •	“Range: bytes=-5” •	“Range: bytes=32-“
// TODO: return 'ETag' header from GET
// TODO: maybe do chunked PUT
+ (id)getObjectRequestWithContainer:(NSString *)containerName objectPath:(NSString *)objectPath;
- (ASICloudFilesObject *)object;

// PUT /<api version>/<account>/<container>/<object>
// PUT operations are used to write, or overwrite, an Object's metadata and content.
// The Object can be created with custom metadata via HTTP headers identified with the “X-Object-Meta-” prefix.
+ (id)putObjectRequestWithContainer:(NSString *)containerName object:(ASICloudFilesObject *)object;
+ (id)putObjectRequestWithContainer:(NSString *)containerName objectPath:(NSString *)objectPath contentType:(NSString *)contentType objectData:(NSData *)objectData metadata:(NSDictionary *)metadata etag:(NSString *)etag;

// POST /<api version>/<account>/<container>/<object>
// POST operations against an Object name are used to set and overwrite arbitrary key/value metadata. You cannot use the POST operation to change any of the Object's other headers such as Content-Type, ETag, etc. It is not used to upload storage Objects (see PUT).
// A POST request will delete all existing metadata added with a previous PUT/POST.
+ (id)postObjectRequestWithContainer:(NSString *)containerName object:(ASICloudFilesObject *)object;
+ (id)postObjectRequestWithContainer:(NSString *)containerName objectPath:(NSString *)objectPath metadata:(NSDictionary *)metadata;

// DELETE /<api version>/<account>/<container>/<object>
+ (id)deleteObjectRequestWithContainer:(NSString *)containerName objectPath:(NSString *)objectPath;

@end
