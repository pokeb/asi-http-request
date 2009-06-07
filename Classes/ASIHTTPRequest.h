//
//  ASIHTTPRequest.h
//
//  Created by Ben Copsey on 04/10/2007.
//  Copyright 2007-2009 All-Seeing Interactive. All rights reserved.
//
//  A guide to the main features is available at:
//  http://allseeing-i.com/ASIHTTPRequest
//
//  Portions are based on the ImageClient example from Apple:
//  See: http://developer.apple.com/samplecode/ImageClient/listing37.html

#import <Foundation/Foundation.h>
// Dammit, importing frameworks when you are targetting two platforms is a PITA
#if TARGET_OS_IPHONE
	#import <CFNetwork/CFNetwork.h>
#endif
#import <stdio.h>


typedef enum _ASINetworkErrorType {
    ASIConnectionFailureErrorType = 1,
    ASIRequestTimedOutErrorType = 2,
    ASIAuthenticationErrorType = 3,
    ASIRequestCancelledErrorType = 4,
    ASIUnableToCreateRequestErrorType = 5,
    ASIInternalErrorWhileBuildingRequestType  = 6,
    ASIInternalErrorWhileApplyingCredentialsType  = 7,
	ASIFileManagementError = 8
	
} ASINetworkErrorType;

extern NSString* const NetworkRequestErrorDomain;

@interface ASIHTTPRequest : NSOperation {
	
	// The url for this operation, should include GET params in the query string where appropriate
	NSURL *url; 
	
	// The delegate, you need to manage setting and talking to your delegate in your subclasses
	id delegate;
	
	// A queue delegate that should *ALSO* be notified of delegate message (used by ASINetworkQueue)
	id queue;
	
	// HTTP method to use (GET / POST / PUT / DELETE). Defaults to GET
	NSString *requestMethod;
	
	// Request body - only used when the whole body is stored in memory (shouldStreamPostDataFromDisk is false)
	NSMutableData *postBody;
	
	// When true, post body will be streamed from a file on disk, rather than loaded into memory at once (useful for large uploads)
	// Automatically set to true in ASIFormDataRequests when using setFile:forKey:
	BOOL shouldStreamPostDataFromDisk;
	
	// Path to file used to store post body (when shouldStreamPostDataFromDisk is true)
	// You can set this yourself - useful if you want to PUT a file from local disk 
	NSString *postBodyFilePath;
	
	// Set to true when ASIHTTPRequest automatically created a temporary file containing the request body (when true, the file at postBodyFilePath will be deleted at the end of the request)
	BOOL didCreateTemporaryPostDataFile;
	
	// Used when writing to the post body when shouldStreamPostDataFromDisk is true (via appendPostData: or appendPostDataFromFile:)
	NSOutputStream *postBodyWriteStream;
	
	// Used for reading from the post body when sending the request
	NSInputStream *postBodyReadStream;
	
	// Dictionary for custom HTTP request headers
	NSMutableDictionary *requestHeaders;
	
	// Will be populated with HTTP response headers from the server
	NSDictionary *responseHeaders;
	
	// Can be used to manually insert cookie headers to a request, but it's more likely that sessionCookies will do this for you
	NSMutableArray *requestCookies;
	
	// Will be populated with cookies
	NSArray *responseCookies;
	
	// If use useCookiePersistance is true, network requests will present valid cookies from previous requests
	BOOL useCookiePersistance;
	
	// If useKeychainPersistance is true, network requests will attempt to read credentials from the keychain, and will save them in the keychain when they are successfully presented
	BOOL useKeychainPersistance;
	
	// If useSessionPersistance is true, network requests will save credentials and reuse for the duration of the session (until clearSession is called)
	BOOL useSessionPersistance;
	
	// If allowCompressedResponse is true, requests will inform the server they can accept compressed data, and will automatically decompress gzipped responses. Default is true.
	BOOL allowCompressedResponse;
	
	// When downloadDestinationPath is set, the result of this request will be downloaded to the file at this location
	// If downloadDestinationPath is not set, download data will be stored in memory
	NSString *downloadDestinationPath;
	
	//The location that files will be downloaded to. Once a download is complete, files will be decompressed (if necessary) and moved to downloadDestinationPath
	NSString *temporaryFileDownloadPath;
	
	// Used for writing data to a file when downloadDestinationPath is set
	NSOutputStream *fileDownloadOutputStream;
	
	// When the request fails or completes successfully, complete will be true
	BOOL complete;
	
	// If an error occurs, error will contain an NSError
	// If error code is = ASIConnectionFailureErrorType (1, Connection failure occurred) - inspect [[error userInfo] objectForKey:NSUnderlyingErrorKey] for more information
	NSError *error;
	
