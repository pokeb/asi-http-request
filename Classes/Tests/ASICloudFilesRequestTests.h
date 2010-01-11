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

@end
