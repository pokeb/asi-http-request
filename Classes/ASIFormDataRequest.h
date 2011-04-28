//
//  ASIFormDataRequest.h
//  asi-http-request
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008-2009 All-Seeing Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"


typedef enum {
    ASIRequestContentTypeMultiPart, // default
    ASIRequestContentTypeURLEncoded,
    ASIRequestContentTypeJSON,
    ASIRequestContentTypeMultipartMixedSquare
} ASIRequestContentType;


@interface ASIFormDataRequest : ASIHTTPRequest {
	// Parameters that will be POSTed to the url
	NSMutableDictionary *postData;

	// Files that will be POSTed to the url
	NSMutableDictionary *fileData;

    // Set the content type
    ASIRequestContentType requestContentType;
}

@property (retain) NSMutableDictionary *postData;
@property (retain) NSMutableDictionary *fileData;
@property (nonatomic) ASIRequestContentType requestContentType;

#pragma mark setup request

// Add a POST variable to the request
- (void)setPostValue:(id <NSObject>)value forKey:(NSString *)key;

// Add the contents of a local file to the request
- (void)setFile:(NSString *)filePath forKey:(NSString *)key;

// Same as above, but you can specify the content-type and file name
- (void)setFile:(id)data withFileName:(NSString *)fileName andContentType:(NSString *)contentType forKey:(NSString *)key;

// Add the contents of an NSData object to the request
- (void)setData:(NSData *)data forKey:(NSString *)key;

// Same as above, but you can specify the content-type and file name
- (void)setData:(id)data withFileName:(NSString *)fileName andContentType:(NSString *)contentType forKey:(NSString *)key;

// Same as above, but you can specify any form part headers you want
- (void)setData:(id)data withFileName:(NSString *)fileName formPartHeaders:(NSDictionary *)formPartHeaders forKey:(NSString *)key;

@end
