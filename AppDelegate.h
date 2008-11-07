//
//  AppDelegate.h
//
//  Created by Ben Copsey on 09/07/2008.
//  Copyright 2008 All-Seeing Interactive Ltd. All rights reserved.
//

@class ASIHTTPRequest;

@interface AppDelegate : NSObject {
	NSOperationQueue *networkQueue;
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSTextView *htmlSource;
	IBOutlet NSTextField *fileLocation;
	IBOutlet NSWindow *window;
	IBOutlet NSWindow *loginWindow;
	
	IBOutlet NSTextField *host;
	IBOutlet NSTextField *realm;	
	IBOutlet NSTextField *username;
	IBOutlet NSTextField *password;
	
	IBOutlet NSTextField *topSecretInfo;
	IBOutlet NSButton *keychainCheckbox;
	
	IBOutlet NSImageView *imageView1;
	IBOutlet NSImageView *imageView2;
	IBOutlet NSImageView *imageView3;
}

- (IBAction)simpleURLFetch:(id)sender;
- (IBAction)URLFetchWithProgress:(id)sender;


- (IBAction)fetchThreeImages:(id)sender;

- (void)authorizationNeededForRequest:(ASIHTTPRequest *)request;
- (IBAction)dismissAuthSheet:(id)sender;
- (IBAction)fetchTopSecretInformation:(id)sender;

- (IBAction)postWithProgress:(id)sender;

@end
