/*

File: Reachability.m
Abstract: SystemConfiguration framework wrapper.

Version: 1.5

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
("Apple") in consideration of your agreement to the following terms, and your
use, installation, modification or redistribution of this Apple software
constitutes acceptance of these terms.  If you do not agree with these terms,
please do not use, install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and subject
to these terms, Apple grants you a personal, non-exclusive license, under
Apple's copyrights in this original Apple software (the "Apple Software"), to
use, reproduce, modify and redistribute the Apple Software, with or without
modifications, in source and/or binary forms; provided that if you redistribute
the Apple Software in its entirety and without modifications, you must retain
this notice and the following text and disclaimers in all such redistributions
of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may be used
to endorse or promote products derived from the Apple Software without specific
prior written permission from Apple.  Except as expressly stated in this notice,
no other rights or licenses, express or implied, are granted by Apple herein,
including but not limited to any patent rights that may be infringed by your
derivative works or by other works in which the Apple Software may be
incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2008 Apple Inc. All Rights Reserved.

*/

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#include <netdb.h>

#import "Reachability.h"
#import <SystemConfiguration/SCNetworkReachability.h>

static NSString *kLinkLocalAddressKey = @"169.254.0.0";
static NSString *kDefaultRouteKey = @"0.0.0.0";

static Reachability *_sharedReachability;

// A class extension that declares internal methods for this class.
@interface Reachability()
- (BOOL)isAdHocWiFiNetworkAvailableFlags:(SCNetworkReachabilityFlags *)outFlags;
- (BOOL)isNetworkAvailableFlags:(SCNetworkReachabilityFlags *)outFlags;
- (BOOL)isReachableWithoutRequiringConnection:(SCNetworkReachabilityFlags)flags;
- (SCNetworkReachabilityRef)reachabilityRefForHostName:(NSString *)hostName;
- (SCNetworkReachabilityRef)reachabilityRefForAddress:(NSString *)address;
- (BOOL)addressFromString:(NSString *)IPAddress address:(struct sockaddr_in *)outAddress;
- (void)stopListeningForReachabilityChanges;
@end

@implementation Reachability

@synthesize networkStatusNotificationsEnabled = _networkStatusNotificationsEnabled;
@synthesize hostName = _hostName;
@synthesize address = _address;
@synthesize reachabilityQueries = _reachabilityQueries;

+ (Reachability *)sharedReachability
{
	if (!_sharedReachability) {
		_sharedReachability = [[Reachability alloc] init];
		// Clients of Reachability will typically call [[Reachability sharedReachability] setHostName:]
		// before calling one of the status methods.
        _sharedReachability.hostName = nil;
		_sharedReachability.address = nil;
		_sharedReachability.networkStatusNotificationsEnabled = NO;
		_sharedReachability.reachabilityQueries = [[NSMutableDictionary alloc] init];
	}
	return _sharedReachability;
}

- (void) dealloc
{	
    [self stopListeningForReachabilityChanges];
    
	[_sharedReachability.reachabilityQueries release];
	[_sharedReachability release];
	[super dealloc];
}

- (BOOL)isReachableWithoutRequiringConnection:(SCNetworkReachabilityFlags)flags
{
    // kSCNetworkReachabilityFlagsReachable indicates that the specified nodename or address can
	// be reached using the current network configuration.
	BOOL isReachable = flags & kSCNetworkReachabilityFlagsReachable;
	
	// This flag indicates that the specified nodename or address can
	// be reached using the current network configuration, but a
	// connection must first be established.
	//
	// If the flag is false, we don't have a connection. But because CFNetwork
    // automatically attempts to bring up a WWAN connection, if the WWAN reachability
    // flag is present, a connection is not required.
	BOOL noConnectionRequired = !(flags & kSCNetworkReachabilityFlagsConnectionRequired);
	if ((flags & kSCNetworkReachabilityFlagsIsWWAN)) {
		noConnectionRequired = YES;
	}
	
	return (isReachable && noConnectionRequired) ? YES : NO;
}

// Returns whether or not the current host name is reachable with the current network configuration.
- (BOOL)isHostReachable:(NSString *)host
{
    if (!host || ![host length]) {
        return NO;
    }
    
    SCNetworkReachabilityFlags		flags;
    SCNetworkReachabilityRef reachability =  SCNetworkReachabilityCreateWithName(NULL, [host UTF8String]);
	BOOL gotFlags = SCNetworkReachabilityGetFlags(reachability, &flags);
    
	CFRelease(reachability);
    
    if (!gotFlags) {
        return NO;
    }
    
	return [self isReachableWithoutRequiringConnection:flags];
}

