//
//  GHUnitIPhoneTestMain.m
//  GHUnitIPhone
//
//  Created by Gabriel Handford on 1/25/09.
//  Copyright 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GHUnit.h"
#import "GHTesting.h"

// Default exception handler
void exceptionHandler(NSException *exception) {	
	NSLog(@"%@\n%@", [exception reason], GHUStackTraceFromException(exception));
}

int main(int argc, char *argv[]) {
	
	/*!
	 For debugging:
	 Go into the "Get Info" contextual menu of your (test) executable (inside the "Executables" group in the left panel of XCode). 
	 Then go in the "Arguments" tab. You can add the following environment variables:
	 
																			Default:   Set to:
	 NSDebugEnabled                        NO       "YES"
	 NSZombieEnabled                       NO       "YES"
	 NSDeallocateZombies                   NO       "YES"
	 NSHangOnUncaughtException             NO       "YES"
	 
	 NSEnableAutoreleasePool              YES       "NO"
	 NSAutoreleaseFreedObjectCheckEnabled  NO       "YES"
	 NSAutoreleaseHighWaterMark             0       non-negative integer
	 NSAutoreleaseHighWaterResolution       0       non-negative integer
	
	 For info on these varaiables see NSDebug.h; http://theshadow.uw.hu/iPhoneSDKdoc/Foundation.framework/NSDebug.h.html
	 
	 For malloc debugging see: http://developer.apple.com/mac/library/documentation/Performance/Conceptual/ManagingMemory/Articles/MallocDebug.html
	 */
	
	NSSetUncaughtExceptionHandler(&exceptionHandler);
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// Register any special test case classes
	//[[GHTesting sharedInstance] registerClassName:@"GHSpecialTestCase"];	
	
	int retVal = 0;
	// If GHUNIT_CLI is set we are using the command line interface and run the tests
	// Otherwise load the GUI app
	if (getenv("GHUNIT_CLI")) {
		retVal = [GHTestRunner run];
	} else {
		retVal = UIApplicationMain(argc, argv, nil, @"GHUnitIPhoneAppDelegate");
	}
	[pool release];
	return retVal;
}
