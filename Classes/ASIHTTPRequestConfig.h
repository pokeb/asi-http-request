//
//  ASIHTTPRequestConfig.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 14/12/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//



/*
ASIHTTPRequest uses Apple's Reachability class (http://developer.apple.com/iphone/library/samplecode/Reachability/) to turn bandwidth throttling on and off automatically when shouldThrottleBandwidthForWWAN is set to YES  on iPhone OS

There are two versions of Apple's Reachability class, both of which are included in the source distribution of ASIHTTPRequest in the External/Reachability folder.

 *    Version 2.0 is the latest version. You should use this if you are targeting iPhone OS 3.x and later
      To use Version 2.0, set this to 1, and include Reachbility.h + Reachbility.m from the Reachability 2.0 folder in your project
 
 *    Version 1.5 is the old version, but it is compatible with both iPhone OS 2.2.1 and iPhone OS 3.0 and later. You should use this if your application needs to work on iPhone OS 2.2.1.
      To use Version 1.5, set this to 0, and include Reachbility.h + Reachbility.m from the Reachability 1.5 folder in your project

This config option is not used for apps targeting Mac OS X 
*/

#define REACHABILITY_20_API 0


// When set to 1, requests will print debug information to the console (currently only used by ASIFormDataRequest)
#define ASIHTTPREQUEST_DEBUG 1