//
//  ASIS3ObjectRequest.m
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 16/03/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//

#import "ASIS3ObjectRequest.h"

NSString *const ASIS3StorageClassStandard = @"STANDARD";
NSString *const ASIS3StorageClassReducedRedundancy = @"REDUCED_REDUNDANCY";

@implementation ASIS3ObjectRequest

- (ASIHTTPRequest *)HEADRequest
{
	ASIS3ObjectRequest *headRequest = (ASIS3ObjectRequest *)[super HEADRequest];
	[headRequest setKey:[self key]];
	[headRequest setBucket:[self bucket]];
	return headRequest;
}

+ (id)requestWithBucket:(NSString *)bucket key:(NSString *)key
{
	ASIS3ObjectRequest *request = [[[self alloc] initWithURL:nil] autorelease];
	[request setBucket:bucket];
	[request setKey:key];
	return request;
}

+ (id)requestWithBucket:(NSString *)bucket key:(NSString *)key subResource:(NSString *)subResource
{
	ASIS3ObjectRequest *request = [[[self alloc] initWithURL:nil] autorelease];
	[request setSubResource:subResource];
	[request setBucket:bucket];
	[request setKey:key];
	return request;
}

+ (id)PUTRequestForData:(NSData *)data withBucket:(NSString *)bucket key:(NSString *)key
{
	ASIS3ObjectRequest *request = [self requestWithBucket:bucket key:key];
	[request appendPostData:data];
	[request setRequestMethod:@"PUT"];
	return request;
}

+ (id)PUTRequestForFile:(NSString *)filePath withBucket:(NSString *)bucket key:(NSString *)key
{
	ASIS3ObjectRequest *request = [self requestWithBucket:bucket key:key];
	[request setPostBodyFilePath:filePath];
	[request setShouldStreamPostDataFromDisk:YES];
	[request setRequestMethod:@"PUT"];
	[request setMimeType:[ASIHTTPRequest mimeTypeForFileAtPath:filePath]];
	return request;
}

+ (id)DELETERequestWithBucket:(NSString *)bucket key:(NSString *)key
{
	ASIS3ObjectRequest *request = [self requestWithBucket:bucket key:key];
	[request setRequestMethod:@"DELETE"];
	return request;
}

+ (id)COPYRequestFromBucket:(NSString *)sourceBucket key:(NSString *)sourceKey toBucket:(NSString *)bucket key:(NSString *)key
{
	ASIS3ObjectRequest *request = [self requestWithBucket:bucket key:key];
	[request setRequestMethod:@"PUT"];
	[request setSourceBucket:sourceBucket];
	[request setSourceKey:sourceKey];
	return request;
}

+ (id)HEADRequestWithBucket:(NSString *)bucket key:(NSString *)key
{
	ASIS3ObjectRequest *request = [self requestWithBucket:bucket key:key];
	[request setRequestMethod:@"HEAD"];
	return request;
}

- (id)copyWithZone:(NSZone *)zone
{
	ASIS3ObjectRequest *newRequest = [super copyWithZone:zone];
	[newRequest setBucket:[self bucket]];
	[newRequest setKey:[self key]];
	[newRequest setMimeType:[self mimeType]];
	[newRequest setSourceBucket:[self sourceBucket]];
	[newRequest setSourceKey:[self sourceKey]];
	return newRequest;
}

- (void)dealloc
{
	[bucket release];
	[key release];
	[mimeType release];
	[sourceKey release];
	[sourceBucket release];
	[subResource release];
	[storageClass release];
	[super dealloc];
}

- (void)buildURL
{
	if ([self subResource]) {
		[self setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@://%@.%@%@?%@",[self requestScheme],[self bucket],[[self class] S3Host],[ASIS3Request stringByURLEncodingForS3Path:[self key]],[self subResource]]]];
	} else {
		[self setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@://%@.%@%@",[self requestScheme],[self bucket],[[self class] S3Host],[ASIS3Request stringByURLEncodingForS3Path:[self key]]]]];
	}
}

- (NSString *)mimeType
{
	if (mimeType) {
		return mimeType;
	} else if ([self postBodyFilePath]) {
		return [ASIHTTPRequest mimeTypeForFileAtPath:[self postBodyFilePath]];
	} else {
		return @"application/octet-stream";
	}
}

- (NSString *)canonicalizedResource
{
	if ([[self subResource] length] > 0) {
		return [NSString stringWithFormat:@"/%@%@?%@",[self bucket],[ASIS3Request stringByURLEncodingForS3Path:[self key]], [self subResource]];
	}
	return [NSString stringWithFormat:@"/%@%@",[self bucket],[ASIS3Request stringByURLEncodingForS3Path:[self key]]];
}

- (NSMutableDictionary *)S3Headers
{
	NSMutableDictionary *headers = [super S3Headers];
	if ([self sourceKey]) {
		NSString *path = [ASIS3Request stringByURLEncodingForS3Path:[self sourceKey]];
		[headers setObject:[[self sourceBucket] stringByAppendingString:path] forKey:@"x-amz-copy-source"];
	}
	if ([self storageClass]) {
		[headers setObject:[self storageClass] forKey:@"x-amz-storage-class"];
	}
	return headers;
}

- (NSString *)stringToSignForHeaders:(NSString *)canonicalizedAmzHeaders resource:(NSString *)canonicalizedResource
{
	if ([[self requestMethod] isEqualToString:@"PUT"] && ![self sourceKey]) {
		[self addRequestHeader:@"Content-Type" value:[self mimeType]];
		return [NSString stringWithFormat:@"PUT\n\n%@\n%@\n%@%@",[self mimeType],dateString,canonicalizedAmzHeaders,canonicalizedResource];
	} 
	return [super stringToSignForHeaders:canonicalizedAmzHeaders resource:canonicalizedResource];
}

@synthesize bucket;
@synthesize key;
@synthesize sourceBucket;
@synthesize sourceKey;
@synthesize mimeType;
@synthesize subResource;
@synthesize storageClass;
@end
