//
//  ASIFormDataRequest.m
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008-2009 All-Seeing Interactive. All rights reserved.
//

#import "ASIFormDataRequest.h"


// Private stuff
@interface ASIFormDataRequest ()
- (void)buildMultipartFormDataPostBody;
- (void)buildURLEncodedPostBody;
- (void)appendPostString:(NSString *)string;

@property (retain) NSMutableDictionary *postData;
@property (retain) NSMutableDictionary *fileData;

#if DEBUG_FORM_DATA_REQUEST
- (void)addToDebugBody:(NSString *)string;
@property (retain, nonatomic) NSString *debugBodyString;
#endif

@end

@implementation ASIFormDataRequest

#pragma mark utilities
- (NSString*)encodeURL:(NSString *)string
{
	NSString *newString = [(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding([self stringEncoding])) autorelease];
	if (newString) {
		return newString;
	}
	return @"";
}

#pragma mark init / dealloc

+ (id)requestWithURL:(NSURL *)newURL
{
	return [[[self alloc] initWithURL:newURL] autorelease];
}

- (id)initWithURL:(NSURL *)newURL
{
	self = [super initWithURL:newURL];
	[self setPostFormat:ASIURLEncodedPostFormat];
	[self setStringEncoding:NSUTF8StringEncoding];
	return self;
}

- (void)dealloc
{
#if DEBUG_FORM_DATA_REQUEST
	[debugBodyString release]; 
#endif
	
	[postData release];
	[fileData release];
	[super dealloc];
}

#pragma mark setup request

- (void)setPostValue:(id <NSObject>)value forKey:(NSString *)key
{
	if (![self postData]) {
		[self setPostData:[NSMutableDictionary dictionary]];
	}
	[[self postData] setValue:[value description] forKey:key];
}

- (void)setFile:(NSString *)filePath forKey:(NSString *)key
{
	[self setFile:filePath withFileName:nil andContentType:nil forKey:key];
}

- (void)setFile:(id)data withFileName:(NSString *)fileName andContentType:(NSString *)contentType forKey:(NSString *)key
{
	if (![self fileData]) {
		[self setFileData:[NSMutableDictionary dictionary]];
	}
	
	// If data is a path to a local file
	if ([data isKindOfClass:[NSString class]]) {
		BOOL isDirectory = NO;
		BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:(NSString *)data isDirectory:&isDirectory];
		if (!fileExists || isDirectory) {
			[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:ASIInternalErrorWhileBuildingRequestType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"No file exists at %@",data],NSLocalizedDescriptionKey,nil]]];
		}

		// If the caller didn't specify a custom file name, we'll use the file name of the file we were passed
		if (!fileName) {
			fileName = [(NSString *)data lastPathComponent];
		}
	
		// If we were given the path to a file, and the user didn't specify a mime type, we can detect it from the file extension
		if (!contentType) {
			contentType = [ASIHTTPRequest mimeTypeForFileAtPath:data];
		}
	}
	
	NSDictionary *fileInfo = [NSDictionary dictionaryWithObjectsAndKeys:data, @"data", contentType, @"contentType", fileName, @"fileName", nil];
	[[self fileData] setObject:fileInfo forKey:key];
}

- (void)setData:(NSData *)data forKey:(NSString *)key
{
	[self setData:data withFileName:@"file" andContentType:nil forKey:key];
}

- (void)setData:(id)data withFileName:(NSString *)fileName andContentType:(NSString *)contentType forKey:(NSString *)key
{
	if (![self fileData]) {
		[self setFileData:[NSMutableDictionary dictionary]];
	}
	if (!contentType) {
		contentType = @"application/octet-stream";
	}
	
	NSDictionary *fileInfo = [NSDictionary dictionaryWithObjectsAndKeys:data, @"data", contentType, @"contentType", fileName, @"fileName", nil];
	[[self fileData] setObject:fileInfo forKey:key];
}

- (void)buildPostBody
{
	if ([self haveBuiltPostBody]) {
		return;
	}
	if (![[self requestMethod] isEqualToString:@"PUT"]) {
		[self setRequestMethod:@"POST"];
	}
	
#if DEBUG_FORM_DATA_REQUEST
	[self setDebugBodyString:@""];	
#endif
	
	if (![self postData] && ![self fileData]) {
		[super buildPostBody];
		return;
	}	
	if ([[self fileData] count] > 0) {
		[self setShouldStreamPostDataFromDisk:YES];
	}
	
	if ([self postFormat] == ASIURLEncodedPostFormat) {
		[self buildURLEncodedPostBody];
	} else {
		[self buildMultipartFormDataPostBody];
	}

	[super buildPostBody];
	
#if DEBUG_FORM_DATA_REQUEST
	NSLog(@"%@",[self debugBodyString]);
	[self setDebugBodyString:nil];
#endif
}


