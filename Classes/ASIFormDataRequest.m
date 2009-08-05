//
//  ASIFormDataRequest.m
//  asi-http-request
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008-2009 All-Seeing Interactive. All rights reserved.
//

#import "ASIFormDataRequest.h"


// Private stuff
@interface ASIFormDataRequest ()
@property (retain) NSMutableDictionary *postData;
@property (retain) NSMutableDictionary *fileData;
@end

@implementation ASIFormDataRequest

#pragma mark init / dealloc

+ (id)requestWithURL:(NSURL *)newURL
{
	return [[[self alloc] initWithURL:newURL] autorelease];
}

- (void)dealloc
{
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
	[self setRequestMethod:@"POST"];
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
	
		// If we were given the path to a file, and the user didn't specify a mime type, we can detect it (currently only on Mac OS)
		// Will return 'application/octet-stream' on iPhone, or if the mime type cannot be determined
		if (!contentType) {
			contentType = [ASIHTTPRequest mimeTypeForFileAtPath:data];
		}
	}
	
	NSDictionary *fileInfo = [NSDictionary dictionaryWithObjectsAndKeys:data, @"data", contentType, @"contentType", fileName, @"fileName", nil];
	[[self fileData] setObject:fileInfo forKey:key];
	[self setRequestMethod: @"POST"];
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
	[self setRequestMethod: @"POST"];
}

- (void)buildPostBody
{
	if (![self postData] && ![self fileData]) {
		[super buildPostBody];
		return;
	}	
	if ([[self fileData] count] > 0) {
		[self setShouldStreamPostDataFromDisk:YES];
	}
	 
	
	// Set your own boundary string only if really obsessive. We don't bother to check if post data contains the boundary, since it's pretty unlikely that it does.
	NSString *stringBoundary = @"0xKhTmLbOuNdArY";
	
	[self addRequestHeader:@"Content-Type" value:[NSString stringWithFormat:@"multipart/form-data; boundary=%@",stringBoundary]];
	
	[self appendPostData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	// Adds post data
	NSData *endItemBoundary = [[NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding];
	NSEnumerator *e = [[self postData] keyEnumerator];
	NSString *key;
	int i=0;
	while (key = [e nextObject]) {
		[self appendPostData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",key] dataUsingEncoding:NSUTF8StringEncoding]];
		[self appendPostData:[[[self postData] objectForKey:key] dataUsingEncoding:NSUTF8StringEncoding]];
		i++;
		if (i != [[self postData] count] || [[self fileData] count] > 0) { //Only add the boundary if this is not the last item in the post body
			[self appendPostData:endItemBoundary];
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

		[self appendPostData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, fileName] dataUsingEncoding:NSUTF8StringEncoding]];
		[self appendPostData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", contentType] dataUsingEncoding:NSUTF8StringEncoding]];

		if ([file isKindOfClass:[NSString class]]) {
			[self appendPostDataFromFile:file];
		} else {
			[self appendPostData:file];
		}
		i++;
		// Only add the boundary if this is not the last item in the post body
		if (i != [[self fileData] count]) { 
			[self appendPostData:endItemBoundary];
		}
	}
	
	[self appendPostData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[super buildPostBody];
}


@synthesize fileData;
@synthesize postData;

@end
