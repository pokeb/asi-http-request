//
//  ASIFormDataRequestTests.h
//  asi-http-request
//
//  Created by Ben Copsey on 08/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import "ASITestCase.h"

@interface ASIFormDataRequestTests : ASITestCase {
	float progress;
}

- (void)testPostWithFileUpload;
- (void)testEmptyData;
- (void)testSubclass;
@end
