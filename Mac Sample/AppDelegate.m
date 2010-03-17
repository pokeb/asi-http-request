//
//  AppDelegate.m
//
//  Created by Ben Copsey on 09/07/2008.
//  Copyright 2008 All-Seeing Interactive Ltd. All rights reserved.
//

#import "AppDelegate.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"

@implementation AppDelegate

- (id)init
{
	[super init];
	networkQueue = [[ASINetworkQueue alloc] init];
	NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateBandwidthUsageIndicator) userInfo:nil repeats:YES];
	timer = nil;
	return self;
}

- (void)dealloc
{
	[networkQueue release];
	[super dealloc];
}


- (IBAction)simpleURLFetch:(id)sender
{
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/the_great_american_novel_%28abridged%29.txt"]] autorelease];
	
	//Customise our user agent, for no real reason
	[request addRequestHeader:@"User-Agent" value:@"ASIHTTPRequest"];
	[request setDelegate:self];
	[request startSynchronous];
	if ([request error]) {
		[htmlSource setString:[[request error] localizedDescription]];
	} else if ([request responseString]) {
		[htmlSource setString:[request responseString]];
	}
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	[htmlSource setString:[request responseString]];
}


- (IBAction)URLFetchWithProgress:(id)sender
{
	[startButton setTitle:@"Stop"];
	[startButton setAction:@selector(stopURLFetchWithProgress:)];
	
	NSString *tempFile = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"MemexTrails_1.0b1.zip.download"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:tempFile]) {
		[[NSFileManager defaultManager] removeItemAtPath:tempFile error:nil];
	}
	
	[self resumeURLFetchWithProgress:self];
}


- (IBAction)stopURLFetchWithProgress:(id)sender
{
	[startButton setTitle:@"Start"];
	[startButton setAction:@selector(URLFetchWithProgress:)];
	[[self bigFetchRequest] cancel];
	[self setBigFetchRequest:nil];
	[resumeButton setEnabled:YES];
}

- (IBAction)resumeURLFetchWithProgress:(id)sender
{
	[resumeButton setEnabled:NO];
	[startButton setTitle:@"Stop"];
	[startButton setAction:@selector(stopURLFetchWithProgress:)];
	
	// Stop any other requests
	[networkQueue cancelAllOperations];
	
	[self setBigFetchRequest:[[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://trails-network.net/Downloads/MemexTrails_1.0b1.zip"]] autorelease]];
	[[self bigFetchRequest] setDownloadDestinationPath:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"MemexTrails_1.0b1.zip"]];
	[[self bigFetchRequest] setTemporaryFileDownloadPath:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"MemexTrails_1.0b1.zip.download"]];
	[[self bigFetchRequest] setAllowResumeForFileDownloads:YES];
	[[self bigFetchRequest] setDidFinishSelector:@selector(URLFetchWithProgressComplete:)];
	[[self bigFetchRequest] setDownloadProgressDelegate:progressIndicator];
	[[self bigFetchRequest] startAsynchronous];
}

- (void)URLFetchWithProgressComplete:(ASIHTTPRequest *)request
{
	if ([request error]) {
		[fileLocation setStringValue:[NSString stringWithFormat:@"An error occurred: %@",[[[request error] userInfo] objectForKey:@"Title"]]];
	} else {
		[fileLocation setStringValue:[NSString stringWithFormat:@"File downloaded to %@",[request downloadDestinationPath]]];
	}
	[startButton setTitle:@"Start"];
	[startButton setAction:@selector(URLFetchWithProgress:)];
}

- (IBAction)fetchThreeImages:(id)sender
{
	[imageView1 setImage:nil];
	[imageView2 setImage:nil];
	[imageView3 setImage:nil];
	
	[networkQueue cancelAllOperations];
	[networkQueue setRequestDidFinishSelector:NULL];
	[networkQueue setDownloadProgressDelegate:progressIndicator];
	[networkQueue setDelegate:self];
	[networkQueue setShowAccurateProgress:([showAccurateProgress state] == NSOnState)];
	
	ASIHTTPRequest *request;
	
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/images/small-image.jpg"]] autorelease];
	[request setDownloadDestinationPath:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"1.png"]];
	[request setDownloadProgressDelegate:imageProgress1];
	[request setDidFinishSelector:@selector(imageFetch1Complete:)];
	[request setDelegate:self];
	[networkQueue addOperation:request];
	
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/images/medium-image.jpg"]] autorelease];
	[request setDownloadDestinationPath:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"2.png"]];
	[request setDownloadProgressDelegate:imageProgress2];
	[request setDidFinishSelector:@selector(imageFetch2Complete:)];
	[request setDelegate:self];
	[networkQueue addOperation:request];
	
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/images/large-image.jpg"]] autorelease];
	[request setDownloadDestinationPath:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"3.png"]];
	[request setDownloadProgressDelegate:imageProgress3];
	[request setDidFinishSelector:@selector(imageFetch3Complete:)];
	[request setDelegate:self];
	[networkQueue addOperation:request];
	
	
	[networkQueue go];
}