	// Username and password used for authentication
	NSString *username;
	NSString *password;
	
	// Domain used for NTLM authentication
	NSString *domain;
	
	// Delegate for displaying upload progress (usually an NSProgressIndicator, but you can supply a different object and handle this yourself)
	id uploadProgressDelegate;
	
	// Delegate for displaying download progress (usually an NSProgressIndicator, but you can supply a different object and handle this yourself)
	id downloadProgressDelegate;
	
	// Whether we've seen the headers of the response yet
    BOOL haveExaminedHeaders;
	
	// Data we receive will be stored here. Data may be compressed unless allowCompressedResponse is false - you should use [request responseData] instead in most cases
	NSMutableData *rawResponseData;
	
	// Used for sending and receiving data
    CFHTTPMessageRef request;	
	CFReadStreamRef readStream;
	
	// Authentication currently being used for prompting and resuming
    CFHTTPAuthenticationRef requestAuthentication; 
	NSMutableDictionary *requestCredentials;
	int authenticationRetryCount;
	NSString *authenticationMethod;
	
	// HTTP status code, eg: 200 = OK, 404 = Not found etc
	int responseStatusCode;
	
	// Size of the response
	unsigned long long contentLength;
	
	// Size of the partially downloaded content
	unsigned long long partialDownloadSize;
	
	// Size of the POST payload
	unsigned long long postLength;	
	
	// The total amount of downloaded data
	unsigned long long totalBytesRead;
	
	// The total amount of uploaded data
	unsigned long long totalBytesSent;
	
	// Last amount of data read (used for incrementing progress)
	unsigned long long lastBytesRead;
	
	// Last amount of data sent (used for incrementing progress)
	unsigned long long lastBytesSent;
	
	// Realm for authentication when credentials are required
	NSString *authenticationRealm;
	
	// This lock will block the request until the delegate supplies authentication info
	NSConditionLock *authenticationLock;
	
	// This lock prevents the operation from being cancelled at an inopportune moment
	NSLock *cancelledLock;
	
	// Called on the delegate when the request completes successfully
	SEL didFinishSelector;
	
	// Called on the delegate when the request fails
	SEL didFailSelector;
	
	// Used for recording when something last happened during the request, we will compare this value with the current date to time out requests when appropriate
	NSDate *lastActivityTime;
	
	// Number of seconds to wait before timing out - default is 10
	NSTimeInterval timeOutSeconds;
	
	// Autorelease pool for the main loop, since it's highly likely that this operation will run in a thread
	NSAutoreleasePool *pool;
	
	// Will be YES when a HEAD request will handle the content-length before this request starts
	BOOL shouldResetProgressIndicators;
	
	// Used by HEAD requests when showAccurateProgress is YES to preset the content-length for this request
	ASIHTTPRequest *mainRequest;
	
	// When NO, this request will only update the progress indicator when it completes
	// When YES, this request will update the progress indicator according to how much data it has received so far
	// The default for requests is YES
	// Also see the comments in ASINetworkQueue.h
	BOOL showAccurateProgress;
	
	// Used to ensure the progress indicator is only incremented once when showAccurateProgress = NO
	BOOL updatedProgress;
	
	// Prevents the body of the post being built more than once (largely for subclasses)
	BOOL haveBuiltPostBody;
	
	unsigned long long uploadBufferSize;
	
	NSStringEncoding defaultResponseEncoding;
	NSStringEncoding responseEncoding;
	
	BOOL allowResumeForFileDownloads;
	
	// Custom user information assosiated with the request
	NSDictionary *userInfo;
	
	// Use HTTP 1.0 rather than 1.1 (defaults to false)
	BOOL useHTTPVersionOne;
	
	// When YES, requests will automatically redirect when they get a HTTP 30x header (defaults to YES)
	BOOL shouldRedirect;
	
	// When NO, requests will not check the secure certificate is valid (use for self-signed cerficates during development, DO NOT USE IN PRODUCTION) Default is YES
	BOOL validatesSecureCertificate;

}

#pragma mark init / dealloc

// Should be an HTTP or HTTPS url, may include username and password if appropriate
- (id)initWithURL:(NSURL *)newURL;

// Convenience constructor
+ (id)requestWithURL:(NSURL *)newURL;

#pragma mark setup request

// Add a custom header to the request
- (void)addRequestHeader:(NSString *)header value:(NSString *)value;

- (void)buildPostBody;

// Called to add data to the post body. Will append to postBody when shouldStreamPostDataFromDisk is false, or write to postBodyWriteStream when true
- (void)appendPostData:(NSData *)data;
- (void)appendPostDataFromFile:(NSString *)file;

