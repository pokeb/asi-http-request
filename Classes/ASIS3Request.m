//
//  ASIS3Request.m
//  Mac
//
//  Created by Ben Copsey on 30/06/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import "ASIS3Request.h"
#import <CommonCrypto/CommonHMAC.h>

static NSString *sharedAccessKey = nil;
static NSString *sharedSecretAccessKey = nil;

@implementation ASIS3Request


+ (id)requestWithBucket:(NSString *)bucket path:(NSString *)path
{
	ASIS3Request *request =  [[[ASIS3Request alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@.s3.amazonaws.com/%@",bucket,path]]] autorelease];
	[request setBucket:bucket];
	[request setPath:path];
	return request;
}

+ (id)PUTRequestForFile:(NSString *)filePath withBucket:(NSString *)bucket path:(NSString *)path
{
	ASIS3Request *request = [ASIS3Request requestWithBucket:bucket path:path];
	[request setPostBodyFilePath:filePath];
	[request setShouldStreamPostDataFromDisk:YES];
	[request setRequestMethod:@"PUT"];
	[request setMimeType:[ASIS3Request mimeTypeForFileAtPath:path]];
	return request;
}

+ (id)GETRequestWithBucket:(NSString *)bucket path:(NSString *)path
{
	ASIS3Request *request = [ASIS3Request requestWithBucket:bucket path:path];
	[request setRequestMethod:@"GET"];
	return request;
}

+ (id)ACLRequestWithBucket:(NSString *)bucket path:(NSString *)path
{
	ASIS3Request *request = [ASIS3Request requestWithBucket:bucket path:[NSString stringWithFormat:@"%@?acl",path]];
	[request setRequestMethod:@"GET"];
	return request;
}

+ (id)listRequestWithBucket:(NSString *)bucket prefix:(NSString *)prefix maxResults:(int)maxResults marker:(NSString *)marker
{
	ASIS3Request *request =  [[[ASIS3Request alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@.s3.amazonaws.com/?prefix=/%@&max-keys=%hi&marker=%@",bucket,prefix,maxResults,marker]]] autorelease];
	[request setBucket:bucket];
	[request setRequestMethod:@"GET"];
	return request;
}

+ (NSString *)mimeTypeForFileAtPath:(NSString *)path
{
// NSTask does seem to exist in the 2.2.1 SDK, though it's not in the 3.0 SDK. It's probably best if we just use a generic mime type on iPhone all the time.
#if TARGET_OS_IPHONE
	return @"application/octet-stream";
#else
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath: @"/usr/bin/file"];
	[task setArguments:[NSMutableArray arrayWithObjects:@"-Ib",path,nil]];

    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
	
    NSFileHandle *file = [pipe fileHandleForReading];
	
	[task launch];
	
	NSString *mimeTypeString = [[[NSString alloc] initWithData:[file readDataToEndOfFile] encoding: NSUTF8StringEncoding] autorelease];
	return [[mimeTypeString componentsSeparatedByString:@";"] objectAtIndex:0];
#endif
}

- (void)setDate:(NSDate *)date
{
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss zzzz"];
	[self setDateString:[dateFormatter stringFromDate:date]];	
}

- (void)generateS3Headers
{
	if (![self accessKey]) {
		[self setAccessKey:[ASIS3Request sharedAccessKey]];
	}
	if (![self secretAccessKey]) {
		[self setAccessKey:[ASIS3Request sharedSecretAccessKey]];
	}
	if (![self dateString]) {
		[self setDate:[NSDate date]];
	}
	if (![self path]) {
		[self setPath:@""];
	}
	
	[self addRequestHeader:@"Date" value:[self dateString]];
	
	[self addRequestHeader:@"x-amz-acl" value:@"private"];

	NSString *stringToSign;
	NSString *canonicalizedResource = [NSString stringWithFormat:@"/%@/%@",[self bucket],[self path]];
	NSString *canonicalizedAmzHeaders = @"x-amz-acl:private";
	if ([[self requestMethod] isEqualToString:@"PUT"]) {
		[self addRequestHeader:@"Content-Type" value:[self mimeType]];
		stringToSign = [NSString stringWithFormat:@"PUT\n\n%@\n%@\n%@",[self mimeType],dateString,canonicalizedResource];
	} else {
		stringToSign = [NSString stringWithFormat:@"%@\n\n\n%@\n%@",[self requestMethod],dateString,canonicalizedResource];
	}
	NSLog(@"%@",stringToSign);
	NSString *signature = [ASIS3Request base64forData:[ASIS3Request HMACSHA1withKey:[self secretAccessKey] forString:stringToSign]];
	NSString *authorizationString = [NSString stringWithFormat:@"AWS %@:%@",[self accessKey],signature];
	[self addRequestHeader:@"Authorization" value:authorizationString];
	
}

#pragma mark Shared access keys

+ (NSString *)sharedAccessKey
{
	return sharedAccessKey;
}

+ (void)setSharedAccessKey:(NSString *)newAccessKey
{
	[sharedAccessKey release];
	sharedAccessKey = [newAccessKey retain];
}

+ (NSString *)sharedSecretAccessKey
{
	return sharedSecretAccessKey;
}

+ (void)setSharedSecretAccessKey:(NSString *)newAccessKey
{
	[sharedSecretAccessKey release];
	sharedSecretAccessKey = [newAccessKey retain];
}


#pragma mark S3 Authentication helpers

// From: http://stackoverflow.com/questions/476455/is-there-a-library-for-iphone-to-work-with-hmac-sha-1-encoding

+ (NSData *)HMACSHA1withKey:(NSString *)key forString:(NSString *)string
{
	NSData *clearTextData = [string dataUsingEncoding:NSUTF8StringEncoding];
	NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
	
	uint8_t digest[CC_SHA1_DIGEST_LENGTH] = {0};
	
	CCHmacContext hmacContext;
	CCHmacInit(&hmacContext, kCCHmacAlgSHA1, keyData.bytes, keyData.length);
	CCHmacUpdate(&hmacContext, clearTextData.bytes, clearTextData.length);
	CCHmacFinal(&hmacContext, digest);
	
	return [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
}


// From: http://www.cocoadev.com/index.pl?BaseSixtyFour

+ (NSString*)base64forData:(NSData*)theData {
	
	const uint8_t* input = (const uint8_t*)[theData bytes];
	NSInteger length = [theData length];
	
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
	
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
	
    for (NSInteger i = 0; i < length; i += 3) {
        NSInteger value = 0;
        for (NSInteger j = i; j < (i + 3); j++) {
            value <<= 8;
			
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
		
        NSInteger index = (i / 3) * 4;
        output[index + 0] =                    table[(value >> 18) & 0x3F];
        output[index + 1] =                    table[(value >> 12) & 0x3F];
        output[index + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[index + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
	
    return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
}


@synthesize bucket;
@synthesize path;
@synthesize dateString;
@synthesize mimeType;
@synthesize accessKey;
@synthesize secretAccessKey;
@end
