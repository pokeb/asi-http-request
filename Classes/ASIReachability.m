//
//  ASIReachability.m
//
//  Created by Christoph Ludwig on 2009-12-01.
//  Copyright 2009 Pensive S.A.. All rights reserved.
//
//  This file may be distributed as part of 
//  Ben Copsey's ASIHTTPRequest library subject to the license of
//  ASIHTTPRequest.
//

#if TARGET_OS_IPHONE

#import "ASIReachability.h"
#import "Reachability.h"

#pragma mark -
#pragma mark C data and type definitions
#pragma mark -

static ASIReachability* reachabilitySingleton = nil;
static BOOL reachabilityIs15 = FALSE;

// Apple changed the NetworkStatus enum :-(
typedef enum {
    NotReachable15 = 0,
    ReachableViaCarrierDataNetwork15,
    ReachableViaWiFiNetwork15
} NetworkStatus15;

typedef enum {
	NotReachable20 = 0,
	ReachableViaWiFi20,
	ReachableViaWWAN20
} NetworkStatus20;


#pragma mark -
@protocol Reachability15
#pragma mark -

- (void)setNetworkStatusNotificationsEnabled:(BOOL)value;
- (NetworkStatus15)internetConnectionStatus;

@end

#pragma mark -
@protocol Reachability20
#pragma mark -

- (BOOL)startNotifer;
- (void)stopNotifer;
- (NetworkStatus20)currentReachabilityStatus;

@end 

#pragma mark -
@implementation ASIReachability
#pragma mark -

+ (void)initialize {
    reachabilityIs15 = [[Reachability class] respondsToSelector:@selector(sharedReachability)];
}

+ (ASIReachability*) sharedReachability {
    @synchronized([ASIReachability class]) {
        if(reachabilitySingleton == nil) {
            // -init assigns self to reachabilitySingleton and increments the retainCount
            [[[ASIReachability alloc] init] release];
        }
        return reachabilitySingleton;
    }
}

- (id)init {
    @synchronized([ASIReachability class]) {
        if(reachabilitySingleton == nil) {
            if(self = [super init]) {
                id ReachabilityClass = [Reachability class];
                if(reachabilityIs15) {
                    reachability = [[ReachabilityClass sharedReachability] retain];
                    [(id<Reachability15>)reachability setNetworkStatusNotificationsEnabled:YES];
                }
                else {
                    reachability = [[ReachabilityClass reachabilityForInternetConnection] retain];
                    [(id<Reachability20>)reachability startNotifer];
                }
                if(reachability != nil) {
                    reachabilitySingleton = [self retain];
                }
                else {
                    [self release];
                    self = nil;
                }
            }
        }
        else {
            [self release];
            self = [reachabilitySingleton retain];
        }
        return self;
    }
}

- (void)dealloc {
    // We should never enter this method since reachabilitySingleton is the only instance 
    // and it is never released. But we implement it anyway for good form...
    @synchronized([ASIReachability class]) {
        reachabilitySingleton = nil;
        if(reachabilityIs15 == NO) {
            [(id<Reachability20>)reachability stopNotifer];
        }
        [reachability release];
        reachability = nil;
        [super dealloc];
    }
}

- (BOOL)reachableViaWWAN {
    if(reachabilityIs15) {
        NetworkStatus15 status = [(id<Reachability15>)reachability internetConnectionStatus];
        return (status == ReachableViaCarrierDataNetwork15);
    }
    else {
        NetworkStatus20 status = [(id<Reachability20>)reachability currentReachabilityStatus];
        return (status == ReachableViaWWAN20);
    }
}

@end


#endif
