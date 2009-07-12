//
//  ASIS3RequestTests.h
//  Mac
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

@end
