//
//  QueueViewController.m
//  asi-http-request
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import "QueueViewController.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"

@implementation QueueViewController


- (void)awakeFromNib
{
	networkQueue = [[ASINetworkQueue alloc] init];
}

- (IBAction)fetchThreeImages:(id)sender
{
	[imageView1 setImage:nil];
	[imageView2 setImage:nil];
	[imageView3 setImage:nil];
	
	[networkQueue cancelAllOperations];
	[networkQueue setDownloadProgressDelegate:progressIndicator];
	[networkQueue setRequestDidFinishSelector:@selector(imageFetchComplete:)];
	[networkQueue setShowAccurateProgress:[accurateProgress isOn]];
	[networkQueue setDelegate:self];
	
	ASIHTTPRequest *request;
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/images/small-image.jpg"]];
	[request setDownloadDestinationPath:[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"1.png"]];
	[networkQueue addOperation:request];
	
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/images/medium-image.jpg"]] autorelease];
	[request setDownloadDestinationPath:[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"2.png"]];
	[networkQueue addOperation:request];
	
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/images/large-image.jpg"]] autorelease];
	[request setDownloadDestinationPath:[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"3.png"]];
	[networkQueue addOperation:request];
	
	[networkQueue go];
}


- (void)imageFetchComplete:(ASIHTTPRequest *)request
{
	UIImage *img = [UIImage imageWithContentsOfFile:[request downloadDestinationPath]];
	if (img) {
		if ([imageView1 image]) {
			if ([imageView2 image]) {
				[imageView3 setImage:img];
			} else {
				[imageView2 setImage:img];
			}
		} else {
			[imageView1 setImage:img];
		}
	}
}

- (void)dealloc {
	[networkQueue release];
    [super dealloc];
}


@end
