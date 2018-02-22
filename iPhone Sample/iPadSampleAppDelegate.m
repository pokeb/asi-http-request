//
//  iPadSampleAppDelegate.m
//  Part of the ASIHTTPRequest sample project - see http://allseeing-i.com/ASIHTTPRequest for details
//
//  Created by Ben Copsey on 15/06/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//

#import "iPadSampleAppDelegate.h"

@implementation iPadSampleAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    window.rootViewController = splitViewController;
	[window makeKeyAndVisible];
}

@synthesize window;
@synthesize splitViewController;
@end
