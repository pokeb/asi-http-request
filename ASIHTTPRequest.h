//
//  ASIHTTPRequest.h
//
//  Created by Ben Copsey on 04/10/2007.
//  Copyright 2007-2008 All-Seeing Interactive. All rights reserved.
//
//  A guide to the main features is available at:
//  http://allseeing-i.com/asi-http-request
//
//  Portions are based on the ImageClient example from Apple:
//  See: http://developer.apple.com/samplecode/ImageClient/listing37.html


@interface ASIHTTPRequest : NSOperation {
	
	//The url for this operation, should include GET params in the query string where appropriate
	NSURL *url; 
	
	//The delegate, you need to manage setting and talking to your delegate in your subclasses
	id delegate;
	
	//HTTP method to use (GET / POST / PUT / DELETE). Defaults to GET
	NSString *requestMethod;
	
	//Request body
	NSData *postBody;
	
	//Dictionary for custom HTTP request headers
	NSMutableDictionary *requestHeaders;
	
	//Will be populated with HTTP response headers from the server
	NSDictionary *responseHeaders;
	
	//Can be used to manually insert cookie headers to a request, but it's more likely that sessionCookies will do this for you
	NSMutableArray *requestCookies;
	
	//Will be populated with Cookies
	NSArray *responseCookies;
	
	//If use cokie persistance is true, network requests will present valid cookies from previous requests
	BOOL useCookiePersistance;
	
	//If useKeychainPersistance is true, network requests will attempt to read credentials from the keychain, and will save them in the keychain when they are successfully presented
	BOOL useKeychainPersistance;
	
	//If useSessionPersistance is true, network requests will save credentials and reuse for the duration of the session (until clearSession is called)
	BOOL useSessionPersistance;
	
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

	//Domain used for NTLM authentication
	NSString *domain;
	
	//Delegate for displaying upload progress (usually an NSProgressIndicator, but you can supply a different object and handle this yourself)
	id uploadProgressDelegate;
	
	//Delegate for displaying download progress (usually an NSProgressIndicator, but you can supply a different object and handle this yourself)
	id downloadProgressDelegate;

	// Whether we've seen the headers of the response yet
    BOOL haveExaminedHeaders;
	
	//Data we receive will be stored here
	NSMutableData *receivedData;
	
	//Used for sending and receiving data
    CFHTTPMessageRef request;	
	CFReadStreamRef readStream;
	
	// Authentication currently being used for prompting and resuming
    CFHTTPAuthenticationRef requestAuthentication; 
	NSMutableDictionary *requestCredentials;

	// HTTP status code, eg: 200 = OK, 404 = Not found etc
	int responseStatusCode;
	
	//Size of the response
	unsigned int contentLength;

	//Size of the POST payload
	unsigned int postLength;	
	
	//The total amount of downloaded data
	unsigned int totalBytesRead;
	
	//Last amount of data read (used for incrementing progress)
	unsigned int lastBytesRead;
	//Last amount of data sent (used for incrementing progress)
	unsigned int lastBytesSent;
	
	//Realm for authentication when credentials are required
	NSString *authenticationRealm;

	//This lock will block the request until the delegate supplies authentication info
	NSConditionLock *authenticationLock;
	
	//Called on the delegate when the request completes successfully
	SEL didFinishSelector;
	
	//Called on the delegate when the request fails
	SEL didFailSelector;
	
	//Used for recording when something last happened during the request, we will compare this value with the current date to time out requests when appropriate
	NSDate *lastActivityTime;
	
	// Number of seconds to wait before timing out - default is 10
	NSTimeInterval timeOutSeconds;
	
	// Autorelease pool for the main loop, since it's highly likely that this operation will run in a thread
	NSAutoreleasePool *pool;
	
	// Will be YES when a HEAD request will handle the content-length before this request starts
	BOOL useCachedContentLength;
	
	// Used by HEAD requests when showAccurateProgress is YES to preset the content-length for this request
	ASIHTTPRequest *mainRequest;
	
	// When NO, this request will only update the progress indicator when it completes
	// When YES, this request will update the progress indicator according to how much data it has recieved so far
	// The default for requests is YES
	// Also see the comments in ASINetworkQueue.h
	BOOL showAccurateProgress;
	
	BOOL updatedProgress;
	
	BOOL haveBuiltPostBody;
}

#pragma mark init / dealloc

// Should be an HTTP or HTTPS url, may include username and password if appropriate
- (id)initWithURL:(NSURL *)newURL;

#pragma mark setup request

//Add a custom header to the request
- (void)addRequestHeader:(NSString *)header value:(NSString *)value;

- (void)buildPostBody;

#pragma mark get information about this request

- (BOOL)isFinished; //Same thing, for NSOperationQueues to read

// Get total amount of data received so far for this request
- (int)totalBytesRead;