// This returns YES if the address 169.254.0.0 is reachable without requiring a connection.
- (BOOL)isAdHocWiFiNetworkAvailableFlags:(SCNetworkReachabilityFlags *)outFlags
{		
    // Look in the cache of reachability queries for one that matches this query.
	ReachabilityQuery *query = [self.reachabilityQueries objectForKey:kLinkLocalAddressKey];
	SCNetworkReachabilityRef adHocWiFiNetworkReachability = query.reachabilityRef;
	
    // If a cached reachability query was not found, create one.
    if (!adHocWiFiNetworkReachability) {
        
        // Build a sockaddr_in that we can pass to the address reachability query.
        struct sockaddr_in sin;
        
        bzero(&sin, sizeof(sin));
        sin.sin_len = sizeof(sin);
        sin.sin_family = AF_INET;
        // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
        sin.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
        
        adHocWiFiNetworkReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&sin);
		
		query = [[[ReachabilityQuery alloc] init] autorelease];
		query.hostNameOrAddress = kLinkLocalAddressKey;
		query.reachabilityRef = adHocWiFiNetworkReachability;
		
        // Add the reachability query to the cache.
		[self.reachabilityQueries setObject:query forKey:kLinkLocalAddressKey];
    }
	
	// If necessary, register for notifcations for the SCNetworkReachabilityRef on the current run loop.
	// If an existing SCNetworkReachabilityRef was found in the cache, we can reuse it and register
	// to receive notifications from it in the current run loop, which may be different than the run loop
	// that was previously used when registering the SCNetworkReachabilityRef for notifications.
    // -scheduleOnRunLoop: will schedule only if network status notifications are enabled in the Reachability instance.
    // By default, they are not enabled. 
	[query scheduleOnRunLoop:[NSRunLoop currentRunLoop]];
    
    SCNetworkReachabilityFlags addressReachabilityFlags;
    BOOL gotFlags = SCNetworkReachabilityGetFlags(adHocWiFiNetworkReachability, &addressReachabilityFlags);
    if (!gotFlags) {
        // There was an error getting the reachability flags.
        return NO;
    }
    
    // Callers of this method might want to use the reachability flags, so if an 'out' parameter
    // was passed in, assign the reachability flags to it.
    if (outFlags) {
        *outFlags = addressReachabilityFlags;
    }
    
    return [self isReachableWithoutRequiringConnection:addressReachabilityFlags];
}

// ReachabilityCallback is registered as the callback for network state changes in startListeningForReachabilityChanges.
static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Post a notification to notify the client that the network reachability changed.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kNetworkReachabilityChangedNotification" object:nil];
	
	[pool release];
}

// Perform a reachability query for the address 0.0.0.0. If that address is reachable without
// requiring a connection, a network interface is available. We'll have to do more work to
// determine which network interface is available.
- (BOOL)isNetworkAvailableFlags:(SCNetworkReachabilityFlags *)outFlags
{
	ReachabilityQuery *query = [self.reachabilityQueries objectForKey:kDefaultRouteKey];
	SCNetworkReachabilityRef defaultRouteReachability = query.reachabilityRef;
	
    // If a cached reachability query was not found, create one.
    if (!defaultRouteReachability) {
        
        struct sockaddr_in zeroAddress;
        bzero(&zeroAddress, sizeof(zeroAddress));
        zeroAddress.sin_len = sizeof(zeroAddress);
        zeroAddress.sin_family = AF_INET;
        
        defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
		
		ReachabilityQuery *query = [[[ReachabilityQuery alloc] init] autorelease];
		query.hostNameOrAddress = kDefaultRouteKey;
		query.reachabilityRef = defaultRouteReachability;
		
		[self.reachabilityQueries setObject:query forKey:kDefaultRouteKey];
    }
	
	// If necessary, register for notifcations for the SCNetworkReachabilityRef on the current run loop.
	// If an existing SCNetworkReachabilityRef was found in the cache, we can reuse it and register
	// to receive notifications from it in the current run loop, which may be different than the run loop
	// that was previously used when registering the SCNetworkReachabilityRef for notifications. 
    // -scheduleOnRunLoop: will schedule only if network status notifications are enabled in the Reachability instance.
    // By default, they are not enabled. 
	[query scheduleOnRunLoop:[NSRunLoop currentRunLoop]];
	
	SCNetworkReachabilityFlags flags;
	BOOL gotFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
	if (!gotFlags) {
        return NO;
    }
    
	BOOL isReachable = [self isReachableWithoutRequiringConnection:flags];
	
	// Callers of this method might want to use the reachability flags, so if an 'out' parameter
	// was passed in, assign the reachability flags to it.
	if (outFlags) {
		*outFlags = flags;
	}
	
	return isReachable;
}

