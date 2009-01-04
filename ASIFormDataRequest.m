//
//  ASIFormDataRequest.m
//  asi-http-request
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import "ASIFormDataRequest.h"


@implementation ASIFormDataRequest

#pragma mark init / dealloc

- (id)initWithURL:(NSURL *)newURL
{
	self = [super initWithURL:newURL];
	postData = nil;
	fileData = nil;	
	return self;
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
	if (!postData) {
		postData = [[NSMutableDictionary alloc] init];
	}
	[postData setValue:[value description] forKey:key];
	[self setRequestMethod:@"POST"];
}

- (void)setFile:(NSString *)filePath forKey:(NSString *)key
{
	if (!fileData) {
		fileData = [[NSMutableDictionary alloc] init];
	}
	NSMutableDictionary *file = [[[NSMutableDictionary alloc] init] autorelease];
	[file setObject:[NSData dataWithContentsOfFile:filePath options:NSUncachedRead error:NULL] forKey:@"data"];
	[file setObject:[filePath lastPathComponent] forKey:@"filename"];
	[fileData setValue:file forKey:key];
	[self setRequestMethod:@"POST"];
}

- (void)setData:(NSData *)data forKey:(NSString *)key
{
	if (!fileData) {
		fileData = [[NSMutableDictionary alloc] init];
	}
	NSMutableDictionary *file = [[[NSMutableDictionary alloc] init] autorelease];
	[file setObject:data forKey:@"data"];
	[file setObject:@"file" forKey:@"filename"];
	[fileData setValue:file forKey:key];
	[self setRequestMethod:@"POST"];	
}

- (void)buildPostBody
{
	if (!postData && ! fileData) {
		[super buildPostBody];
		return;
	}	

	NSMutableData *body = [[[NSMutableData alloc] init] autorelease];
	
	// Set your own boundary string only if really obsessive. We don't bother to check if post data contains the boundary, since it's pretty unlikely that it does.
	NSString *stringBoundary = @"0xKhTmLbOuNdArY";
	
	[self addRequestHeader:@"Content-Type" value:[NSString stringWithFormat:@"multipart/form-data; boundary=%@",stringBoundary]];
	
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	// Adds post data
	NSData *endItemBoundary = [[NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding];
	NSEnumerator *e = [postData keyEnumerator];
	NSString *key;
	int i=0;
	while (key = [e nextObject]) {
		[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",key] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[postData objectForKey:key] dataUsingEncoding:NSUTF8StringEncoding]];
		i++;
		if (i != [postData count] || [fileData count] > 0) { //Only add the boundary if this is not the last item in the post body
			[body appendData:endItemBoundary];
		}
	}
	
	// Adds files to upload
	NSData *contentTypeHeader = [[NSString stringWithString:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding];
	e = [fileData keyEnumerator];
	i=0;
	while (key = [e nextObject]) {
		NSDictionary *fileInfo = [fileData objectForKey:key];
		[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n",key,[fileInfo objectForKey:@"filename"]] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:contentTypeHeader];
		[body appendData: [fileInfo objectForKey:@"data"]];
		i++;
		// Only add the boundary if this is not the last item in the post body
		if (i != [fileData count]) { 
			[body appendData:endItemBoundary];
		}
	}
	
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[self setPostBody:body];
	

	[super buildPostBody];
}




@end
