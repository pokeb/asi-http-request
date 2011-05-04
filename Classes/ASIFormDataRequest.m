//
//  ASIFormDataRequest.m
//  asi-http-request
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008-2009 All-Seeing Interactive. All rights reserved.
//

#import "ASIFormDataRequest.h"
#import "CCJSONSerialization.h"
#import "CCUserAgent.h"
#import "NSDate-CCAdditions.h"
#import "NSDictionary-CCAdditions.h"
#import "NSString-CCAdditions.h"
#import "SQLogController.h"


static NSString *const ASIFormDataContentTypeHeader = @"Content-Type";

// Private stuff
@interface ASIFormDataRequest ()
@end

@implementation ASIFormDataRequest

@synthesize requestContentType;

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

    NSDictionary *formPartHeaders = [NSDictionary dictionaryWithObjectsAndKeys:contentType, ASIFormDataContentTypeHeader, nil];
	NSDictionary *fileInfo = [NSDictionary dictionaryWithObjectsAndKeys:data, @"data", formPartHeaders, @"formPartHeaders", fileName, @"fileName", nil];
	[[self fileData] setObject:fileInfo forKey:key];
	[self setRequestMethod: @"POST"];
}

- (void)setData:(NSData *)data forKey:(NSString *)key
{
	[self setData:data withFileName:@"file" andContentType:nil forKey:key];
}

- (void)setData:(id)data withFileName:(NSString *)fileName andContentType:(NSString *)contentType forKey:(NSString *)key
{
    NSDictionary *formPartHeaders = [NSDictionary dictionaryWithObjectsAndKeys:contentType, ASIFormDataContentTypeHeader, nil];
    [self setData:data withFileName:fileName formPartHeaders:formPartHeaders forKey:key];
}

- (void)setData:(id)data withFileName:(NSString *)fileName formPartHeaders:(NSDictionary *)formPartHeaders forKey:(NSString *)key
{
    CCCheckCondition(data,, @"Cannot attach a nil data object to form data request");

	if (![self fileData]) {
		[self setFileData:[NSMutableDictionary dictionary]];
	}
    
	if (![formPartHeaders objectForKey:ASIFormDataContentTypeHeader]) {
        formPartHeaders = [[formPartHeaders mutableCopy] autorelease];
        if (!formPartHeaders) {
            formPartHeaders = [NSMutableDictionary dictionary];
        }
        [(NSMutableDictionary *)formPartHeaders setObject:@"application/octet-stream" forKey:ASIFormDataContentTypeHeader];
	}

	NSDictionary *fileInfo = [NSDictionary dictionaryWithObjectsAndKeys:data, @"data", formPartHeaders, @"formPartHeaders", fileName, @"fileName", nil];
	[[self fileData] setObject:fileInfo forKey:key];
	[self setRequestMethod: @"POST"];
}

