//
//  iPhoneSampleAppDelegate.m
//  asi-http-request
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright All-Seeing Interactive 2008. All rights reserved.
//

#import "iPhoneSampleAppDelegate.h"
#import "ASIHTTPRequest.h"

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
    [window addSubview:tabBarController.view];
}


@end