// Returns the contents of the result as an NSString (not appropriate for binary data!)
- (NSString *)dataString;

#pragma mark request logic

// Start loading the request
- (void)loadRequest;

// Cancel loading and clean up
- (void)cancelLoad;

#pragma mark upload/download progress

// Called on main thread to update progress delegates
- (void)updateProgressIndicators;
- (void)resetUploadProgress:(NSNumber *)max;
- (void)updateUploadProgress;
- (void)resetDownloadProgress:(NSNumber *)max;
- (void)updateDownloadProgress;

// Called when authorisation is needed, as we only find out we don't have permission to something when the upload is complete
- (void)removeUploadProgressSoFar;

// Helper method for interacting with progress indicators to abstract the details of different APIS (NSProgressIndicator and UIProgressView)
+ (void)setProgress:(double)progress forProgressIndicator:(id)indicator;

#pragma mark handling request complete / failure

// Called when a request completes successfully - defaults to: @selector(requestFinished:)
- (void)requestFinished;

// Called when a request fails - defaults to: @selector(requestFailed:)
- (void)failWithProblem:(NSString *)problem;

#pragma mark http authentication stuff

// Reads the response headers to find the content length, and returns true if the request needs a username and password (or if those supplied were incorrect)
- (BOOL)readResponseHeadersReturningAuthenticationFailure;

// Apply credentials to this request
- (BOOL)applyCredentials:(NSMutableDictionary *)newCredentials;

// Attempt to obtain credentials for this request from the URL, username and password or keychain
- (NSMutableDictionary *)findCredentials;

// Unlock (unpause) the request thread so it can resume the request
// Should be called by delegates when they have populated the authentication information after an authentication challenge
- (void)retryWithAuthentication;

// Apply authentication information and resume the request after an authentication challenge
- (void)attemptToApplyCredentialsAndResume;

// Customise or overidde this to have a generic error for authentication failure
- (NSError *)authenticationError;

#pragma mark stream status handlers

// CFnetwork event handlers
- (void)handleNetworkEvent:(CFStreamEventType)type;
- (void)handleBytesAvailable;
- (void)handleStreamComplete;
- (void)handleStreamError;

#pragma mark managing the session

+ (void)setSessionCredentials:(NSMutableDictionary *)newCredentials;
+ (void)setSessionAuthentication:(CFHTTPAuthenticationRef)newAuthentication;

#pragma mark keychain storage

// Save credentials for this request to the keychain
- (void)saveCredentialsToKeychain:(NSMutableDictionary *)newCredentials;

// Save creddentials to the keychain
+ (void)saveCredentials:(NSURLCredential *)credentials forHost:(NSString *)host port:(int)port protocol:(NSString *)protocol realm:(NSString *)realm;

// Return credentials from the keychain
+ (NSURLCredential *)savedCredentialsForHost:(NSString *)host port:(int)port protocol:(NSString *)protocol realm:(NSString *)realm;

// Remove credentials from the keychain
+ (void)removeCredentialsForHost:(NSString *)host port:(int)port protocol:(NSString *)protocol realm:(NSString *)realm;

// We keep track of any cookies we accept, so that we can remove them from the persistent store later
+ (void)setSessionCookies:(NSMutableArray *)newSessionCookies;
+ (NSMutableArray *)sessionCookies;

// Dump all session data (authentication and cookies)
+ (void)clearSession;


@property (retain) NSString *username;
@property (retain) NSString *password;
@property (retain) NSString *domain;

@property (retain,readonly) NSURL *url;
@property (assign) id delegate;
@property (assign) id uploadProgressDelegate;
@property (assign) id downloadProgressDelegate;
@property (assign) BOOL useKeychainPersistance;
@property (assign) BOOL useSessionPersistance;
@property (retain) NSString *downloadDestinationPath;
@property (assign) SEL didFinishSelector;
@property (assign) SEL didFailSelector;
@property (retain,readonly) NSString *authenticationRealm;
@property (retain) NSError *error;
@property (assign,readonly) BOOL complete;
@property (retain) NSDictionary *responseHeaders;
@property (retain) NSMutableArray *requestCookies;
@property (retain) NSArray *responseCookies;
@property (assign) BOOL useCookiePersistance;
@property (retain) NSDictionary *requestCredentials;
@property (assign) int responseStatusCode;
@property (retain) NSMutableData *receivedData;
@property (retain) NSDate *lastActivityTime;
@property (assign) NSTimeInterval timeOutSeconds;
@property (retain) NSString *requestMethod;
@property (retain,setter=setPostBody:) NSData *postBody;
@property (assign) unsigned int contentLength;
@property (assign) unsigned int postLength;
@property (assign) BOOL useCachedContentLength;
@property (retain) ASIHTTPRequest *mainRequest;
@property (assign) BOOL showAccurateProgress;
@end
