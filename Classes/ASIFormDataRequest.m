//
//  ASIFormDataRequest.m
//  asi-http-request
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008-2009 All-Seeing Interactive. All rights reserved.
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
	[fileData setValue:filePath forKey:key];
	[self setRequestMethod:@"POST"];
}

- (void)setData:(NSData *)data forKey:(NSString *)key
{
	if (!fileData) {
		fileData = [[NSMutableDictionary alloc] init];
	}
	[fileData setObject:data forKey:key];
	[self setRequestMethod:@"POST"];	
}

- (void)buildPostBody
{
	if (!postData && ! fileData) {
		[super buildPostBody];
		return;
	}	
	if ([fileData count] > 0) {
		[self setShouldStreamPostDataFromDisk:YES];
	}
	 
	
	// Set your own boundary string only if really obsessive. We don't bother to check if post data contains the boundary, since it's pretty unlikely that it does.
	NSString *stringBoundary = @"0xKhTmLbOuNdArY";
	
	[self addRequestHeader:@"Content-Type" value:[NSString stringWithFormat:@"multipart/form-data; boundary=%@",stringBoundary]];
	
	[self appendPostData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	// Adds post data
	NSData *endItemBoundary = [[NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding];
	NSEnumerator *e = [postData keyEnumerator];
	NSString *key;
	int i=0;
	while (key = [e nextObject]) {
		[self appendPostData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",key] dataUsingEncoding:NSUTF8StringEncoding]];
		[self appendPostData:[[postData objectForKey:key] dataUsingEncoding:NSUTF8StringEncoding]];
		i++;
		if (i != [postData count] || [fileData count] > 0) { //Only add the boundary if this is not the last item in the post body
			[self appendPostData:endItemBoundary];
		}
	}
	
	// Adds files to upload
	NSData *contentTypeHeader = [[NSString stringWithString:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding];
	e = [fileData keyEnumerator];
	i=0;
	while (key = [e nextObject]) {
		NSString *fileName = @"file";
		id file =  [fileData objectForKey:key];
		if ([file isKindOfClass:[NSString class]]) {
			fileName = (NSString *)file;
		}
		[self appendPostData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n",key,fileName] dataUsingEncoding:NSUTF8StringEncoding]];
		[self appendPostData:contentTypeHeader];
		if ([file isKindOfClass:[NSString class]]) {
			[self appendPostDataFromFile:fileName];
		} else {
			[self appendPostData:file];
		}
		i++;
		// Only add the boundary if this is not the last item in the post body
		if (i != [fileData count]) { 
			[self appendPostData:endItemBoundary];
		}
	}
	
	[self appendPostData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[super buildPostBody];
}




@end
