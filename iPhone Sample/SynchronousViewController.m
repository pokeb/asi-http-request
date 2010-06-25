//
//  SynchronousViewController.m
//  Part of the ASIHTTPRequest sample project - see http://allseeing-i.com/ASIHTTPRequest for details
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import "SynchronousViewController.h"
#import "ASIHTTPRequest.h"
#import "DetailCell.h"
#import "InfoCell.h"

@implementation SynchronousViewController


// Runs a request synchronously
- (IBAction)simpleURLFetch:(id)sender
{
	
	NSURL *url = [NSURL URLWithString:[urlField text]];
	// Create a request
	// You don't normally need to retain a synchronous request, but we need to in this case because we'll need it later if we reload the table data
	[self setRequest:[ASIHTTPRequest requestWithURL:url]];
	
	//Customise our user agent, for no real reason
	[request addRequestHeader:@"User-Agent" value:@"ASIHTTPRequest"];
	
	// Start the request
	[request startSynchronous];
	
	// Request has now finished
	[[self tableView] reloadData];

}

/*
Most of the code below here relates to the table view, and isn't that interesting
*/

- (void)viewDidLoad
{
	[[[self navigationBar] topItem] setTitle:@"Synchronous Requests"];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

}

- (void)dealloc
{
	[request cancel];
	[request release];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	[super dealloc];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_3_2
	NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
#else
	NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardBoundsUserInfoKey];
#endif
	CGRect keyboardBounds;
	[keyboardBoundsValue getValue:&keyboardBounds];
	UIEdgeInsets e = UIEdgeInsetsMake(0, 0, keyboardBounds.size.height-42, 0);
	[[self tableView] setScrollIndicatorInsets:e];
	[[self tableView] setContentInset:e];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	UIEdgeInsets e = UIEdgeInsetsMake(0, 0, 0, 0);
	[[self tableView] setScrollIndicatorInsets:e];
	[[self tableView] setContentInset:e];	
}

static NSString *intro = @"Demonstrates fetching a web page synchronously, the HTML source will appear in the box below when the download is complete.  The interface will lock up when you press this button until the operation times out or succeeds. You should avoid using synchronous requests on the main thread, even for the simplest operations.";

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	if ([indexPath section] == 0) {
		cell = [InfoCell cellWithDescription:intro];
	} else if ([indexPath section] == 3) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"HeaderCell"];
		if (!cell) {
			cell = [DetailCell cell];
		}
	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:@"MyCell"];
		if (!cell) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MyCell"] autorelease];
		}	
	}
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	NSString *key;

	int tablePadding = 40;
	int tableWidth = [tableView frame].size.width;
	if (tableWidth > 480) { // iPad
		tablePadding = 110;
	}
	
	switch ([indexPath section]) {
		case 1:
			urlField = [[[UITextField alloc] initWithFrame:CGRectMake(10,12,tableWidth-tablePadding-50,20)] autorelease];
			if ([self request]) {
				[urlField setText:[[[self request] url] absoluteString]];
			} else {
				[urlField setText:@"http://allseeing-i.com"];
			}
			UIButton *goButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
			[goButton setFrame:CGRectMake(tableWidth-tablePadding-38,7,20,20)];
			[goButton setTitle:@"Go!" forState:UIControlStateNormal];
			[goButton sizeToFit];
			[goButton addTarget:self action:@selector(simpleURLFetch:) forControlEvents:UIControlEventTouchUpInside];
			[[cell contentView] addSubview:goButton];
			[[cell contentView] addSubview:urlField];
			break;
		case 2:

			responseField = [[[UITextView alloc] initWithFrame:CGRectMake(5,5,tableWidth-tablePadding,150)] autorelease];
			[responseField setBackgroundColor:[UIColor clearColor]];
			[[cell contentView] addSubview:responseField];
			if (request) {
				if ([request error]) {
					[responseField setText:[[request error] localizedDescription]];
				} else if ([request responseString]) {
					[responseField setText:[request responseString]];
				}
			}
			break;
		case 3:
			key = [[[request responseHeaders] allKeys] objectAtIndex:[indexPath row]];
			[[cell textLabel] setText:key];
			[[cell detailTextLabel] setText:[[request responseHeaders] objectForKey:key]];
			break;
	}
	return cell;
}

- (NSInteger)tableView:(UITableView *)theTableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 3) {
		return [[request responseHeaders] count];
	} else {
		return 1;
	}
}

- (CGFloat)tableView:(UITableView *)theTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath section] == 0) {
		return [InfoCell neededHeightForDescription:intro withTableWidth:[tableView frame].size.width]+20;
	} else if ([indexPath section] == 1) {
		return 48;
	} else if ([indexPath section] == 2) {
		return 160;
	} else {
		return 34;
	}
}

- (NSString *)tableView:(UITableView *)theTableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return nil;
		case 1:
			return @"Enter a URL";
		case 2:
			return @"Response";
		case 3:
			return @"Response Headers";
	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if ([self request]) {
		return 4;
	} else {
		return 2;
	}
}


@synthesize request;

@end
