//
//  SampleViewController.m
//  Part of the ASIHTTPRequest sample project - see http://allseeing-i.com/ASIHTTPRequest for details
//
//  Created by Ben Copsey on 17/06/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//

#import "SampleViewController.h"


@implementation SampleViewController

- (void)showNavigationButton:(UIBarButtonItem *)button
{
    [[[self navigationBar] topItem] setLeftBarButtonItem:button animated:NO];	
}

- (void)hideNavigationButton:(UIBarButtonItem *)button
{
    [[[self navigationBar] topItem] setLeftBarButtonItem:nil animated:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	return YES;
}

- (NSIndexPath *)tableView:(UITableView *)theTableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	return nil;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[[self tableView] reloadData];
}


- (void)viewDidUnload {
    [super viewDidUnload];
    [self setNavigationBar:nil];
	[self setTableView:nil];
}


- (void)dealloc {
	[navigationBar release];
	[tableView release];
    [super dealloc];
}

@synthesize navigationBar;
@synthesize tableView;
@end
