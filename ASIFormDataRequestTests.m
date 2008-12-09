//
//  ASIFormDataRequestTests.m
//  asi-http-request
//
//  Created by Ben Copsey on 08/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import "ASIFormDataRequestTests.h"
#import "ASIFormDataRequest.h"

@implementation ASIFormDataRequestTests


- (void)testPostWithFileUpload
{
	NSURL *url = [NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/post"];
	
	//Create a 32kb file
	unsigned int size = 1024*32;
	NSMutableData *data = [NSMutableData dataWithLength:size];
	NSString *path = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"bigfile"];
	[data writeToFile:path atomically:NO];
	
	ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
	[request setPostValue:@"foo" forKey:@"post_var"];
	[request setFile:path forKey:@"file"];
	[request start];

	BOOL success = ([[request dataString] isEqualToString:[NSString stringWithFormat:@"post_var: %@\r\nfile_name: %@\r\nfile_size: %hu",@"foo",@"bigfile",size]]);
	STAssertTrue(success,@"Failed to upload the correct data (using local file)");	
	
	//Try the same with the raw data
	request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
	[request setPostValue:@"foo" forKey:@"post_var"];
	[request setData:data forKey:@"file"];
	[request start];
	
	success = ([[request dataString] isEqualToString:[NSString stringWithFormat:@"post_var: %@\r\nfile_name: %@\r\nfile_size: %hu",@"foo",@"file",size]]);
	STAssertTrue(success,@"Failed to upload the correct data (using NSData)");	
}
 


@end
