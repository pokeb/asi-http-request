//
//  ASIFormDataRequestTests.h
//  asi-http-request
//
//  Created by Ben Copsey on 08/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface ASIFormDataRequestTests : SenTestCase {
	float progress;
}

- (void)testPostWithFileUpload;

@end
