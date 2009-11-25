//
//  SynchronousViewController.m
//  asi-http-request
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import "SynchronousViewController.h"
#import "ASIHTTPRequest.h"

@implementation SynchronousViewController

- (IBAction)simpleURLFetch:(id)sender
{
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/"]] autorelease];
	
	//Customise our user agent, for no real reason
	[request addRequestHeader:@"User-Agent" value:@"ASIHTTPRequest"];
	
	[request startSynchronous];
	if ([request error]) {
		[htmlSource setText:[[request error] localizedDescription]];
	} else if ([request responseString]) {
		[htmlSource setText:[request responseString]];
	}
}


@end
