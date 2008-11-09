//
//  ASIFormDataRequest.h
//  asi-http-request
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import "ASIHTTPRequest.h"

@interface ASIFormDataRequest : ASIHTTPRequest {

	// Parameters that will be POSTed to the url
	NSMutableDictionary *postData;
	
	// Files that will be POSTed to the url
	NSMutableDictionary *fileData;
	
}

#pragma mark setup request

// Add a POST variable to the request
- (void)setPostValue:(id)value forKey:(NSString *)key;

// Add the contents of a local file as a POST variable to the request
- (void)setFile:(NSString *)filePath forKey:(NSString *)key;

@end
