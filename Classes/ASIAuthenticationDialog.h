//
//  ASIAuthenticationDialog.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 21/08/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ASIHTTPRequest;

typedef enum _ASIAuthenticationType {
	ASIStandardAuthenticationType = 0,
    ASIProxyAuthenticationType = 1
} ASIAuthenticationType;
	
@interface ASIAuthenticationDialog : UIViewController <UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate> {
	ASIHTTPRequest *request;
	ASIAuthenticationType type;
	UITableView *tableView;
	UIViewController *presentingController;
	UIBarButtonItem *loginButton;
}
+ (void)presentAuthenticationDialogForRequest:(ASIHTTPRequest *)request;
+ (void)presentProxyAuthenticationDialogForRequest:(ASIHTTPRequest *)request;

+ (void)dismiss;

@property (retain) ASIHTTPRequest *request;
@property (assign) ASIAuthenticationType type;
@end