#pragma mark get information about this request

// Returns the contents of the result as an NSString (not appropriate for binary data - used responseData instead)
- (NSString *)responseString;

// Response data, automatically uncompressed where appropriate
- (NSData *)responseData;

// Returns true if the response was gzip compressed
- (BOOL)isResponseCompressed;

#pragma mark request logic

// Main request loop is in here
- (void)loadRequest;

// Start the read stream. Called by loadRequest, and again to restart the request when authentication is needed
- (void)startRequest;

// Cancel loading and clean up
- (void)cancelLoad;

// Call to delete the temporary file used during a file download (if it exists)
// No need to call this if the request succeeds - it is removed automatically
- (void)removeTemporaryDownloadFile;

// Call to remove the file used as the request body
// No need to call this if the request succeeds and you didn't specify postBodyFilePath manually - it is removed automatically
- (void)removePostDataFile;

#pragma mark upload/download progress

// Called on main thread to update progress delegates
- (void)updateProgressIndicators;
- (void)resetUploadProgress:(unsigned long long)value;
- (void)updateUploadProgress;
- (void)resetDownloadProgress:(unsigned long long)value;
- (void)updateDownloadProgress;

// Called when authorisation is needed, as we only find out we don't have permission to something when the upload is complete
- (void)removeUploadProgressSoFar;

// Helper method for interacting with progress indicators to abstract the details of different APIS (NSProgressIndicator and UIProgressView)
+ (void)setProgress:(double)progress forProgressIndicator:(id)indicator;

#pragma mark handling request complete / failure

// Called when a request completes successfully, lets the delegate now via didFinishSelector
- (void)requestFinished;

// Called when a request fails, and lets the delegate now via didFailSelector
- (void)failWithError:(NSError *)theError;

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

#pragma mark gzip compression

// Uncompress gzipped data with zlib
+ (NSData *)uncompressZippedData:(NSData*)compressedData;

// Uncompress gzipped data from a file into another file, used when downloading to a file
+ (int)uncompressZippedDataFromFile:(NSString *)sourcePath toFile:(NSString *)destinationPath;
+ (int)uncompressZippedDataFromSource:(FILE *)source toDestination:(FILE *)dest;

@property (retain) NSString *username;
@property (retain) NSString *password;
@property (retain) NSString *domain;

@property (retain,readonly) NSURL *url;
@property (assign) id delegate;
@property (assign) id queue;
@property (assign) id uploadProgressDelegate;
@property (assign) id downloadProgressDelegate;
@property (assign) BOOL useKeychainPersistance;
@property (assign) BOOL useSessionPersistance;
@property (retain) NSString *downloadDestinationPath;
@property (retain) NSString *temporaryFileDownloadPath;
@property (assign) SEL didFinishSelector;
@property (assign) SEL didFailSelector;
@property (retain,readonly) NSString *authenticationRealm;
@property (retain) NSError *error;
@property (assign,readonly) BOOL complete;
@property (retain,readonly) NSDictionary *responseHeaders;
@property (retain) NSMutableDictionary *requestHeaders;
@property (retain) NSMutableArray *requestCookies;
@property (retain,readonly) NSArray *responseCookies;
@property (assign) BOOL useCookiePersistance;
@property (retain) NSDictionary *requestCredentials;
@property (assign,readonly) int responseStatusCode;
@property (retain,readonly) NSMutableData *rawResponseData;
@property (assign) NSTimeInterval timeOutSeconds;
@property (retain) NSString *requestMethod;
@property (retain) NSMutableData *postBody;
@property (assign,readonly) unsigned long long contentLength;
@property (assign) unsigned long long postLength;
@property (assign) BOOL shouldResetProgressIndicators;
@property (retain) ASIHTTPRequest *mainRequest;
@property (assign) BOOL showAccurateProgress;
@property (assign,readonly) unsigned long long totalBytesRead;
@property (assign,readonly) unsigned long long totalBytesSent;
@property (assign) NSStringEncoding defaultResponseEncoding;
@property (assign,readonly) NSStringEncoding responseEncoding;
@property (assign) BOOL allowCompressedResponse;
@property (assign) BOOL allowResumeForFileDownloads;
@property (retain) NSDictionary *userInfo;
@property (retain) NSString *postBodyFilePath;
@property (assign) BOOL shouldStreamPostDataFromDisk;
@property (assign) BOOL didCreateTemporaryPostDataFile;
@property (assign) BOOL useHTTPVersionOne;
@property (assign, readonly) unsigned long long partialDownloadSize;
@property (assign) BOOL shouldRedirect;
@property (assign) BOOL validatesSecureCertificate;
@end
