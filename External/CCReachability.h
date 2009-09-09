//
//  CCReachability.h
//  CommonCode
//
//  Created by Tristan O'Tierney on 2/18/09.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>


typedef enum {
    CCNetworkStatusNotReachable = 0,
    CCNetworkStatusViaCarrier,
    CCNetworkStatusViaWifi
} CCNetworkStatus;


extern NSString *CCReachabilityChangedNotification;
extern NSString *CCReachabilityPreviousStatusKey;
extern NSString *CCReachabilityCurrentStatusKey;


@interface CCReachability : NSObject {
    BOOL _networkStatusNotificationsEnabled;
    BOOL notificationsEnabledBeforeResign;
    
    NSString *_hostName;
    NSString *_address;    
    NSMutableDictionary *_reachabilityQueries;
    
    CCNetworkStatus previousNetworkStatus;
}

@property BOOL networkStatusNotificationsEnabled;
@property (nonatomic, retain) NSString *hostName; // The remote host whose reachability will be queried.
@property (nonatomic, retain) NSString *address; // The IP address of the remote host whose reachability will be queried.
@property (nonatomic, assign) NSMutableDictionary *reachabilityQueries; // A cache of CCReachabilityQuery objects, which encapsulate SCNetworkReachabilityRef, a host or address, and a run loop. The keys are host names or addresses.
@property (nonatomic, assign) CCNetworkStatus previousNetworkStatus; // This is used to determine if we've transitioned from one state to another
@property (nonatomic, readonly, assign) BOOL connectedToInternet; // returns true if internetConnectionStatus != CCNetworkStatusNotReachable
@property (nonatomic, readonly, assign) BOOL connectedToWifi;

+ (CCReachability *)sharedReachability;

- (CCNetworkStatus)remoteHostStatus; // If self.hostName is nil and self.address is not nil, determines the reachability of self.address.
- (CCNetworkStatus)internetConnectionStatus; // Is the device able to communicate with Internet hosts? If so, through which network interface?
- (CCNetworkStatus)localWiFiConnectionStatus; // Is the device able to communicate with hosts on the local WiFi network? (Typically these are Bonjour hosts).

@end
