//
//  ASICloudFilesObject.m
//  iPhone
//
//  Created by Michael Mayo on 1/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ASICloudFilesObject.h"


@implementation ASICloudFilesObject

@synthesize name, hash, bytes, contentType, lastModified, data, metadata;

+ (id)object {
	ASICloudFilesObject *object = [[[self alloc] init] autorelease];
	return object;
}

-(void)dealloc {
	[name release];
	[hash release];
	[contentType release];
	[lastModified release];
	[data release];
	[metadata release];
	[super dealloc];
}

@end
