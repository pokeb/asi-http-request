//
//  ASIS3RequestTests.h
//  asi-http-request
//
//  Created by Ben Copsey on 12/07/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import "ASITestCase.h"

@interface ASIS3RequestTests : ASITestCase {
}

- (void)testAuthenticationHeaderGeneration;
- (void)testREST;
- (void)testFailure;
- (void)testListRequest;
- (void)testSubclasses;
@end
