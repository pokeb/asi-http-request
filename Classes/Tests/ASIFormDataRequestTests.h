//
//  ASIFormDataRequestTests.h
//  asi-http-request
//
//  Created by Ben Copsey on 08/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#if TARGET_OS_IPHONE
	#import "GHUnit.h"
#else
	#import <GHUnit/GHUnit.h>
#endif

@interface ASIFormDataRequestTests : GHTestCase {
	float progress;
}

- (void)testPostWithFileUpload;
- (void)testEmptyData;
- (void)testSubclass;
@end
