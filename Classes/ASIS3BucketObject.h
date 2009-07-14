//
//  ASIS3BucketObject.h
//  Mac
//
//  Created by Ben Copsey on 13/07/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ASIS3Request;

@interface ASIS3BucketObject : NSObject {
	
	// The bucket this object belongs to
	NSString *bucket;
	
	// The key (path) of this object in the bucket
	NSString *key;
	
	// When this object was last modified
	NSDate *lastModified;
	
	// The ETag for this object's content
	NSString *ETag;
	
	// The size in bytes of this object
	unsigned long long size;
	
	// Info about the owner
	NSString *ownerID;
	NSString *ownerName;
}

+ (id)objectWithBucket:(NSString *)bucket;

// Returns a request that will fetch this object when run
- (ASIS3Request *)GETRequest;

// Returns a request that will replace this object with the contents of the file at filePath when run
- (ASIS3Request *)PUTRequestWithFile:(NSString *)filePath;

// Returns a request that will delete this object when run
- (ASIS3Request *)DELETERequest;

@property (retain) NSString *bucket;
@property (retain) NSString *key;
@property (retain) NSDate *lastModified;
@property (retain) NSString *ETag;
@property (assign) unsigned long long size;
@property (retain) NSString *ownerID;
@property (retain) NSString *ownerName;
@end