// Be a good citizen and unregister for network state changes when the application terminates.
- (void)stopListeningForReachabilityChanges
{
	// Walk through the cache that holds SCNetworkReachabilityRefs for reachability
	// queries to particular hosts or addresses.
	NSEnumerator *enumerator = [self.reachabilityQueries objectEnumerator];
	ReachabilityQuery *reachabilityQuery;
    
	while (reachabilityQuery = [enumerator nextObject]) {
		
		CFArrayRef runLoops = reachabilityQuery.runLoops;
		NSUInteger runLoopCounter, maxRunLoops = CFArrayGetCount(runLoops);
        
		for (runLoopCounter = 0; runLoopCounter < maxRunLoops; runLoopCounter++) {
			CFRunLoopRef nextRunLoop = (CFRunLoopRef)CFArrayGetValueAtIndex(runLoops, runLoopCounter);
			
			SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityQuery.reachabilityRef, nextRunLoop, kCFRunLoopDefaultMode);
		}
        
        CFArrayRemoveAllValues(reachabilityQuery.runLoops);
	}
}

/*
 Create a SCNetworkReachabilityRef for hostName, which lets us determine if hostName
 is currently reachable, and lets us register to receive notifications when the 
 reachability of hostName changes.
 */
- (SCNetworkReachabilityRef)reachabilityRefForHostName:(NSString *)hostName
{
	if (!hostName || ![hostName length]) {
		return NULL;
	}
	
	// Look in the cache for an existing SCNetworkReachabilityRef for hostName.
	ReachabilityQuery *cachedQuery = [self.reachabilityQueries objectForKey:hostName];
	SCNetworkReachabilityRef reachabilityRefForHostName = cachedQuery.reachabilityRef;
	
	if (reachabilityRefForHostName) {
		return reachabilityRefForHostName;
	}
	
	// Didn't find an existing SCNetworkReachabilityRef for hostName, so create one ...
	reachabilityRefForHostName = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [hostName UTF8String]);
    
    NSAssert1(reachabilityRefForHostName != NULL, @"Failed to create SCNetworkReachabilityRef for host: %@", hostName);
    
	ReachabilityQuery *query = [[[ReachabilityQuery alloc] init] autorelease];
	query.hostNameOrAddress = hostName;
	query.reachabilityRef = reachabilityRefForHostName;
	
    // If necessary, register for notifcations for the SCNetworkReachabilityRef on the current run loop.
    // If an existing SCNetworkReachabilityRef was found in the cache, we can reuse it and register
    // to receive notifications from it in the current run loop, which may be different than the run loop
    // that was previously used when registering the SCNetworkReachabilityRef for notifications.
    // -scheduleOnRunLoop: will schedule only if network status notifications are enabled in the Reachability instance.
    // By default, they are not enabled. 
    [query scheduleOnRunLoop:[NSRunLoop currentRunLoop]];
    
    // ... and add it to the cache.
    [self.reachabilityQueries setObject:query forKey:hostName];
    return reachabilityRefForHostName;
}

/*
 Create a SCNetworkReachabilityRef for the IP address in addressString, which lets us determine if 
 the address is currently reachable, and lets us register to receive notifications when the 
 reachability of the address changes.
 */
