//
//  QueueViewController.m
//  Part of the ASIHTTPRequest sample project - see http://allseeing-i.com/ASIHTTPRequest for details
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import "QueueViewController.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "InfoCell.h"
#import "ToggleCell.h"

@implementation QueueViewController


- (IBAction)fetchThreeImages:(id)sender
{
	[imageView1 setImage:nil];
	[imageView2 setImage:nil];
	[imageView3 setImage:nil];
	
	if (!networkQueue) {
		networkQueue = [[ASINetworkQueue alloc] init];	
	}
	failed = NO;
	[networkQueue reset];
	[networkQueue setDownloadProgressDelegate:progressIndicator];
	[networkQueue setRequestDidFinishSelector:@selector(imageFetchComplete:)];
	[networkQueue setRequestDidFailSelector:@selector(imageFetchFailed:)];
	[networkQueue setShowAccurateProgress:[accurateProgress isOn]];
	[networkQueue setDelegate:self];
	
	ASIHTTPRequest *request;
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/images/small-image.jpg"]];
	[request setDownloadDestinationPath:[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"1.png"]];
	[request setDownloadProgressDelegate:imageProgressIndicator1];
	[networkQueue addOperation:request];
	
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/images/medium-image.jpg"]] autorelease];
	[request setDownloadDestinationPath:[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"2.png"]];
	[request setDownloadProgressDelegate:imageProgressIndicator2];
	[networkQueue addOperation:request];
	
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/images/large-image.jpg"]] autorelease];
	[request setDownloadDestinationPath:[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"3.png"]];
	[request setDownloadProgressDelegate:imageProgressIndicator3];
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

- (void)imageFetchFailed:(ASIHTTPRequest *)request
{
	if (!failed) {
		if ([[request error] domain] != NetworkRequestErrorDomain || [[request error] code] != ASIRequestCancelledErrorType) {
			UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Download failed" message:@"Failed to download images" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
			[alertView show];
		}
		failed = YES;
	}
}

- (void)dealloc {
	[networkQueue reset];
	[networkQueue release];
    [super dealloc];
}


/*
 Most of the code below here relates to the table view, and isn't that interesting
 */

- (void)viewDidLoad
{
	[[[self navigationBar] topItem] setTitle:@"Using a Queue"];
}

static NSString *intro = @"Demonstrates a fetching 3 items at once, using an ASINetworkQueue to track progress.\r\nEach request has its own downloadProgressDelegate, and the queue has an additional downloadProgressDelegate to track overall progress.";

- (UIView *)tableView:(UITableView *)theTableView viewForHeaderInSection:(NSInteger)section
{
	if (section == 1) {
		int tablePadding = 40;
		int tableWidth = [tableView frame].size.width;
		if (tableWidth > 480) { // iPad
			tablePadding = 110;
		}
		
		UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0,0,tableWidth-(tablePadding/2),30)] autorelease];
		UIButton *goButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[goButton setTitle:@"Go!" forState:UIControlStateNormal];
		[goButton sizeToFit];
		[goButton setFrame:CGRectMake([view frame].size.width-[goButton frame].size.width+10,7,[goButton frame].size.width,[goButton frame].size.height)];
		
		[goButton addTarget:self action:@selector(fetchThreeImages:) forControlEvents:UIControlEventTouchUpInside];
		[view addSubview:goButton];
		
		progressIndicator = [[[UIProgressView alloc] initWithFrame:CGRectMake((tablePadding/2)-10,20,200,10)] autorelease];
		[view addSubview:progressIndicator];
		
		return view;
	}
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	if ([indexPath section] == 0) {
		cell = [InfoCell cellWithDescription:intro];
	} else if ([indexPath section] == 1) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"ToggleCell"];
		if (!cell) {
			cell = [ToggleCell cell];
		}	
	} else {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MyCell"] autorelease];
	}
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	
	int tablePadding = 40;
	int tableWidth = [tableView frame].size.width;
	if (tableWidth > 480) { // iPad
		tablePadding = 110;
	}
	
	if ([indexPath section] == 1) {
		[[cell textLabel] setText:@"Show Accurate Progress"];
		accurateProgress = [(ToggleCell *)cell toggle];
	} else if ([indexPath section] == 2) {
		
		NSUInteger imageWidth = (tableWidth-tablePadding-20)/3;
		NSUInteger imageHeight = imageWidth*0.66;
		
		imageView1 = [[[UIImageView alloc] initWithFrame:CGRectMake(tablePadding/2,10,imageWidth,imageHeight)] autorelease];
		[imageView1 setBackgroundColor:[UIColor grayColor]];
		[cell addSubview:imageView1];
		
		imageProgressIndicator1 = [[[UIProgressView alloc] initWithFrame:CGRectMake(tablePadding/2,15+imageHeight,imageWidth,20)] autorelease];
		[cell addSubview:imageProgressIndicator1];
		
		UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(tablePadding/2,25+imageHeight,imageWidth,20)] autorelease];
		if (tableWidth > 480) {
			[label setText:@"This image is 15KB in size"];
		} else {
			[label setText:@"Img size: 15KB"];
		}
		[label setTextAlignment:UITextAlignmentCenter];
		[label setFont:[UIFont systemFontOfSize:11]];
		[label setBackgroundColor:[UIColor clearColor]];
		[cell addSubview:label];
		
		imageView2 = [[[UIImageView alloc] initWithFrame:CGRectMake((tablePadding/2)+imageWidth+10,10,imageWidth,imageHeight)] autorelease];
		[imageView2 setBackgroundColor:[UIColor grayColor]];
		[cell addSubview:imageView2];
		
		imageProgressIndicator2 = [[[UIProgressView alloc] initWithFrame:CGRectMake((tablePadding/2)+imageWidth+10,15+imageHeight,imageWidth,20)] autorelease];
		[cell addSubview:imageProgressIndicator2];
		
		label = [[[UILabel alloc] initWithFrame:CGRectMake(tablePadding/2+imageWidth+10,25+imageHeight,imageWidth,20)] autorelease];
		if (tableWidth > 480) {
			[label setText:@"This image is 176KB in size"];
		} else {
			[label setText:@"Img size: 176KB"];
		}
		[label setTextAlignment:UITextAlignmentCenter];
		[label setFont:[UIFont systemFontOfSize:11]];
		[label setBackgroundColor:[UIColor clearColor]];
		[cell addSubview:label];
		
		imageView3 = [[[UIImageView alloc] initWithFrame:CGRectMake((tablePadding/2)+(imageWidth*2)+20,10,imageWidth,imageHeight)] autorelease];
		[imageView3 setBackgroundColor:[UIColor grayColor]];
		[cell addSubview:imageView3];
		
		imageProgressIndicator3 = [[[UIProgressView alloc] initWithFrame:CGRectMake((tablePadding/2)+(imageWidth*2)+20,15+imageHeight,imageWidth,20)] autorelease];
		[cell addSubview:imageProgressIndicator3];
		
		label = [[[UILabel alloc] initWithFrame:CGRectMake(tablePadding/2+(imageWidth*2)+20,25+imageHeight,imageWidth,20)] autorelease];
		if (tableWidth > 480) {
			[label setText:@"This image is 1.4MB in size"];
		} else {
			[label setText:@"Img size: 1.4MB"];
		}
		[label setTextAlignment:UITextAlignmentCenter];
		[label setFont:[UIFont systemFontOfSize:11]];
		[label setBackgroundColor:[UIColor clearColor]];
		[cell addSubview:label];

	}
	return cell;
}

- (NSInteger)tableView:(UITableView *)theTableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (CGFloat)tableView:(UITableView *)theTableView heightForHeaderInSection:(NSInteger)section
{
	if (section == 1) {
		return 50;
	}
	return 34;
}

- (CGFloat)tableView:(UITableView *)theTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath section] == 0) {
		return [InfoCell neededHeightForDescription:intro withTableWidth:[tableView frame].size.width]+20;
	} else if ([indexPath section] == 2) {
		int tablePadding = 40;
		int tableWidth = [tableView frame].size.width;
		if (tableWidth > 480) { // iPad
			tablePadding = 110;
		}
		NSUInteger imageWidth = (tableWidth-tablePadding-20)/3;
		NSUInteger imageHeight = imageWidth*0.66;
		return imageHeight+50;
	} else {
		return 42;
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}

@end