- (void)updateBandwidthUsageIndicator
{
	[bandwidthUsed setStringValue:[NSString stringWithFormat:@"%luKB / second",[ASIHTTPRequest averageBandwidthUsedPerSecond]/1024]];
}

- (IBAction)throttleBandwidth:(id)sender
{
	if ([(NSButton *)sender state] == NSOnState) {
		[ASIHTTPRequest setMaxBandwidthPerSecond:ASIWWANBandwidthThrottleAmount];
	} else {
		[ASIHTTPRequest setMaxBandwidthPerSecond:0];
	}
}


- (void)imageFetch1Complete:(ASIHTTPRequest *)request
{
	NSImage *img = [[[NSImage alloc] initWithContentsOfFile:[request downloadDestinationPath]] autorelease];
	if (img) {
		[imageView1 setImage:img];
	}
}

- (void)imageFetch2Complete:(ASIHTTPRequest *)request
{
	NSImage *img = [[[NSImage alloc] initWithContentsOfFile:[request downloadDestinationPath]] autorelease];
	if (img) {
		[imageView2 setImage:img];
	}
}


- (void)imageFetch3Complete:(ASIHTTPRequest *)request
{
	NSImage *img = [[[NSImage alloc] initWithContentsOfFile:[request downloadDestinationPath]] autorelease];
	if (img) {
		[imageView3 setImage:img];
	}
}


- (IBAction)fetchTopSecretInformation:(id)sender
{
	[networkQueue cancelAllOperations];
	
	[progressIndicator setDoubleValue:0];
	
	ASIHTTPRequest *request;
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/top_secret/"]] autorelease];
	[request setDidFinishSelector:@selector(topSecretFetchComplete:)];
	[request setDelegate:self];
	[request setUseKeychainPersistence:[keychainCheckbox state]];
	[request startAsynchronous];

}

- (IBAction)topSecretFetchComplete:(ASIHTTPRequest *)request
{
	if (![request error]) {
		[topSecretInfo setStringValue:[request responseString]];
		[topSecretInfo setFont:[NSFont boldSystemFontOfSize:13]];
	}
}

- (void)authenticationNeededForRequest:(ASIHTTPRequest *)request
{
	[realm setStringValue:[request authenticationRealm]];
	[host setStringValue:[[request url] host]];

	[NSApp beginSheet: loginWindow
		modalForWindow: window
		modalDelegate: self
		didEndSelector: @selector(authSheetDidEnd:returnCode:contextInfo:)
		contextInfo: request];
}

- (void)proxyAuthenticationNeededForRequest:(ASIHTTPRequest *)request
{
	[realm setStringValue:[request proxyAuthenticationRealm]];
	[host setStringValue:[request proxyHost]];
	
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
		if ([request authenticationNeeded] == ASIProxyAuthenticationNeeded) {
			[request setProxyUsername:[[[username stringValue] copy] autorelease]];
			[request setProxyPassword:[[[password stringValue] copy] autorelease]];			
		} else {
			[request setUsername:[[[username stringValue] copy] autorelease]];
			[request setPassword:[[[password stringValue] copy] autorelease]];
		}
		[request retryUsingSuppliedCredentials];
    } else {
		[request cancelAuthentication];
	}
    [loginWindow orderOut: self];
}

- (IBAction)postWithProgress:(id)sender
{	
	//Create a 2MB file
	NSMutableData *data = [NSMutableData dataWithLength:1024*2048];
	NSString *path = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"bigfile"];
	[data writeToFile:path atomically:NO];
	
	
	[networkQueue cancelAllOperations];
	[networkQueue setShowAccurateProgress:YES];
	[networkQueue setUploadProgressDelegate:progressIndicator];
	[networkQueue setDelegate:self];
	
	ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ignore"]] autorelease];
	[request setPostValue:@"test" forKey:@"value1"];
	[request setPostValue:@"test" forKey:@"value2"];
	[request setPostValue:@"test" forKey:@"value3"];
	[request setFile:path forKey:@"file"];
	

	[networkQueue addOperation:request];
	[networkQueue go];
}


@synthesize bigFetchRequest;
@end
