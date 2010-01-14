//
//  ASIS3BucketObject.m
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 13/07/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import "ASIS3BucketObject.h"
#import "ASIS3Request.h"

@implementation ASIS3BucketObject

+ (id)objectWithBucket:(NSString *)bucket
{
	ASIS3BucketObject *object = [[[self alloc] init] autorelease];
	[object setBucket:bucket];
	return object;
}

- (void)dealloc
{
	[key release];
	[lastModified release];
	[ETag release];
	[ownerID release];
	[ownerName release];
	[super dealloc];
}

- (ASIS3Request *)GETRequest
{
	return [ASIS3Request requestWithBucket:[self bucket] path:[NSString stringWithFormat:@"/%@",[self key]]];
}

- (ASIS3Request *)PUTRequestWithFile:(NSString *)filePath
{
	return [ASIS3Request PUTRequestForFile:filePath withBucket:[self bucket] path:[NSString stringWithFormat:@"/%@",[self key]]];
}

- (ASIS3Request *)DELETERequest
{
	ASIS3Request *request = [ASIS3Request requestWithBucket:[self bucket] path:[NSString stringWithFormat:@"/%@",[self key]]];
	[request setRequestMethod:@"DELETE"];
	return request;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"Key: %@ lastModified: %@ ETag: %@ size: %llu ownerID: %@ ownerName: %@",[self key],[self lastModified],[self ETag],[self size],[self ownerID],[self ownerName]];
}

- (id)copyWithZone:(NSZone *)zone
{
	ASIS3BucketObject *newBucketObject = [[[self class] alloc] init];
	[newBucketObject setBucket:[self bucket]];
	[newBucketObject setKey:[self key]];
	[newBucketObject setLastModified:[self lastModified]];
	[newBucketObject setETag:[self ETag]];
	[newBucketObject setSize:[self size]];
	[newBucketObject setOwnerID:[self ownerID]];
	[newBucketObject setOwnerName:[self ownerName]];
	return newBucketObject;
}

@synthesize bucket;
@synthesize key;
@synthesize lastModified;
@synthesize ETag;
@synthesize size;
@synthesize ownerID;
@synthesize ownerName;
@end
