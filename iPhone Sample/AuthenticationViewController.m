//
//  AuthenticationViewController.m
//  iPhone
//
//  Created by Ben Copsey on 01/08/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import "AuthenticationViewController.h"
#import "ASIHTTPRequest.h"

@implementation AuthenticationViewController

- (IBAction)fetchTopSecretInformation:(id)sender
{
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/top_secret/"]];
	[request setUseKeychainPersistence:[useKeychain isOn]];
	[request setDelegate:self];
	[request setShouldPresentAuthenticationDialog:[useBuiltInDialog isOn]];
	[request setDidFinishSelector:@selector(topSecretFetchComplete:)];
	[request setDidFailSelector:@selector(topSecretFetchFailed:)];
	[request startAsynchronous];
	
}

- (IBAction)topSecretFetchFailed:(ASIHTTPRequest *)request
{
	[topSecretInfo setText:[[request error] localizedDescription]];
	[topSecretInfo setFont:[UIFont boldSystemFontOfSize:12]];
}

- (IBAction)topSecretFetchComplete:(ASIHTTPRequest *)request
{
	[topSecretInfo setText:[request responseString]];
	[topSecretInfo setFont:[UIFont boldSystemFontOfSize:12]];
}

- (void)authenticationNeededForRequest:(ASIHTTPRequest *)request
{
	// Why oh why is there no contextInfo for alertView like on Mac OS ?!
	[self setRequestRequiringProxyAuthentication:nil];
	[self setRequestRequiringAuthentication:request];
	
	
	UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Please Login" message:[request authenticationRealm] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK",nil] autorelease];
	// These are undocumented, use at your own risk!
	// A better general approach would be to subclass UIAlertView, or just use ASIHTTPRequest's built-in dialog
	[alertView addTextFieldWithValue:@"" label:@"Username"];
	[alertView addTextFieldWithValue:@"" label:@"Password"];
	[alertView show];

}

- (void)proxyAuthenticationNeededForRequest:(ASIHTTPRequest *)request
{
	[self setRequestRequiringAuthentication:nil];
	[self setRequestRequiringProxyAuthentication:request];
	UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Please Login to proxy" message:[request authenticationRealm] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK",nil] autorelease];
	[alertView addTextFieldWithValue:@"" label:@"Username"];
	[alertView addTextFieldWithValue:@"" label:@"Password"];
	[alertView show];
}



- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1) {
		if ([self requestRequiringAuthentication]) {
			[[self requestRequiringAuthentication] setUsername:[[alertView textFieldAtIndex:0] text]];
			[[self requestRequiringAuthentication] setPassword:[[alertView textFieldAtIndex:1] text]];
			[[self requestRequiringAuthentication] retryUsingSuppliedCredentials];
		} else if ([self requestRequiringProxyAuthentication]) {
			[[self requestRequiringProxyAuthentication] setProxyUsername:[[alertView textFieldAtIndex:0] text]];
			[[self requestRequiringProxyAuthentication] setProxyPassword:[[alertView textFieldAtIndex:1] text]];
			[[self requestRequiringProxyAuthentication] retryUsingSuppliedCredentials];
		}
	} else {
		[[self requestRequiringAuthentication] cancelAuthentication];
	}
}

- (BOOL)respondsToSelector:(SEL)selector
{
	if (selector == @selector(authenticationNeededForRequest:) || selector == @selector(proxyAuthenticationNeededForRequest:)) {
		if ([useBuiltInDialog isOn]) {
			return NO;
		}
		return YES;
	}
	return [super respondsToSelector:selector];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)dealloc
{
	[requestRequiringAuthentication release];
	[requestRequiringProxyAuthentication release];
    [super dealloc];
}

@synthesize requestRequiringAuthentication;
@synthesize requestRequiringProxyAuthentication;
@end
