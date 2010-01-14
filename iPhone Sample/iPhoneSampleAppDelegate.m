//
//  iPhoneSampleAppDelegate.m
//  asi-http-request
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright All-Seeing Interactive 2008. All rights reserved.
//

#import "iPhoneSampleAppDelegate.h"
#import "ASIHTTPRequest.h"
#import "Reachability.h"

@implementation iPhoneSampleAppDelegate

@synthesize window;
@synthesize tabBarController;



- (void)dealloc {
    [tabBarController release];
    [window release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    // Add the tab bar controller's current view as a subview of the window
    [window addSubview:[tabBarController view]];
	[[tabBarController view] setFrame:CGRectMake(0,47,320,433)];
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


@end

