//
//  AppDelegate.m
//
//  Created by Ben Copsey on 09/07/2008.
//  Copyright 2008 All-Seeing Interactive Ltd. All rights reserved.
//

#import "AppDelegate.h"
#import "ASIHTTPRequest.h"

@implementation AppDelegate

- (id)init
{
	[super init];
	networkQueue = [[NSOperationQueue alloc] init];
	return self;
}

- (void)dealloc
{
	[networkQueue release];
	[super dealloc];
}


- (IBAction)simpleURLFetch:(id)sender
{
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com"]] autorelease];
	
	//Customise our user agent, for no real reason
	[request addRequestHeader:@"User-Agent" value:@"ASIHTTPRequest"];
	
	[request start];
	if ([request dataString]) {
		[htmlSource setString:[request dataString]];
	}
}


- (IBAction)URLFetchWithProgress:(id)sender
{
	[networkQueue cancelAllOperations];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://trails-network.net/Downloads/MemexTrails_1.0b1.zip"]] autorelease];
	[request setDelegate:self];
	[request setDownloadProgressDelegate:progressIndicator];
	[request setDidFinishSelector:@selector(URLFetchWithProgressComplete:)];
	[request setDownloadDestinationPath:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"MemexTrails_1.0b1.zip"]];
	[networkQueue addOperation:request];
}

- (void)URLFetchWithProgressComplete:(ASIHTTPRequest *)request
{
	if ([request error]) {
		[fileLocation setStringValue:[NSString stringWithFormat:@"An error occurred: %@",[[[request error] userInfo] objectForKey:@"Title"]]];
	} else {
		[fileLocation setStringValue:[NSString stringWithFormat:@"File downloaded to %@",[request downloadDestinationPath]]];
	}
}

- (IBAction)fetchThreeImages:(id)sender
{
	[imageView1 setImage:nil];
	[imageView2 setImage:nil];
	[imageView3 setImage:nil];
	
	[networkQueue cancelAllOperations];
	[progressIndicator setDoubleValue:0];
	[progressIndicator setMaxValue:3];
	ASIHTTPRequest *request;
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/i/logo.png"]] autorelease];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(imageFetchComplete:)];
	[request setDownloadDestinationPath:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"1.png"]];
	[networkQueue addOperation:request];
	
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/i/trailsnetwork.png"]] autorelease];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(imageFetchComplete:)];
	[request setDownloadDestinationPath:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"2.png"]];
	[networkQueue addOperation:request];
	
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/i/sharedspace20.png"]] autorelease];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(imageFetchComplete:)];
	[request setDownloadDestinationPath:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"3.png"]];
	[networkQueue addOperation:request];
}


- (void)imageFetchComplete:(ASIHTTPRequest *)request
{
	NSImage *img = [[[NSImage alloc] initWithContentsOfFile:[request downloadDestinationPath]] autorelease];
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
	[progressIndicator incrementBy:1];

}


- (IBAction)fetchTopSecretInformation:(id)sender
{
	[networkQueue cancelAllOperations];
	[progressIndicator setDoubleValue:0];
	ASIHTTPRequest *request;
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/top_secret/"]] autorelease];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(topSecretFetchComplete:)];
	[request setUsesKeychain:[keychainCheckbox state]];
	[networkQueue addOperation:request];

}

- (IBAction)topSecretFetchComplete:(ASIHTTPRequest *)request
{
	if (![request error]) {
		[topSecretInfo setStringValue:[request dataString]];
		[topSecretInfo setFont:[NSFont boldSystemFontOfSize:13]];
	}
}

- (void)authorizationNeededForRequest:(ASIHTTPRequest *)request
{
	[realm setStringValue:[request authenticationRealm]];
	[host setStringValue:[[request url] host]];

	[NSApp beginSheet: loginWindow
		modalForWindow: window
		modalDelegate: self
		didEndSelector: @selector(authSheetDidEnd:returnCode:contextInfo:)
		contextInfo: request];
}

- (IBAction)dismissAuthSheet:(id)sender {
    [[NSApplication sharedApplication] endSheet: loginWindow returnCode: [(NSControl*)sender tag]];
}

- (void)authSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	ASIHTTPRequest *request = (ASIHTTPRequest *)contextInfo;
    if (returnCode == NSOKButton) {
		[request setUsername:[[[username stringValue] copy] autorelease] andPassword:[[[password stringValue] copy] autorelease]];
		[request retryWithAuthentication];
    } else {
		[request cancelLoad];
	}
    [loginWindow orderOut: self];
}

- (IBAction)postWithProgress:(id)sender
{	
	//Create a 1mb file
	NSMutableData *data = [NSMutableData dataWithLength:1024*1024];
	NSString *path = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"bigfile"];
	[data writeToFile:path atomically:NO];
	
	[networkQueue cancelAllOperations];
	[progressIndicator setDoubleValue:0];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ignore"]] autorelease];
	[request setDelegate:self];
	[request setUploadProgressDelegate:progressIndicator];
	[request setPostValue:@"test" forKey:@"value1"];
	[request setPostValue:@"test" forKey:@"value2"];
	[request setPostValue:@"test" forKey:@"value3"];

	[request setFile:path forKey:@"file"];

	[networkQueue addOperation:request];
	
}



@end
