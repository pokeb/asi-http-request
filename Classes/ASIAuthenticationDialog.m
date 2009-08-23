//
//  ASIAuthenticationDialog.m
//  iPhone
//
//  Created by Ben Copsey on 21/08/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import "ASIAuthenticationDialog.h"
#import "ASIHTTPRequest.h"

ASIAuthenticationDialog *sharedDialog = nil;
NSLock *dialogLock = nil;

@interface ASIAuthenticationDialog ()
- (void)show;
@end

@implementation ASIAuthenticationDialog

+ (void)initialize
{
	if (self == [ASIAuthenticationDialog class]) {
		dialogLock = [[NSLock alloc] init];
	}
}

+ (void)presentProxyAuthenticationDialogForRequest:(ASIHTTPRequest *)request
{
	[dialogLock lock];
	[sharedDialog release];
	sharedDialog = [[self alloc] init];
	[sharedDialog setRequest:request];
	[sharedDialog setType:ASIProxyAuthenticationType];
	[sharedDialog show];
	[dialogLock unlock];	
}

+ (void)presentAuthenticationDialogForRequest:(ASIHTTPRequest *)request
{
	[dialogLock lock];
	[sharedDialog release];
	sharedDialog = [[self alloc] init];
	[sharedDialog setRequest:request];
	[sharedDialog show];
	[dialogLock unlock];
	
}

- (void)show
{
	// Create an action sheet to show the login dialog
	[self setLoginDialog:[[[UIActionSheet alloc] init] autorelease]];
	[[self loginDialog] setActionSheetStyle:UIActionSheetStyleBlackOpaque];
	[[self loginDialog] setDelegate:self];
	
	// We show the login form in a table view, similar to Safari's authentication dialog
	UITableView *table = [[[UITableView alloc] initWithFrame:CGRectMake(0,50,320,480) style:UITableViewStyleGrouped] autorelease];
	[table setDelegate:self];
	[table setDataSource:self];
	[[self loginDialog] addSubview:table];
	[[self loginDialog] showInView:[[[UIApplication sharedApplication] windows] objectAtIndex:0]];
	[[self loginDialog] setFrame:CGRectMake(0,0,320,480)];
	
	UIToolbar *toolbar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0,0,320,80)] autorelease];
	//[toolbar setFrame:CGRectMake(0,20,320,50)];
	NSMutableArray *items = [[[NSMutableArray alloc] init] autorelease];
	UIBarButtonItem *backButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAuthenticationFromDialog:)] autorelease];
	//[backButton setContentEdgeInsets:UIEdgeInsetsMake(0,20,0,0)];
	[items addObject:backButton];
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0,0,170,50)];
	[label setText:[[[self request] url] host]];
	[label setTextColor:[UIColor whiteColor]];
	[label setFont:[UIFont boldSystemFontOfSize:22.0]];
	[label setShadowColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
	[label setShadowOffset:CGSizeMake(0, -1.0)];
	[label setOpaque:NO];
	[label setBackgroundColor:nil];
	[label setTextAlignment:UITextAlignmentCenter];
	
	[toolbar addSubview:label];
	
	UIBarButtonItem *labelButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:nil action:nil] autorelease];

	//[labelButton setCustomView:label];
	//[items addObject:labelButton];
	[items addObject:[[[UIBarButtonItem alloc] initWithTitle:@"Login" style:UIBarButtonItemStyleDone target:self action:@selector(loginWithCredentialsFromDialog:)] autorelease]];
	[toolbar setItems:items];
	[[self loginDialog] addSubview:toolbar];
}

- (void)cancelAuthenticationFromDialog:(id)sender
{
	[[self request] cancelAuthentication];
	[[self loginDialog] dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)loginWithCredentialsFromDialog:(id)sender
{
	[[self request] setUsername:[[[[[[[self loginDialog] subviews] objectAtIndex:0] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] subviews] objectAtIndex:2] text]];
	[[self request] setPassword:[[[[[[[self loginDialog] subviews] objectAtIndex:0] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]] subviews] objectAtIndex:2] text]];
	[[self loginDialog] dismissWithClickedButtonIndex:1 animated:YES];
	[[self request] retryWithAuthentication];	
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	NSString *scheme = ([self type] == ASIStandardAuthenticationType) ? [[self request] authenticationScheme] : [[self request] proxyAuthenticationScheme];
	if ([scheme isEqualToString:(NSString *)kCFHTTPAuthenticationSchemeNTLM]) {
		return 3;
	}
	return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	if (section == [self numberOfSectionsInTableView:tableView]-1) {
		return 30;
	}
	return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if (section == 0) {
		return 30;
	}
	return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == 0) {
		return [[self request] authenticationRealm];
	}
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	UITextField *textField = [[[UITextField alloc] initWithFrame:CGRectMake(20,12,260,25)] autorelease];
	if ([indexPath section] == 0) {
		[textField setPlaceholder:@"User"];
	} else if ([indexPath section] == 1) {
		[textField setPlaceholder:@"Password"];
	} else if ([indexPath section] == 2) {
		[textField setPlaceholder:@"Domain"];
	}	
	[cell addSubview:textField];
	
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (section == [self numberOfSectionsInTableView:tableView]-1) {
		if ([[[[self request] url] scheme] isEqualToString:@"https"]) {
			return @"Password will be sent securely.";
		} else {
			return @"Password will be sent in the clear.";
		}
	}
	return nil;
}

@synthesize request;
@synthesize loginDialog;
@synthesize type;
@end
