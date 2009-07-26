//
//  GHUnitIPhoneTestMain.m
//  GHUnitIPhone
//
//  Created by Gabriel Handford on 1/25/09.
//  Copyright 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GHUnit.h"

extern BOOL NSDebugEnabled;
extern BOOL NSZombieEnabled;
extern BOOL NSDeallocateZombies;
extern BOOL NSHangOnUncaughtException;

int main(int argc, char *argv[]) {
	
	NSDebugEnabled = YES;
	NSZombieEnabled = YES;
	NSDeallocateZombies = NO;
	NSHangOnUncaughtException = YES;
	
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
