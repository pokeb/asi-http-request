//
//  QueueViewController.m
//  asi-http-request
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import "QueueViewController.h"
#import "ASIHTTPRequest.h"

@implementation QueueViewController


- (void)awakeFromNib
{
	networkQueue = [[NSOperationQueue alloc] init];
}

- (IBAction)fetchThreeImages:(id)sender
{
	[imageView1 setImage:nil];
	[imageView2 setImage:nil];
	[imageView3 setImage:nil];
	
	[networkQueue cancelAllOperations];
	[progressIndicator setProgress:0];
	ASIHTTPRequest *request;
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/i/logo.png"]] autorelease];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(imageFetchComplete:)];
	[networkQueue addOperation:request];
	
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/i/trailsnetwork.png"]] autorelease];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(imageFetchComplete:)];
	[networkQueue addOperation:request];
	
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/i/sharedspace20.png"]] autorelease];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(imageFetchComplete:)];
	[networkQueue addOperation:request];
}


- (void)imageFetchComplete:(ASIHTTPRequest *)request
{
	UIImage *img = [UIImage imageWithData:[request receivedData]];
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
	[progressIndicator setProgress:[progressIndicator progress]+0.3333];
	
}

- (void)dealloc {
	[networkQueue release];
    [super dealloc];
}


@end
