//
//  ASIS3Bucket.m
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 16/03/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//

#import "ASIS3Bucket.h"


@implementation ASIS3Bucket

+ (id)bucketWithOwnerID:(NSString *)ownerID ownerName:(NSString *)ownerName
{
	ASIS3Bucket *bucket = [[[self alloc] init] autorelease];
	[bucket setOwnerID:ownerID];
	[bucket setOwnerName:ownerName];
	return bucket;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"Name: %@ creationDate: %@ ownerID: %@ ownerName: %@",[self name],[self creationDate],[self ownerID],[self ownerName]];
}


@synthesize name;
@synthesize creationDate;
@synthesize ownerID;
@synthesize ownerName;
@end
