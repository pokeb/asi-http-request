//
//  ASIHTTPRequest.h
//
//  Created by Ben Copsey on 04/10/2007.
//  Copyright 2007-2008 All-Seeing Interactive. All rights reserved.
//
//  Portions are based on the ImageClient example from Apple:
//  See: http://developer.apple.com/samplecode/ImageClient/listing37.html

#import <Cocoa/Cocoa.h>
#import "ASIProgressDelegate.h"

@interface ASIHTTPRequest : NSOperation {

	//The url for this operation, should include get params in the query string where appropriate
	NSURL *url; 
	
	//The delegate, you need to manage setting and talking to your delegate in your subclasses
	id delegate;
	
	//Parameters that will be POSTed to the url
	NSMutableDictionary *postData;
	
	//Files that will be POSTed to the url
	NSMutableDictionary *fileData;
	
	//Dictionary for custom request headers
	NSMutableDictionary *requestHeaders;
	
	//If usesKeychain is true, network requests will attempt to read credentials from the keychain, and will save them in the keychain when they are successfully presented
	BOOL usesKeychain;
	
	//When downloadDestinationPath is set, the result of this request will be downloaded to the file at this location
	//If downloadDestinationPath is not set, download data will be stored in memory
	NSString *downloadDestinationPath;
	
	//Used for writing data to a file when downloadDestinationPath is set
	NSOutputStream *outputStream;
	
	//When the request fails or completes successfully, complete will be true
	BOOL complete;
	
	//If an error occurs, error will contain an NSError
	NSError *error;
	
	//If an authentication error occurs, we give the delegate a chance to handle it, ignoreError will be set to true
	BOOL ignoreError;
	
	//Username and password used for authentication
	NSString *username;
	NSString *password;
	
	//Delegate for displaying upload progress (usually an NSProgressIndicator, but you can supply a different object and handle this yourself)
	NSObject <ASIProgressDelegate> *uploadProgressDelegate;
	
	//Delegate for displaying download progress (usually an NSProgressIndicator, but you can supply a different object and handle this yourself)
	NSObject <ASIProgressDelegate> *downloadProgressDelegate;

	// Whether we've seen the headers of the response yet
    BOOL haveExaminedHeaders;
	
	//Data we receive will be stored here
	CFMutableDataRef receivedData;
	
	//Used for sending and receiving data
    CFHTTPMessageRef request;	
	CFReadStreamRef readStream;
	
	// Authentication currently being used for prompting and resuming
    CFHTTPAuthenticationRef authentication;  
	
	// Credentials associated with the authentication (reused until server says no)
	CFMutableDictionaryRef credentials; 

	//Size of the response
	double contentLength;

	//Size of the POST payload
	double postLength;	
	
	//Timer used to update the progress delegates
	NSTimer *progressTimer;
	
	//The total amount of downloaded data
	double totalBytesRead;
	
	//Realm for authentication when credentials are required
	NSString *authenticationRealm;
	
	//Called on the delegate when the request completes successfully
	SEL didFinishSelector;
	
	//Called on the delegate when the request fails
	SEL didFailSelector;
	
	//This lock will block the request until the delegate supplies authentication info
	NSConditionLock *authenticationLock;
}

// Should be an HTTP or HTTPS url, may include username and password if appropriate
- (id)initWithURL:(NSURL *)newURL;

//Add a POST variable to the request
- (void)setPostValue:(id)value forKey:(NSString *)key;

//Add the contents of a local file as a POST variable to the request
- (void)setFile:(NSString *)filePath forKey:(NSString *)key;

//Add a custom header to the request
- (void)addRequestHeader:(NSString *)header value:(NSString *)value;

//the results of this request will be saved to downloadDestinationPath, if it is set
- (void)setDownloadDestinationPath:(NSString *)newDestinationPath;
- (NSString *)downloadDestinationPath;

// When set, username and password will be presented for HTTP authentication
- (void)setUsername:(NSString *)newUsername andPassword:(NSString *)newPassword;

// Delegate will get messages when the request completes, fails or when authentication is required
- (void)setDelegate:(id)newDelegate;

// Called on the delegate when the request completes successfully
- (void)setDidFinishSelector:(SEL)selector;

// Called on the delegate when the request fails
- (void)setDidFailSelector:(SEL)selector;

// upload progress delegate (usually an NSProgressIndicator) is sent information on upload progress
- (void)setUploadProgressDelegate:(id)newDelegate;

// download progress delegate (usually an NSProgressIndicator) is sent information on download progress
- (void)setDownloadProgressDelegate:(id)newDelegate;

// When true, authentication information will automatically be stored in (and re-used from) the keychain
- (void)setUsesKeychain:(BOOL)shouldUseKeychain;

// Will be true when the request is complete (success or failure)
- (BOOL)complete;

// Returns the contents of the result as an NSString (not appropriate for binary data!)
- (NSString *)dataString;

// Accessors for getting information about the request (useful for auth dialogs) 
- (NSString *)authenticationRealm;
- (NSString *)host;

// Contains a description of the error that occurred if the request failed
- (NSError *)error;


// CFnetwork event handlers
- (void)handleStreamComplete;
- (void)handleStreamError;
- (void)handleBytesAvailable;
- (void)handleNetworkEvent:(CFStreamEventType)type;

// Start loading the request
- (void)loadRequest;

// Reads the response headers to find the content length, and returns true if the request needs a username and password (or if those supplied were incorrect)
- (BOOL)isAuthorizationFailure;

// Apply authentication information and resume the request after an authentication challenge
- (void)applyCredentialsAndResume;

// Unlock (unpause) the request thread so it can resume the request
// Should be called by delegates when they have populated the authentication information after an authentication challenge
- (void)retryWithAuthentication;

// Cancel loading and clean up
- (void)cancelLoad;

// Called from timer on main thread to update progress delegates
- (void)updateUploadProgress;
- (void)updateDownloadProgress;

#pragma mark keychain stuff

//Save credentials to the keychain
+ (void)saveCredentials:(NSURLCredential *)credentials forHost:(NSString *)host port:(int)port protocol:(NSString *)protocol realm:(NSString *)realm;

//Return credentials from the keychain
+ (NSURLCredential *)savedCredentialsForHost:(NSString *)host port:(int)port protocol:(NSString *)protocol realm:(NSString *)realm;

//Called when a request completes successfully
- (void)requestFinished;

//Called when a request fails
- (void)failWithProblem:(NSString *)problem;

@end
