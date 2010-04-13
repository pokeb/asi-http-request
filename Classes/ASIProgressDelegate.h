//
//  ASIProgressDelegate.h
//  Mac
//
//  Created by Ben Copsey on 13/04/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ASIHTTPRequest;

@protocol ASIProgressDelegate

@optional
- (void)request:(ASIHTTPRequest *)request didReceiveBytes:(long long)bytes;
- (void)request:(ASIHTTPRequest *)request didSendBytes:(long long)bytes;
- (void)request:(ASIHTTPRequest *)request resetDownloadContentLength:(long long)newLength;
- (void)request:(ASIHTTPRequest *)request resetUploadContentLength:(long long)newLength;
@end