- (void)buildPostBody
{
	if (![self postData] && ![self fileData]) {
        [super buildPostBody];
        return;
	}

    // Set the content type
	NSString *stringBoundary = @"0xKhTmLbOuNdArY";
    if (self.requestContentType == ASIRequestContentTypeURLEncoded) {
        [self addRequestHeader:ASIFormDataContentTypeHeader value:@"application/x-www-form-urlencoded"];
    } else if (self.requestContentType == ASIRequestContentTypeJSON) {
        [self addRequestHeader:ASIFormDataContentTypeHeader value:@"application/json"];
    } else if (self.requestContentType == ASIRequestContentTypeMultiPart) {
        [self addRequestHeader:ASIFormDataContentTypeHeader value:[NSString stringWithFormat:@"multipart/form-data; boundary=\"%@\"", stringBoundary]];
    } else if (self.requestContentType == ASIRequestContentTypeMultipartMixedSquare) {
        [self addRequestHeader:ASIFormDataContentTypeHeader value:[NSString stringWithFormat:@"multipart/vnd.square-mixed; boundary=\"%@\"", stringBoundary]];
    } else {
        NSAssert(false, @"This content type is not supported. Did you add a new content type?");
    }

    // Don't have to check for the presence of postData because the first conditional ensures that we have that if we don't have fileData
    if (self.requestContentType != ASIRequestContentTypeMultiPart && self.requestContentType != ASIRequestContentTypeMultipartMixedSquare && ![self fileData]) {
        if (self.requestContentType == ASIRequestContentTypeURLEncoded) {
            [self appendPostData:[[[self postData] URLEncodedStringValue] dataUsingEncoding:NSUTF8StringEncoding]];
        } else {
            [self appendPostData:[[[self postData] JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
        }

        [super buildPostBody];
        return;
    }

    // NOTE: We have very little flexibility here when using custom MIME types [sam@squareup.com]
    for (NSDictionary *fileInfo in [fileData allValues]) {
        id fileObject = [fileInfo valueForKey:@"data"];
        if ([fileObject isKindOfClass:[NSString class]]) {
            [self setShouldStreamPostDataFromDisk:YES];
            break;
        }
    }

	[self appendPostData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];

	// Adds post data
	NSData *endItemBoundary = [[NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding];
	NSEnumerator *e = [[self postData] keyEnumerator];
	NSString *key;

	int i=0;
	while ((key = [e nextObject])) {
        id object = [[self postData] objectForKey:key];
        // !!!: This is a hack to properly support log create
        if (self.requestContentType == ASIRequestContentTypeMultipartMixedSquare) {
            if ([object isKindOfClass:[NSDictionary class]]) {
                [self appendPostData:[[NSString stringWithFormat:@"User-Agent: %@\r\n", [CCUserAgent userAgent]] dataUsingEncoding:NSUTF8StringEncoding]];
                [self appendPostData:[[NSString stringWithFormat:@"Content-Type: %@\r\n", [object objectForKey:SQLogContentTypeKey]] dataUsingEncoding:NSUTF8StringEncoding]];
                [self appendPostData:[[NSString stringWithFormat:@"X-Category: %@\r\n", [object objectForKey:SQLogCategoryKey]] dataUsingEncoding:NSUTF8StringEncoding]];
                [self appendPostData:[[NSString stringWithFormat:@"X-UUID: %@\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
                [self appendPostData:[[NSString stringWithFormat:@"X-Timestamp: %@\r\n\r\n", [object objectForKey:SQLogTimestampKey]] dataUsingEncoding:NSUTF8StringEncoding]];
                [self appendPostData:[[object JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
            } else {
                [self appendPostData:[object dataUsingEncoding:NSUTF8StringEncoding]];
            }
        } else {
            [self appendPostData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
            [self appendPostData:[object dataUsingEncoding:NSUTF8StringEncoding]];
        }
		i++;
		if (i != [[self postData] count] || [[self fileData] count] > 0) { //Only add the boundary if this is not the last item in the post body
			[self appendPostData:endItemBoundary];
		}
	}

	// Adds files to upload
	e = [fileData keyEnumerator];
	i=0;
	while ((key = [e nextObject])) {
		NSDictionary *fileInfo = [[self fileData] objectForKey:key];
		id file = [fileInfo objectForKey:@"data"];
        NSDictionary *formPartHeaders = [fileInfo objectForKey:@"formPartHeaders"];
		NSString *fileName = [fileInfo objectForKey:@"fileName"];

		[self appendPostData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, fileName] dataUsingEncoding:NSUTF8StringEncoding]];
        for (NSString *formPartHeaderKey in [formPartHeaders allKeys]) {
            NSString *formPartHeaderValue = [formPartHeaders objectForKey:formPartHeaderKey];
      		[self appendPostData:[[NSString stringWithFormat:@"%@: %@\r\n", formPartHeaderKey, formPartHeaderValue] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        [self appendPostData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];

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
