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
	
	//Create a 32kb file
	unsigned int size = 1024*32;
	NSMutableData *data = [NSMutableData dataWithLength:size];
	NSString *path = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"bigfile"];
	[data writeToFile:path atomically:NO];
	
	ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:@"http:/http://allseeing-i.com/asi-http-request/tests/post"]] autorelease];
	[request setPostValue:@"foo" forKey:@"post_var"];
	[request setFile:path forKey:@"file"];
	[request start];

	
	BOOL success = ([[request dataString] isEqualToString:[NSString stringWithFormat:@"post_var: %@\r\nfile_name: %@\r\nfile_size: %hu",@"foo",@"bigfile",size]]);
	STAssertTrue(success,@"Failed to upload the correct data");	
}
 


@end
