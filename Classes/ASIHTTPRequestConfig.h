//
//  ASIHTTPRequestConfig.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 14/12/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//


// ======
// Debug output configuration options
// ======

// When set to 1 ASIHTTPRequests will print information about what a request is doing
#ifndef DEBUG_REQUEST_STATUS
	#define DEBUG_REQUEST_STATUS 0
#endif

// When set to 1, ASIFormDataRequests will print information about the request body to the console
#ifndef DEBUG_FORM_DATA_REQUEST
	#define DEBUG_FORM_DATA_REQUEST 0
#endif

// When set to 1, ASIHTTPRequests will print information about bandwidth throttling to the console
#ifndef DEBUG_THROTTLING
	#define DEBUG_THROTTLING 0
#endif

// When set to 1, ASIHTTPRequests will print information about persistent connections to the console
#ifndef DEBUG_PERSISTENT_CONNECTIONS
	#define DEBUG_PERSISTENT_CONNECTIONS 0
#endif

// ======
// Reachability API (iPhone only)
// ======

/*
ASIHTTPRequest uses Apple's Reachability class (http://developer.apple.com/iphone/library/samplecode/Reachability/) to turn bandwidth throttling on and off automatically when shouldThrottleBandwidthForWWAN is set to YES  on iPhone OS

There are two versions of Apple's Reachability class, both of which are included in the source distribution of ASIHTTPRequest in the External/Reachability folder.

 *    Version 2.0 is the latest version. You should use this if you are targeting iPhone OS 3.x and later
      To use Version 2.0, set this to 1, and include Reachability.h + Reachability.m from the Reachability 2.0 folder in your project
 
 *    Version 1.5 is the old version, but it is compatible with both iPhone OS 2.2.1 and iPhone OS 3.0 and later. You should use this if your application needs to work on iPhone OS 2.2.1.
      To use Version 1.5, set this to 0, and include Reachability.h + Reachability.m from the Reachability 1.5 folder in your project

This config option is not used for apps targeting Mac OS X 
*/

#ifndef REACHABILITY_20_API
	#define REACHABILITY_20_API 0
#endif

