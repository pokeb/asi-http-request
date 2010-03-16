//
//  ASIS3ServiceRequest.m
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 16/03/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//

#import "ASIS3ServiceRequest.h"


@implementation ASIS3ServiceRequest

+ (id)serviceRequest
{
	return [[[self alloc] initWithURL:[NSURL URLWithString:@"http://s3.amazonaws.com"]] autorelease];
}


@end
