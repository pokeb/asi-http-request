//
//  AppDelegate.h
//
//  Created by Ben Copsey on 09/07/2008.
//  Copyright 2008 All-Seeing Interactive Ltd. All rights reserved.
//

@class ASIHTTPRequest;
@class ASINetworkQueue;

@interface AppDelegate : NSObject {
	ASINetworkQueue *networkQueue;
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSTextView *htmlSource;
	IBOutlet NSTextField *fileLocation;
	IBOutlet NSWindow *window;
	IBOutlet NSWindow *loginWindow;
	
	IBOutlet NSButton *showAccurateProgress;
	
	IBOutlet NSTextField *host;
	IBOutlet NSTextField *realm;	
	IBOutlet NSTextField *username;
	IBOutlet NSTextField *password;
	
	IBOutlet NSTextField *topSecretInfo;
	IBOutlet NSButton *keychainCheckbox;
	
	IBOutlet NSImageView *imageView1;
	IBOutlet NSImageView *imageView2;
	IBOutlet NSImageView *imageView3;
	IBOutlet NSProgressIndicator *imageProgress1;
	IBOutlet NSProgressIndicator *imageProgress2;
	IBOutlet NSProgressIndicator *imageProgress3;
	
	IBOutlet NSButton *startButton;
	IBOutlet NSButton *resumeButton;
	
	IBOutlet NSTextField *bandwidthUsed;
	
	ASIHTTPRequest *bigFetchRequest;
	IBOutlet NSTextField *postStatus;
}

- (IBAction)simpleURLFetch:(id)sender;
- (IBAction)URLFetchWithProgress:(id)sender;
- (IBAction)stopURLFetchWithProgress:(id)sender;
- (IBAction)resumeURLFetchWithProgress:(id)sender;

- (IBAction)fetchThreeImages:(id)sender;

- (void)authenticationNeededForRequest:(ASIHTTPRequest *)request;
- (IBAction)dismissAuthSheet:(id)sender;
- (IBAction)fetchTopSecretInformation:(id)sender;

- (IBAction)postWithProgress:(id)sender;

- (IBAction)throttleBandwidth:(id)sender;

- (void)updateBandwidthUsageIndicator;
- (void)URLFetchWithProgressComplete:(ASIHTTPRequest *)request;
- (void)URLFetchWithProgressFailed:(ASIHTTPRequest *)request;
- (void)imageFetch1Complete:(ASIHTTPRequest *)request;
- (void)imageFetch2Complete:(ASIHTTPRequest *)request;
- (void)imageFetch3Complete:(ASIHTTPRequest *)request;
- (void)topSecretFetchComplete:(ASIHTTPRequest *)request;
- (void)authSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)postFinished:(ASIHTTPRequest *)request;
- (void)postFailed:(ASIHTTPRequest *)request;

@property (retain, nonatomic) ASIHTTPRequest *bigFetchRequest;
@end
