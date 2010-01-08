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
#import "ASICloudFilesRequest.h"
#import "ASICloudFilesContainerRequest.h"
#import "ASICloudFilesObjectRequest.h"
#import "ASICloudFilesCDNRequest.h"
#import "ASICloudFilesContainer.h"
#import "ASICloudFilesObject.h"

@implementation iPhoneSampleAppDelegate

@synthesize window;
@synthesize tabBarController;



- (void)dealloc {
    [tabBarController release];
    [window release];
    [super dealloc];
}

// TODO: remove
-(NSDate *)dateFromString:(NSString *)dateString {
	NSDateFormatter *format = [[NSDateFormatter alloc] init];
	// example: 2009-11-04T19:46:20.192723
	//[format setDateFormat:@"EEE, d MMM yyyy H:mm:ss zzz"];
	//[format setDateFormat:@"yyyy-MM-ddTH:mm:ss"];
	[format setDateFormat:@"yyyy-MM-dd'T'H:mm:ss"];
	NSDate *date = [format dateFromString:dateString];
	[format release];
	
	return date;
}



- (void)applicationDidFinishLaunching:(UIApplication *)application {

    NSLog(@"DATE TESTS!!!");
	
	NSDate *date = [self dateFromString:@"2009-11-04T19:46:20.192723"];
	NSLog(@"date: %@", [date description]);
	
	
	NSLog(@"time to test Cloud Files!");
	
	[ASICloudFilesRequest setUsername:@"greenisus"];
	[ASICloudFilesRequest setApiKey:@"1c331a7a4a6eb58ca6072afe81e812d0"];
	[ASICloudFilesRequest authenticate];
	
	NSLog(@"Storage URL: %@", [ASICloudFilesRequest storageURL]);

	NSArray *containers = nil;
	containers; // to suppress warning when test are commented out
	
	/*
	NSLog(@"account info:");
	
	ASICloudFilesContainerRequest *accountInfoRequest = [ASICloudFilesContainerRequest accountInfoRequest];
	[accountInfoRequest start];

//	NSLog(@"Response status code: %i", [accountInfoRequest responseStatusCode]);
//	NSLog(@"Response status message: %@", [accountInfoRequest responseStatusMessage]);
	NSLog(@"Container count: %i", [accountInfoRequest containerCount]);
	NSLog(@"Bytes used: %i", [accountInfoRequest bytesUsed]);
	
//	NSLog(@"All headers:");
//	NSDictionary *headers = [accountInfoRequest responseHeaders];
//	NSArray *keys = [headers allKeys];
//	for (int i = 0; i < [keys count]; i++) {
//		NSString *key = [keys objectAtIndex:i];
//		NSLog(@"%@: %@", key, [headers objectForKey:key]);
//	}
	
	ASICloudFilesContainerRequest *containerListRequest = [ASICloudFilesContainerRequest listRequest];
	[containerListRequest start];
	
	containers = [containerListRequest containers];
	NSLog(@"Containers list count: %i", [containers count]);
	
	for (int i = 0; i < [containers count]; i++) {
		ASICloudFilesContainer *container = [containers objectAtIndex:i];
		NSLog(@"%@ - %i objects, %i bytes", container.name, container.count, container.bytes);
	}
	
	ASICloudFilesContainerRequest *limitContainerListRequest = [ASICloudFilesContainerRequest listRequestWithLimit:2];
	[limitContainerListRequest start];
	
	containers = [limitContainerListRequest containers];
	NSLog(@"Limit 2 Containers list count: %i", [containers count]);
	
	for (int i = 0; i < [containers count]; i++) {
		ASICloudFilesContainer *container = [containers objectAtIndex:i];
		NSLog(@"%@ - %i objects, %i bytes", container.name, container.count, container.bytes);
	}

	ASICloudFilesContainerRequest *markerContainerListRequest = [ASICloudFilesContainerRequest listRequestWithMarker:@"personal"];
	[markerContainerListRequest start];
	
	containers = [markerContainerListRequest containers];
	NSLog(@"Marker personal Containers list count: %i", [containers count]);
	
	for (int i = 0; i < [containers count]; i++) {
		ASICloudFilesContainer *container = [containers objectAtIndex:i];
		NSLog(@"%@ - %i objects, %i bytes", container.name, container.count, container.bytes);
	}

	ASICloudFilesContainerRequest *limitMarkerContainerListRequest = [ASICloudFilesContainerRequest listRequestWithLimit:3 marker:@"cf_service"];
	[limitMarkerContainerListRequest start];
	
	containers = [limitMarkerContainerListRequest containers];
	NSLog(@"Limit 3 Marker cf_service Containers list count: %i", [containers count]);
	
	for (int i = 0; i < [containers count]; i++) {
		ASICloudFilesContainer *container = [containers objectAtIndex:i];
		NSLog(@"%@ - %i objects, %i bytes", container.name, container.count, container.bytes);
	}
	
	ASICloudFilesContainerRequest *createContainerRequest = [ASICloudFilesContainerRequest createContainerRequest:@"ASICloudFiles"];
	[createContainerRequest start];
	NSLog(@"Create response status code: %i", [createContainerRequest responseStatusCode]);
	NSLog(@"Create response status message: %@", [createContainerRequest responseStatusMessage]);

	ASICloudFilesContainerRequest *deleteContainerRequest = [ASICloudFilesContainerRequest deleteContainerRequest:@"ASICloudFiles"];
	[deleteContainerRequest start];
	NSLog(@"Delete response status code: %i", [deleteContainerRequest responseStatusCode]);
	NSLog(@"Delete response status message: %@", [deleteContainerRequest responseStatusMessage]);
	*/
	
	// OBJECT LIST TEST
	/*
	ASICloudFilesObjectRequest *objectListRequest = [ASICloudFilesObjectRequest listRequestWithContainer:@"cf_service"];
	[objectListRequest start];
	
	containers = [objectListRequest objects];
	NSLog(@"cf_service object list count: %i", [containers count]);
	for (int i = 0; i < [containers count]; i++) {
		ASICloudFilesObject *object = [containers objectAtIndex:i];
		NSLog(@"%@ - %@ - %i bytes, %@, %@", object.name, object.hash, object.bytes, object.contentType, [object.lastModified description]);
	}
	*/
	
	
	
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

