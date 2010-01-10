//
//  ASICloudFilesRequest.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Michael Mayo on 22/12/09.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//
// A (basic) class for accessing data stored on Rackspace's Cloud Files Service
// http://www.rackspacecloud.com/cloud_hosting_products/files
// 
// Cloud Files Developer Guide:
// http://docs.rackspacecloud.com/servers/api/cs-devguide-latest.pdf

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"


@interface ASICloudFilesRequest : ASIHTTPRequest {
}

+ (NSString *)storageURL;
+ (NSString *)cdnManagementURL;
+ (NSString *)authToken;

#pragma mark Rackspace Cloud Authentication

+ (void)authenticate;

+ (NSString *)username;
+ (void)setUsername:(NSString *)username;
+ (NSString *)apiKey;
+ (void)setApiKey:(NSString *)apiKey;

-(NSDate *)dateFromString:(NSString *)dateString;

#pragma mark Constructors

+ (id)authenticationRequest;
+ (id)storageRequest;
+ (id)cdnRequest;

@end
