//
//  ASICloudFilesContainer.m
//  iPhone
//
//  Created by Michael Mayo on 1/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ASICloudFilesContainer.h"


@implementation ASICloudFilesContainer

@synthesize name, count, bytes;

+ (id)container {
	ASICloudFilesContainer *container = [[[self alloc] init] autorelease];
	return container;
}

-(void) dealloc {
	[name release];
	[super dealloc];
}

@end
