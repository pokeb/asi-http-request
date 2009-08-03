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
	if (!postData) {
		postData = [[NSMutableDictionary alloc] init];
	}
	[postData setValue:[value description] forKey:key];
	[self setRequestMethod:@"POST"];
}

- (void)setFile:(NSString *)filePath forKey:(NSString *)key
{
	[self setFileDataContainerObject:filePath fileName:@"file" contentType:@"application/octet-stream" forKey:key];
}

- (void)setData:(NSData *)data forKey:(NSString *)key
{
	[self setFileDataContainerObject:data fileName:@"file" contentType:@"application/octet-stream" forKey:key];
}

- (void)setFileDataContainerObject:(id)data
						  fileName:(NSString *)fileName
					   contentType:(NSString *)contentType
							forKey:(NSString *)key {
	if (!fileData) {
		fileData = [[NSMutableDictionary alloc] initWithCapacity: 0];
	}

	NSDictionary *fileInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  data, @"fileDataContainerObject", contentType, @"contentType", fileName, @"fileName", nil];
	[fileData setObject:fileInfo forKey:key];
	[self setRequestMethod: @"POST"];
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
	e = [fileData keyEnumerator];
	i=0;
	while (key = [e nextObject]) {
		NSDictionary *fileInfo = [fileData objectForKey:key];
		id file = [fileInfo objectForKey:@"fileDataContainerObject"];
		NSString *contentType = [fileInfo objectForKey:@"contentType"];
		NSString *fileName = [fileInfo objectForKey:@"fileName"];

		NSString *contentTypeHeader = [NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", contentType];

		[self appendPostData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, fileName] dataUsingEncoding:NSUTF8StringEncoding]];
		[self appendPostData:[contentTypeHeader dataUsingEncoding:NSUTF8StringEncoding]];

		if ([file isKindOfClass:[NSString class]]) {
			[self appendPostDataFromFile:file];
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
