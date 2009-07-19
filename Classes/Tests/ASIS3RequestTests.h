//
//  ASIS3RequestTests.h
//  asi-http-request
//
//  Created by Ben Copsey on 12/07/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#if TARGET_OS_IPHONE
#import "GHUnit.h"
#else
#import <GHUnit/GHUnit.h>
#endif

@interface ASIS3RequestTests : GHTestCase {
}

- (void)testAuthenticationHeaderGeneration;
- (void)testREST;
- (void)testFailure;
- (void)testListRequest;
- (void)testSubclasses;
@end