- (void)buildMultipartFormDataPostBody
{
#if DEBUG_FORM_DATA_REQUEST
	[self addToDebugBody:@"\r\n==== Building a multipart/form-data body ====\r\n"];
#endif
	
	NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding([self stringEncoding]));
	
	// Set your own boundary string only if really obsessive. We don't bother to check if post data contains the boundary, since it's pretty unlikely that it does.
	NSString *stringBoundary = @"0xKhTmLbOuNdArY";
	
	[self addRequestHeader:@"Content-Type" value:[NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@", charset, stringBoundary]];
	
	[self appendPostString:[NSString stringWithFormat:@"--%@\r\n",stringBoundary]];
	
	// Adds post data
	NSString *endItemBoundary = [NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary];
	NSEnumerator *e = [[self postData] keyEnumerator];
	NSString *key;
	NSUInteger i=0;
	while (key = [e nextObject]) {
		[self appendPostString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",key]];
		[self appendPostString:[[self postData] objectForKey:key]];
		i++;
		if (i != [[self postData] count] || [[self fileData] count] > 0) { //Only add the boundary if this is not the last item in the post body
			[self appendPostString:endItemBoundary];
		}
	}
	
	// Adds files to upload
	e = [fileData keyEnumerator];
	i=0;
	while (key = [e nextObject]) {
		NSDictionary *fileInfo = [[self fileData] objectForKey:key];
		id file = [fileInfo objectForKey:@"data"];
		NSString *contentType = [fileInfo objectForKey:@"contentType"];
		NSString *fileName = [fileInfo objectForKey:@"fileName"];
		
		[self appendPostString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, fileName]];
		[self appendPostString:[NSString stringWithFormat:@"Content-Type: %@; charset=%@\r\n\r\n", contentType, charset]];
		
		if ([file isKindOfClass:[NSString class]]) {
			[self appendPostDataFromFile:file];
		} else {
			[self appendPostData:file];
		}
		i++;
		// Only add the boundary if this is not the last item in the post body
		if (i != [[self fileData] count]) { 
			[self appendPostString:endItemBoundary];
		}
	}
	
	[self appendPostString:[NSString stringWithFormat:@"\r\n--%@--\r\n",stringBoundary]];
	
#if DEBUG_FORM_DATA_REQUEST
	[self addToDebugBody:@"==== End of multipart/form-data body ====\r\n"];
#endif
}

- (void)buildURLEncodedPostBody
{

	// We can't post binary data using application/x-www-form-urlencoded
	if ([[self fileData] count] > 0) {
		[self setPostFormat:ASIMultipartFormDataPostFormat];
		[self buildMultipartFormDataPostBody];
		return;
	}
	
#if DEBUG_FORM_DATA_REQUEST
	[self addToDebugBody:@"\r\n==== Building an application/x-www-form-urlencoded body ====\r\n"]; 
#endif
	
	
	NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding([self stringEncoding]));

	[self addRequestHeader:@"Content-Type" value:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@",charset]];

	
	NSEnumerator *e = [[self postData] keyEnumerator];
	NSString *key;
	int i=0;
	int count = [[self postData] count]-1;
	while (key = [e nextObject]) {
        NSString *data = [NSString stringWithFormat:@"%@=%@%@", [self encodeURL:key], [self encodeURL:[[self postData] objectForKey:key]],(i<count ?  @"&" : @"")]; 
		[self appendPostString:data];
		i++;
	}
#if DEBUG_FORM_DATA_REQUEST
	[self addToDebugBody:@"\r\n==== End of application/x-www-form-urlencoded body ====\r\n"]; 
#endif
}

- (void)appendPostString:(NSString *)string
{
#if DEBUG_FORM_DATA_REQUEST
	[self addToDebugBody:string];
#endif
	[super appendPostData:[string dataUsingEncoding:[self stringEncoding]]];
}

#if DEBUG_FORM_DATA_REQUEST
- (void)appendPostData:(NSData *)data
{
	[self addToDebugBody:[NSString stringWithFormat:@"[%lu bytes of data]",(unsigned long)[data length]]];
	[super appendPostData:data];
}

- (void)appendPostDataFromFile:(NSString *)file
{
	NSError *err = nil;
	unsigned long long fileSize = [[[[NSFileManager defaultManager] attributesOfItemAtPath:file error:&err] objectForKey:NSFileSize] unsignedLongLongValue];
	if (err) {
		[self addToDebugBody:[NSString stringWithFormat:@"[Error: Failed to obtain the size of the file at '%@']",file]];
	} else {
		[self addToDebugBody:[NSString stringWithFormat:@"[%llu bytes of data from file '%@']",fileSize,file]];
	}

	[super appendPostDataFromFile:file];
}

- (void)addToDebugBody:(NSString *)string
{
	[self setDebugBodyString:[[self debugBodyString] stringByAppendingString:string]];
}
#endif

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
	ASIFormDataRequest *newRequest = [super copyWithZone:zone];
	[newRequest setPostData:[[[self postData] copyWithZone:zone] autorelease]];
	[newRequest setFileData:[[[self fileData] copyWithZone:zone] autorelease]];
	[newRequest setPostFormat:[self postFormat]];
	[newRequest setStringEncoding:[self stringEncoding]];
	[newRequest setRequestMethod:[self requestMethod]];
	return newRequest;
}

@synthesize postData;
@synthesize fileData;
@synthesize postFormat;
@synthesize stringEncoding;
#if DEBUG_FORM_DATA_REQUEST
@synthesize debugBodyString;
#endif
@end
