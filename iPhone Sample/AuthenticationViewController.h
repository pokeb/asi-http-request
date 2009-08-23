//
//  AuthenticationViewController.h
//  iPhone
//
//  Created by Ben Copsey on 01/08/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ASINetworkQueue;
@class ASIHTTPRequest;

@interface AuthenticationViewController : UIViewController {
	ASINetworkQueue *networkQueue;
	IBOutlet UISwitch *useKeychain;
	IBOutlet UISwitch *useBuiltInDialog;
	IBOutlet UILabel *topSecretInfo;
	ASIHTTPRequest *requestRequiringAuthentication;
	ASIHTTPRequest *requestRequiringProxyAuthentication;
}
- (IBAction)fetchTopSecretInformation:(id)sender;

@property (retain) ASINetworkQueue *networkQueue;
@property (retain) ASIHTTPRequest *requestRequiringAuthentication;
@property (retain) ASIHTTPRequest *requestRequiringProxyAuthentication;
@end
