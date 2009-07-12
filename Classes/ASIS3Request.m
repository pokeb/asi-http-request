//
//  ASIS3Request.m
//
//  Created by Ben Copsey on 30/06/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import "ASIS3Request.h"
#import <CommonCrypto/CommonHMAC.h>

NSString* const ASIS3AccessPolicyPrivate = @"private";
NSString* const ASIS3AccessPolicyPublicRead = @"public-read";
NSString* const ASIS3AccessPolicyPublicReadWrote = @"public-read-write";
NSString* const ASIS3AccessPolicyAuthenticatedRead = @"authenticated-read";

static NSString *sharedAccessKey = nil;
static NSString *sharedSecretAccessKey = nil;

// Private stuff
@interface ASIHTTPRequest ()
	+ (NSData *)HMACSHA1withKey:(NSString *)key forString:(NSString *)string;
	+ (NSString *)base64forData:(NSData *)theData;
@end

@implementation ASIS3Request

- (void)dealloc
{
	[bucket release];
	[path release];
	[dateString release];
	[mimeType release];
	[accessKey release];
	[secretAccessKey release];
	[super dealloc];
}

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


+ (id)listRequestWithBucket:(NSString *)bucket prefix:(NSString *)prefix maxResults:(int)maxResults marker:(NSString *)marker
{
	ASIS3Request *request =  [[[ASIS3Request alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@.s3.amazonaws.com/?prefix=/%@&max-keys=%hi&marker=%@",bucket,prefix,maxResults,marker]]] autorelease];
	[request setBucket:bucket];
	return request;
}

+ (NSString *)mimeTypeForFileAtPath:(NSString *)path
{
// NSTask does seem to exist in the 2.2.1 SDK, though it's not in the 3.0 SDK. It's probably best if we just use a generic mime type on iPhone all the time.
#if TARGET_OS_IPHONE
	return @"application/octet-stream";
	
// Grab the mime type using an NSTask to run the 'file' program, with the Mac OS-specific parameters to grab the mime type
// Perhaps there is a better way to do this?
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
	// If an access key / secret access keyu haven't been set for this request, let's use the shared keys
	if (![self accessKey]) {
		[self setAccessKey:[ASIS3Request sharedAccessKey]];
	}
	if (![self secretAccessKey]) {
		[self setAccessKey:[ASIS3Request sharedSecretAccessKey]];
	}
	// If a date string hasn't been set, we'll create one from the current time
	if (![self dateString]) {
		[self setDate:[NSDate date]];
	}
	[self addRequestHeader:@"Date" value:[self dateString]];
	
	// Ensure our formatted string doesn't use '(null)' for the empty path
	if (![self path]) {
		[self setPath:@""];
	}

	
	NSString *canonicalizedResource = [NSString stringWithFormat:@"/%@/%@",[self bucket],[self path]];
	
	// Add a header for the access policy if one was set, otherwise we won't add one (and S3 will default to private)
	NSString *canonicalizedAmzHeaders = @"";
	if ([self accessPolicy]) {
		[self addRequestHeader:@"x-amz-acl" value:[self accessPolicy]];
		canonicalizedAmzHeaders = [NSString stringWithFormat:@"x-amz-acl:%@\n",[self accessPolicy]];
	}
	
	// Jump through hoops while eating hot food
	NSString *stringToSign;
	if ([[self requestMethod] isEqualToString:@"PUT"]) {
		[self addRequestHeader:@"Content-Type" value:[self mimeType]];
		stringToSign = [NSString stringWithFormat:@"PUT\n\n%@\n%@\n%@%@",[self mimeType],dateString,canonicalizedAmzHeaders,canonicalizedResource];
	} else {
		stringToSign = [NSString stringWithFormat:@"%@\n\n\n%@\n%@%@",[self requestMethod],dateString,canonicalizedAmzHeaders,canonicalizedResource];
	}
	NSString *signature = [ASIS3Request base64forData:[ASIS3Request HMACSHA1withKey:[self secretAccessKey] forString:stringToSign]];
	NSString *authorizationString = [NSString stringWithFormat:@"AWS %@:%@",[self accessKey],signature];
	[self addRequestHeader:@"Authorization" value:authorizationString];
}

- (void)startRequest
{
	[self generateS3Headers];
	[super startRequest];
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
@synthesize accessPolicy;
@end
