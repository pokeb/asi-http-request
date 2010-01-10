//
//  ASICloudFilesRequestTests.h
//  iPhone
//
//  Created by Michael Mayo on 1/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ASITestCase.h"

@class ASINetworkQueue;

@interface ASICloudFilesRequestTests : ASITestCase {
	ASINetworkQueue *networkQueue;
	float progress;
}

@property (retain,nonatomic) ASINetworkQueue *networkQueue;

// ASICloudFilesRequest
- (void)testAuthentication;
- (void)testDateParser;

// ASICloudFilesContainerRequest
- (void)testAccountInfo;
- (void)testContainerList; // TODO: with marker and limit permutations as well
- (void)testContainerCreate;
- (void)testContainerDelete;

// ASICloudFilesObjectRequest
- (void)testContainerInfo;
- (void)testObjectInfo;
- (void)testObjectList; // TODO: all permutations
- (void)testGetObject;
- (void)testPutObject; // TODO: all permutations?
- (void)testPostObject; // TODO: all permutations?
- (void)testDeleteObject;

// ASICloudFilesCDNRequest
// ???

@end
