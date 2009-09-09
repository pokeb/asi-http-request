//
//  UploadViewController.m
//  asi-http-request
//
//  Created by Ben Copsey on 31/12/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import "UploadViewController.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"

@implementation UploadViewController


- (void)awakeFromNib
{
	networkQueue = [[ASINetworkQueue alloc] init];
}

- (IBAction)performLargeUpload:(id)sender
{
	[networkQueue cancelAllOperations];
	[networkQueue setShowAccurateProgress:YES];
	[networkQueue setUploadProgressDelegate:progressIndicator];
	[networkQueue setDelegate:self];
	
	ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ignore"]] autorelease];
	[request setPostValue:@"test" forKey:@"value1"];
	[request setPostValue:@"test" forKey:@"value2"];
	[request setPostValue:@"test" forKey:@"value3"];
	[request setTimeOutSeconds:20];
	
	//Create a 256KB file
	NSData *data = [[[NSMutableData alloc] initWithLength:256*1024] autorelease];
	NSString *path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"file"];
	[data writeToFile:path atomically:NO];
	
	//Add the file 8 times to the request, for a total request size around 2MB
	int i;
	for (i=0; i<8; i++) {
		[request setFile:path forKey:[NSString stringWithFormat:@"file-%hi",i]];
	}
	
	[networkQueue addOperation:request];
	[networkQueue go];
}

- (IBAction)toggleThrottling:(id)sender
{
	[ASIHTTPRequest setShouldThrottleBandwidthForWWAN:[(UISwitch *)sender isOn]];
}

- (void)dealloc {
	[networkQueue release];
    [super dealloc];
}

@end
