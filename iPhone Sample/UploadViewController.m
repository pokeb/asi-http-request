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
	[request setData:[NSMutableData dataWithLength:1024*1024] forKey:@"1mb-of-crap"];
	
	[networkQueue addOperation:request];
	[networkQueue go];
}

- (void)dealloc {
	[networkQueue release];
    [super dealloc];
}

@end
