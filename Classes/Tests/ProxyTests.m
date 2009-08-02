//
//  ProxyTests.m
//  Mac
//
//  Created by Ben Copsey on 02/08/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import "ProxyTests.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"

// Fill in these to run the proxy tests
static NSString *proxyHost = @"";
static int proxyPort = 0;
static NSString *proxyUsername = @"";
static NSString *proxyPassword = @"";

@implementation ProxyTests

- (void)testProxy
{
	BOOL success = (![proxyHost isEqualToString:@""] && proxyPort > 0);
	GHAssertTrue(success,@"You need to supply the details of your proxy to run the proxy autodetect test");	
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com"]];
	[request setProxyHost:proxyHost];
	[request setProxyPort:proxyPort];
	[request start];
	
	// Check data is as expected
	NSRange notFound = NSMakeRange(NSNotFound, 0);
	success = !NSEqualRanges([[request responseString] rangeOfString:@"All-Seeing Interactive"],notFound);
	GHAssertTrue(success,@"Failed to download the correct data, navigating the proxy");
}

- (void)testProxyAutodetect
{
	BOOL success = (![proxyHost isEqualToString:@""] && proxyPort > 0);
	GHAssertTrue(success,@"You need to supply the details of your proxy to run the proxy autodetect test");	
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com"]];
	[request start];
	
	success = ([request proxyHost] && [request proxyPort]);
	GHAssertTrue(success,@"Failed to detect the proxy");		
}


- (void)testProxyWithSuppliedAuthenticationCredentials
{
	BOOL success = (![proxyHost isEqualToString:@""] && proxyPort > 0 && ![proxyUsername isEqualToString:@""] && ![proxyPassword isEqualToString:@""]);
	GHAssertTrue(success,@"You need to supply the details of your authenticating proxy to run the proxy authentication test");	
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com"]];
	[request setProxyHost:proxyHost];
	[request setProxyPort:proxyPort];
	[request setProxyUsername:proxyUsername];
	[request setProxyPassword:proxyPassword];
	[request start];
	
	// Check data is as expected
	NSRange notFound = NSMakeRange(NSNotFound, 0);
	success = !NSEqualRanges([[request responseString] rangeOfString:@"All-Seeing Interactive"],notFound);
	GHAssertTrue(success,@"Failed to download the correct data, navigating the proxy");
}

- (void)testProxyWithDelegateSupplyingCredentials
{
	[self setComplete:NO];
	BOOL success = (![proxyHost isEqualToString:@""] && proxyPort > 0 && ![proxyUsername isEqualToString:@""] && ![proxyPassword isEqualToString:@""]);
	GHAssertTrue(success,@"You need to supply the details of your authenticating proxy to run the proxy authentication test");	
	
	[[self queue] cancelAllOperations];
	[self setQueue:[ASINetworkQueue queue]];
	[[self queue] setDelegate:self];
	[[self queue] setRequestDidFinishSelector:@selector(requestFinished:)];
	[[self queue] setRequestDidFailSelector:@selector(requestFailed:)];
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com"]];
	[[self queue] addOperation:request];
	
	[queue go];
	
	while (![self complete]) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	}
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	[self setComplete:YES];
	// Check data is as expected
	NSRange notFound = NSMakeRange(NSNotFound, 0);
	BOOL success = !NSEqualRanges([[request responseString] rangeOfString:@"All-Seeing Interactive"],notFound);
	GHAssertTrue(success,@"Failed to download the correct data, navigating the proxy");	
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	[self setComplete:YES];
	GHAssertTrue(0,@"Request failed when it shouldn't have done so");	
}

- (void)proxyAuthorizationNeededForRequest:(ASIHTTPRequest *)request
{
	[request setProxyUsername:proxyUsername];
	[request setProxyPassword:proxyPassword];
	[request retryWithAuthentication];
}


- (void)testDoubleAuthentication
{
	[self setComplete:NO];
	BOOL success = (![proxyHost isEqualToString:@""] && proxyPort > 0 && ![proxyUsername isEqualToString:@""] && ![proxyPassword isEqualToString:@""]);
	GHAssertTrue(success,@"You need to supply the details of your authenticating proxy to run the proxy authentication test");	
	
	[[self queue] cancelAllOperations];
	[self setQueue:[ASINetworkQueue queue]];
	[[self queue] setDelegate:self];
	[[self queue] setRequestDidFinishSelector:@selector(requestDone:)];
	[[self queue] setRequestDidFailSelector:@selector(requestFailed:)];
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/basic-authentication"]];
	[[self queue] addOperation:request];
	
	[queue go];
	
	while (![self complete]) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	}
}

- (void)requestDone:(ASIHTTPRequest *)request
{
	[self setComplete:YES];
}

- (void)authorizationNeededForRequest:(ASIHTTPRequest *)request
{
	[request setUsername:@"secret_username"];
	[request setPassword:@"secret_password"];
	[request retryWithAuthentication];
}


@synthesize queue;
@synthesize complete;
@end
