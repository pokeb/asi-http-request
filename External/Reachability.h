/*

File: Reachability.h
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

#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>

@class Reachability;

@interface Reachability : NSObject {
    
@private
	BOOL _networkStatusNotificationsEnabled;
	
	NSString *_hostName;
	NSString *_address;
    
	NSMutableDictionary *_reachabilityQueries;
}

/*
 An enumeration that defines the return values of the network state
 of the device.
 */
typedef enum {
	NotReachable = 0,
	ReachableViaCarrierDataNetwork,
	ReachableViaWiFiNetwork
} NetworkStatus;


// Set to YES to register for changes in network status. Otherwise reachability queries
// will be handled synchronously.
@property BOOL networkStatusNotificationsEnabled;
// The remote host whose reachability will be queried.
// Either this or 'addressName' must be set.
@property (nonatomic, retain) NSString *hostName;
// The IP address of the remote host whose reachability will be queried.
// Either this or 'hostName' must be set.
@property (nonatomic, retain) NSString *address;
// A cache of ReachabilityQuery objects, which encapsulate a SCNetworkReachabilityRef, a host or address, and a run loop. The keys are host names or addresses.
@property (nonatomic, assign) NSMutableDictionary *reachabilityQueries;

// This class is intended to be used as a singleton.
+ (Reachability *)sharedReachability;

// Is self.hostName is not nil, determines its reachability.
// If self.hostName is nil and self.address is not nil, determines the reachability of self.address.
- (NetworkStatus)remoteHostStatus;
// Is the device able to communicate with Internet hosts? If so, through which network interface?
- (NetworkStatus)internetConnectionStatus;
// Is the device able to communicate with hosts on the local WiFi network? (Typically these are Bonjour hosts).
- (NetworkStatus)localWiFiConnectionStatus;

/*
 When reachability change notifications are posted, the callback method 'ReachabilityCallback' is called
 and posts a notification that the client application can observe to learn about changes.
 */
static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info);

@end

@interface ReachabilityQuery : NSObject
{
@private
	SCNetworkReachabilityRef _reachabilityRef;
	CFMutableArrayRef _runLoops;
	NSString *_hostNameOrAddress;
}
// Keep around each network reachability query object so that we can
// register for updates from those objects.
@property (nonatomic) SCNetworkReachabilityRef reachabilityRef;
@property (nonatomic, retain) NSString *hostNameOrAddress;
@property (nonatomic) CFMutableArrayRef runLoops;

- (void)scheduleOnRunLoop:(NSRunLoop *)inRunLoop;

@end

