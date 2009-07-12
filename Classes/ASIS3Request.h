//
//  ASIS3Request.h
//  Mac
//
//  Created by Ben Copsey on 30/06/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"

@interface ASIS3Request : ASIHTTPRequest {
	NSString *bucket;
	NSString *path;
	NSString *dateString;
	NSString *mimeType;
	NSString *accessKey;
	NSString *secretAccessKey;
}

#pragma mark Constructors

+ (id)requestWithBucket:(NSString *)bucket path:(NSString *)path;
+ (id)PUTRequestForFile:(NSString *)filePath withBucket:(NSString *)bucket path:(NSString *)path;
+ (id)GETRequestWithBucket:(NSString *)bucket path:(NSString *)path;
+ (id)listRequestWithBucket:(NSString *)bucket prefix:(NSString *)prefix maxResults:(int)maxResults marker:(NSString *)marker;
+ (id)ACLRequestWithBucket:(NSString *)bucket path:(NSString *)path;


- (void)generateS3Headers;
- (void)setDate:(NSDate *)date;


+ (NSString *)mimeTypeForFileAtPath:(NSString *)path;

#pragma mark Shared access keys
+ (NSString *)sharedAccessKey;
+ (void)setSharedAccessKey:(NSString *)newAccessKey;
+ (NSString *)sharedSecretAccessKey;
+ (void)setSharedSecretAccessKey:(NSString *)newAccessKey;

#pragma mark S3 Authentication helpers
+ (NSData *)HMACSHA1withKey:(NSString *)key forString:(NSString *)string;
+ (NSString *)base64forData:(NSData *)theData;

@property (retain) NSString *bucket;
@property (retain) NSString *path;
@property (retain) NSString *dateString;
@property (retain) NSString *mimeType;
@property (retain) NSString *accessKey;
@property (retain) NSString *secretAccessKey;
@end