- (SCNetworkReachabilityRef)reachabilityRefForAddress:(NSString *)addressString
{
	if (!addressString || ![addressString length]) {
		return NULL;
	}
	
	struct sockaddr_in address;
	
	BOOL gotAddress = [self addressFromString:addressString address:&address];
	if (!gotAddress) {
        // The attempt to convert addressString to a sockaddr_in failed.
        NSAssert1(gotAddress != NO, @"Failed to convert an IP address string to a sockaddr_in: %@", addressString);
		return NULL;
	}
	
	// Look in the cache for an existing SCNetworkReachabilityRef for addressString.
	ReachabilityQuery *cachedQuery = [self.reachabilityQueries objectForKey:addressString];
	SCNetworkReachabilityRef reachabilityRefForAddress = cachedQuery.reachabilityRef;
	
	if (reachabilityRefForAddress) {
		return reachabilityRefForAddress;
	}
	
	// Didn't find an existing SCNetworkReachabilityRef for addressString, so create one.
	reachabilityRefForAddress = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (struct sockaddr *)&address);
    
    NSAssert1(reachabilityRefForAddress != NULL, @"Failed to create SCNetworkReachabilityRef for address: %@", addressString);
    
	ReachabilityQuery *query = [[[ReachabilityQuery alloc] init] autorelease];
	query.hostNameOrAddress = addressString;
	query.reachabilityRef = reachabilityRefForAddress;
    
    // If necessary, register for notifcations for the SCNetworkReachabilityRef on the current run loop.
    // If an existing SCNetworkReachabilityRef was found in the cache, we can reuse it and register
    // to receive notifications from it in the current run loop, which may be different than the run loop
    // that was previously used when registering the SCNetworkReachabilityRef for notifications.
    // -scheduleOnRunLoop: will schedule only if network status notifications are enabled in the Reachability instance.
    // By default, they are not enabled. 
    [query scheduleOnRunLoop:[NSRunLoop currentRunLoop]];
    
    // ... and add it to the cache.
    [self.reachabilityQueries setObject:query forKey:addressString];
    return reachabilityRefForAddress;
}

- (NetworkStatus)remoteHostStatus
{
	/*
     If the current host name or address is reachable, determine which network interface it is reachable through.
     If the host is reachable and the reachability flags include kSCNetworkReachabilityFlagsIsWWAN, it
     is reachable through the carrier data network. If the host is reachable and the reachability
     flags do not include kSCNetworkReachabilityFlagsIsWWAN, it is reachable through the WiFi network.
     */
    
	SCNetworkReachabilityRef reachabilityRef = nil;
	if (self.hostName) {
		reachabilityRef = [self reachabilityRefForHostName:self.hostName];
		
	} else if (self.address) {
		reachabilityRef = [self reachabilityRefForAddress:self.address];
		
	} else {
		NSAssert(self.hostName != nil && self.address != nil, @"No hostName or address specified. Cannot determine reachability.");
		return NotReachable;
	}
	
	if (!reachabilityRef) {
		return NotReachable;
	}
	
	SCNetworkReachabilityFlags reachabilityFlags;
	BOOL gotFlags = SCNetworkReachabilityGetFlags(reachabilityRef, &reachabilityFlags);
    if (!gotFlags) {
        return NotReachable;
    }
    
	BOOL reachable = [self isReachableWithoutRequiringConnection:reachabilityFlags];
	
	if (!reachable) {
		return NotReachable;
	}
	if (reachabilityFlags & ReachableViaCarrierDataNetwork) {
		return ReachableViaCarrierDataNetwork;
	}
	
	return ReachableViaWiFiNetwork;
}

- (NetworkStatus)internetConnectionStatus
{
	/*
     To determine if the device has an Internet connection, query the address
     0.0.0.0. If it's reachable without requiring a connection, first check
     for the kSCNetworkReachabilityFlagsIsDirect flag, which tell us if the connection
     is to an ad-hoc WiFi network. If it is not, the device can access the Internet.
     The next thing to determine is how the device can access the Internet, which
     can either be through the carrier data network (EDGE or other service) or through
     a WiFi connection.
     
     Note: Knowing that the device has an Internet connection is not the same as
     knowing if the device can reach a particular host. To know that, use
     -[Reachability remoteHostStatus].
     */
	
	SCNetworkReachabilityFlags defaultRouteFlags;
	BOOL defaultRouteIsAvailable = [self isNetworkAvailableFlags:&defaultRouteFlags];
	if (defaultRouteIsAvailable) {
        
		if (defaultRouteFlags & kSCNetworkReachabilityFlagsIsDirect) {
            
			// The connection is to an ad-hoc WiFi network, so Internet access is not available.
			return NotReachable;
		}
		else if (defaultRouteFlags & ReachableViaCarrierDataNetwork) {
			return ReachableViaCarrierDataNetwork;
		}
		
		return ReachableViaWiFiNetwork;
	}
	
	return NotReachable;
}

