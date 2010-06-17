//
//  iPhoneSampleAppDelegate.m
//  Part of the ASIHTTPRequest sample project - see http://allseeing-i.com/ASIHTTPRequest for details
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright All-Seeing Interactive 2008. All rights reserved.
//

#import "iPhoneSampleAppDelegate.h"
#import "ASIHTTPRequest.h"
#import "Reachability.h"

@implementation iPhoneSampleAppDelegate

- (void)dealloc
{
    [tabBarController release];
    [window release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    // Add the tab bar controller's current view as a subview of the window
    [window addSubview:[tabBarController view]];
	[[tabBarController view] setFrame:CGRectMake(0,42,320,438)];
	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateStatus:) userInfo:nil repeats:YES];
}

// This is really just so I can test reachability + throttling is working. Please don't use a timer to do this in your own apps!
- (void)updateStatus:(NSTimer *)timer
{
	NSString *connectionType;
	if ([ASIHTTPRequest isNetworkReachableViaWWAN]) {
		connectionType = @"Using WWAN";
	} else {
		connectionType = @"Not using WWAN";
	}
	NSString *throttling = @"Throttling OFF";
	if ([ASIHTTPRequest isBandwidthThrottled]) {
		throttling = @"Throttling ON";
	}
	[statusMessage setText:[NSString stringWithFormat:@"%@ / %luKB per second / %@",connectionType, [ASIHTTPRequest averageBandwidthUsedPerSecond]/1024,throttling]];
}


@synthesize window;
@synthesize tabBarController;

@end

