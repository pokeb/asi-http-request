//
//  ASIReachability.h
//
//  Created by Christoph Ludwig on 2009-12-01.
//  Copyright 2009 Pensive S.A.. All rights reserved.
//
//  This file may be distributed as part of 
//  Ben Copsey's ASIHTTPRequest library subject to the license of
//  ASIHTTPRequest.
//

#if TARGET_OS_IPHONE

#import <Foundation/Foundation.h>

@class Reachability;

@interface ASIReachability : NSObject {
@private
    Reachability* reachability;
}

// constructs and returns the singleton instance of ASIReachability
+ (ASIReachability*) sharedReachability;

// returns YES iff internet access currently uses the carrier's WWAN.
- (BOOL)reachableViaWWAN;

@end

#endif