- (NetworkStatus)localWiFiConnectionStatus
{
	SCNetworkReachabilityFlags selfAssignedAddressFlags;
	
	/*
     To determine if the WiFi connection is to a local ad-hoc network,
     check the availability of the address 169.254.x.x. That's an address
     in the self-assigned range, and the device will have a self-assigned IP
     when it's connected to a ad-hoc WiFi network. So to test if the device
     has a self-assigned IP, look for the kSCNetworkReachabilityFlagsIsDirect flag
     in the address query. If it's present, we know that the WiFi connection
     is to an ad-hoc network.
     */
	// This returns YES if the address 169.254.0.0 is reachable without requiring a connection.
	BOOL hasLinkLocalNetworkAccess = [self isAdHocWiFiNetworkAvailableFlags:&selfAssignedAddressFlags];
    
	if (hasLinkLocalNetworkAccess && (selfAssignedAddressFlags & kSCNetworkReachabilityFlagsIsDirect)) {
		return ReachableViaWiFiNetwork;
	}
	
	return NotReachable;
}

// Convert an IP address from an NSString to a sockaddr_in * that can be used to create
// the reachability request.
- (BOOL)addressFromString:(NSString *)IPAddress address:(struct sockaddr_in *)address
{
	if (!IPAddress || ![IPAddress length]) {
		return NO;
	}
	
	memset((char *) address, sizeof(struct sockaddr_in), 0);
	address->sin_family = AF_INET;
	address->sin_len = sizeof(struct sockaddr_in);
	
	int conversionResult = inet_aton([IPAddress UTF8String], &address->sin_addr);
	if (conversionResult == 0) {
		NSAssert1(conversionResult != 1, @"Failed to convert the IP address string into a sockaddr_in: %@", IPAddress);
		return NO;
	}
	
	return YES;
}

@end

@interface ReachabilityQuery ()
- (CFRunLoopRef)startListeningForReachabilityChanges:(SCNetworkReachabilityRef)reachability onRunLoop:(CFRunLoopRef)runLoop;
@end

@implementation ReachabilityQuery

@synthesize reachabilityRef = _reachabilityRef;
@synthesize runLoops = _runLoops;
@synthesize hostNameOrAddress = _hostNameOrAddress;

- (id)init
{
	self = [super init];
	if (self != nil) {
		self.runLoops = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
	}
	return self;
}

- (void)dealloc
{
	CFRelease(self.runLoops);
	[super dealloc];
}

- (BOOL)isScheduledOnRunLoop:(CFRunLoopRef)runLoop
{
	NSUInteger runLoopCounter, maxRunLoops = CFArrayGetCount(self.runLoops);
	
	for (runLoopCounter = 0; runLoopCounter < maxRunLoops; runLoopCounter++) {
		CFRunLoopRef nextRunLoop = (CFRunLoopRef)CFArrayGetValueAtIndex(self.runLoops, runLoopCounter);
		
		if (nextRunLoop == runLoop) {
			return YES;
		}
	}
	
	return NO;
}

- (void)scheduleOnRunLoop:(NSRunLoop *)inRunLoop
{
	// Only register for network state changes if the client has specifically enabled them.
	if ([[Reachability sharedReachability] networkStatusNotificationsEnabled] == NO) {
		return;
	}
	
	if (!inRunLoop) {
		return;
	}
	
	CFRunLoopRef runLoop = [inRunLoop getCFRunLoop];
	
	// Notifications of status changes for each reachability query can be scheduled on multiple run loops.
	// To support that, register for notifications for each runLoop.
	// -isScheduledOnRunLoop: iterates over all of the run loops that have previously been used
	// to register for notifications. If one is found that matches the passed in runLoop argument, there's
	// no need to register for notifications again. If one is not found, register for notifications
	// using the current runLoop.
	if (![self isScheduledOnRunLoop:runLoop]) {
        
		CFRunLoopRef notificationRunLoop = [self startListeningForReachabilityChanges:self.reachabilityRef onRunLoop:runLoop];
		if (notificationRunLoop) {
			CFArrayAppendValue(self.runLoops, notificationRunLoop);
		}
	}
}

// Register to receive changes to the 'reachability' query so that we can update the
// user interface when the network state changes.
- (CFRunLoopRef)startListeningForReachabilityChanges:(SCNetworkReachabilityRef)reachability onRunLoop:(CFRunLoopRef)runLoop
{	
	if (!reachability) {
		return NULL;
	}
	
	if (!runLoop) {
		return NULL;
	}
    
	SCNetworkReachabilityContext	context = {0, self, NULL, NULL, NULL};
	SCNetworkReachabilitySetCallback(reachability, ReachabilityCallback, &context);
	SCNetworkReachabilityScheduleWithRunLoop(reachability, runLoop, kCFRunLoopDefaultMode);
	
	return runLoop;
}


@end
