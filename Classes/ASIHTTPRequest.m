//
//  ASIHTTPRequest.m
//
//  Created by Ben Copsey on 04/10/2007.
//  Copyright 2007-2009 All-Seeing Interactive. All rights reserved.
//
//  A guide to the main features is available at:
//  http://allseeing-i.com/ASIHTTPRequest
//
//  Portions are based on the ImageClient example from Apple:
//  See: http://developer.apple.com/samplecode/ImageClient/listing37.html

#import "ASIHTTPRequest.h"
#import <zlib.h>
#if TARGET_OS_IPHONE
#import "Reachability.h"
#else
#import <SystemConfiguration/SystemConfiguration.h>
#endif
#import "ASIInputStream.h"

// We use our own custom run loop mode as CoreAnimation seems to want to hijack our threads otherwise
static CFStringRef ASIHTTPRequestRunMode = CFSTR("ASIHTTPRequest");

NSString* const NetworkRequestErrorDomain = @"ASIHTTPRequestErrorDomain";

static const CFOptionFlags kNetworkEvents = kCFStreamEventOpenCompleted | kCFStreamEventHasBytesAvailable | kCFStreamEventEndEncountered | kCFStreamEventErrorOccurred;

static CFHTTPAuthenticationRef sessionAuthentication = NULL;
static NSMutableDictionary *sessionCredentials = nil;

static CFHTTPAuthenticationRef sessionProxyAuthentication = NULL;
static NSMutableDictionary *sessionProxyCredentials = nil;

static NSMutableArray *sessionCookies = nil;

// The number of times we will allow requests to redirect before we fail with a redirection error
const int RedirectionLimit = 5;

static void ReadStreamClientCallBack(CFReadStreamRef readStream, CFStreamEventType type, void *clientCallBackInfo) {
    [((ASIHTTPRequest*)clientCallBackInfo) handleNetworkEvent: type];
}

// This lock prevents the operation from being cancelled while it is trying to update the progress, and vice versa
static NSRecursiveLock *progressLock;

static NSError *ASIRequestCancelledError;
static NSError *ASIRequestTimedOutError;
static NSError *ASIAuthenticationError;
static NSError *ASIUnableToCreateRequestError;
static NSError *ASITooMuchRedirectionError;

static NSMutableArray *bandwidthUsageTracker = nil;
static unsigned long averageBandwidthUsedPerSecond = 0;

// Records how much bandwidth all requests combined have used in the last second
static unsigned long bandwidthUsedInLastSecond = 0; 

// A date one second in the future from the time it was created
static NSDate *bandwidthMeasurementDate = nil;

// Since throttling variables are shared among all requests, we'll use a lock to mediate access
static NSLock *bandwidthThrottlingLock = nil;

// the maximum number of bytes that can be transmitted in one second
static unsigned long maxBandwidthPerSecond = 0;

// A default figure for throttling bandwidth on mobile devices
unsigned long const ASIWWANBandwidthThrottleAmount = 14800;

// YES when bandwidth throttling is active
// This flag does not denote whether throttling is turned on - rather whether it is currently in use
// It will be set to NO when throttling was turned on with setShouldThrottleBandwidthForWWAN, but a WI-FI connection is active
BOOL isBandwidthThrottled = NO;

BOOL shouldThrottleBandwithForWWANOnly = NO;

static NSLock *sessionCookiesLock = nil;

// Private stuff
@interface ASIHTTPRequest ()

- (BOOL)askDelegateForCredentials;
- (BOOL)askDelegateForProxyCredentials;
+ (void)measureBandwidthUsage;
+ (void)recordBandwidthUsage;

@property (assign) BOOL complete;
@property (retain) NSDictionary *responseHeaders;
@property (retain) NSArray *responseCookies;
@property (assign) int responseStatusCode;
@property (retain) NSMutableData *rawResponseData;
@property (retain, nonatomic) NSDate *lastActivityTime;
@property (assign) unsigned long long contentLength;
@property (assign) unsigned long long partialDownloadSize;
@property (assign, nonatomic) unsigned long long uploadBufferSize;
@property (assign) NSStringEncoding responseEncoding;
@property (retain, nonatomic) NSOutputStream *postBodyWriteStream;
@property (retain, nonatomic) NSInputStream *postBodyReadStream;
@property (assign) unsigned long long totalBytesRead;
@property (assign) unsigned long long totalBytesSent;
@property (assign, nonatomic) unsigned long long lastBytesRead;
@property (assign, nonatomic) unsigned long long lastBytesSent;
@property (retain) NSLock *cancelledLock;
@property (assign, nonatomic) BOOL haveBuiltPostBody;
@property (retain, nonatomic) NSOutputStream *fileDownloadOutputStream;
@property (assign, nonatomic) int authenticationRetryCount;
@property (assign, nonatomic) int proxyAuthenticationRetryCount;
@property (assign, nonatomic) BOOL updatedProgress;
@property (assign, nonatomic) BOOL needsRedirect;
@property (assign, nonatomic) int redirectCount;
@property (retain, nonatomic) NSData *compressedPostBody;
@property (retain, nonatomic) NSString *compressedPostBodyFilePath;
@property (retain) NSConditionLock *authenticationLock;
@property (retain) NSString *authenticationRealm;
@property (retain) NSString *proxyAuthenticationRealm;

@end


@implementation ASIHTTPRequest



#pragma mark init / dealloc

+ (void)initialize
{
	if (self == [ASIHTTPRequest class]) {
		progressLock = [[NSRecursiveLock alloc] init];
		bandwidthThrottlingLock = [[NSLock alloc] init];
		sessionCookiesLock = [[NSLock alloc] init];
		bandwidthUsageTracker = [[NSMutableArray alloc] initWithCapacity:5];
		ASIRequestTimedOutError = [[NSError errorWithDomain:NetworkRequestErrorDomain code:ASIRequestTimedOutErrorType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"The request timed out",NSLocalizedDescriptionKey,nil]] retain];	
		ASIAuthenticationError = [[NSError errorWithDomain:NetworkRequestErrorDomain code:ASIAuthenticationErrorType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Authentication needed",NSLocalizedDescriptionKey,nil]] retain];
		ASIRequestCancelledError = [[NSError errorWithDomain:NetworkRequestErrorDomain code:ASIRequestCancelledErrorType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"The request was cancelled",NSLocalizedDescriptionKey,nil]] retain];
		ASIUnableToCreateRequestError = [[NSError errorWithDomain:NetworkRequestErrorDomain code:ASIUnableToCreateRequestErrorType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unable to create request (bad url?)",NSLocalizedDescriptionKey,nil]] retain];
		ASITooMuchRedirectionError = [[NSError errorWithDomain:NetworkRequestErrorDomain code:ASITooMuchRedirectionErrorType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"The request failed because it redirected too many times",NSLocalizedDescriptionKey,nil]] retain];	

	}
	[super initialize];
}


- (id)initWithURL:(NSURL *)newURL
{
	self = [super init];
	[self setRequestMethod:@"GET"];

	[self setShouldRedirect:YES];
	[self setShowAccurateProgress:YES];
	[self setShouldResetProgressIndicators:YES];
	[self setAllowCompressedResponse:YES];
	[self setDefaultResponseEncoding:NSISOLatin1StringEncoding];
	
	[self setTimeOutSeconds:10];
	[self setUseSessionPersistance:YES];
	[self setUseCookiePersistance:YES];
	[self setValidatesSecureCertificate:YES];
	[self setRequestCookies:[[[NSMutableArray alloc] init] autorelease]];
	[self setDidFinishSelector:@selector(requestFinished:)];
	[self setDidFailSelector:@selector(requestFailed:)];
	[self setURL:newURL];
	[self setCancelledLock:[[[NSLock alloc] init] autorelease]];
	return self;
}

+ (id)requestWithURL:(NSURL *)newURL
{
	return [[[self alloc] initWithURL:newURL] autorelease];
}

- (void)dealloc
{
	if (requestAuthentication) {
		CFRelease(requestAuthentication);
	}
	if (proxyAuthentication) {
		CFRelease(proxyAuthentication);
	}
	if (request) {
		CFRelease(request);
	}
	[self cancelLoad];
	[userInfo release];
	[mainRequest release];
	[postBody release];
	[compressedPostBody release];
	[error release];
	[requestHeaders release];
	[requestCookies release];
	[downloadDestinationPath release];
	[temporaryFileDownloadPath release];
	[fileDownloadOutputStream release];
	[username release];
	[password release];
	[domain release];
	[authenticationRealm release];
	[authenticationMethod release];
	[requestCredentials release];
	[proxyHost release];
	[proxyUsername release];
	[proxyPassword release];
	[proxyDomain release];
	[proxyAuthenticationRealm release];
	[proxyAuthenticationMethod release];
	[proxyCredentials release];
	[url release];
	[authenticationLock release];
	[lastActivityTime release];
	[responseCookies release];
	[rawResponseData release];
	[responseHeaders release];
	[requestMethod release];
	[cancelledLock release];
	[postBodyFilePath release];
	[compressedPostBodyFilePath release];
	[postBodyWriteStream release];
	[postBodyReadStream release];
	[PACurl release];
	[super dealloc];
}


#pragma mark setup request

- (void)addRequestHeader:(NSString *)header value:(NSString *)value
{
	if (!requestHeaders) {
		[self setRequestHeaders:[NSMutableDictionary dictionaryWithCapacity:1]];
	}
	[requestHeaders setObject:value forKey:header];
}

// This function will be called either just before a request starts, or when postLength is needed, whichever comes first
// postLength must be set by the time this function is complete
- (void)buildPostBody
{
	// Are we submitting the request body from a file on disk
	if ([self postBodyFilePath]) {
		
		// If we were writing to the post body via appendPostData or appendPostDataFromFile, close the write stream
		if ([self postBodyWriteStream]) {
			[[self postBodyWriteStream] close];
			[self setPostBodyWriteStream:nil];
		}

		if ([self shouldCompressRequestBody]) {
			[self setCompressedPostBodyFilePath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]]];
			[ASIHTTPRequest compressDataFromFile:[self postBodyFilePath] toFile:[self compressedPostBodyFilePath]];
			[self setPostLength:[[[NSFileManager defaultManager] fileAttributesAtPath:[self compressedPostBodyFilePath] traverseLink:NO] fileSize]];
		} else {
			[self setPostLength:[[[NSFileManager defaultManager] fileAttributesAtPath:[self postBodyFilePath] traverseLink:NO] fileSize]];
		}
		
	// Otherwise, we have an in-memory request body
	} else {
		if ([self shouldCompressRequestBody]) {
			[self setCompressedPostBody:[ASIHTTPRequest compressData:[self postBody]]];
			[self setPostLength:[[self compressedPostBody] length]];
		} else {
			[self setPostLength:[[self postBody] length]];
		}
	}
		
	if ([self postLength] > 0) {
		if (![requestMethod isEqualToString:@"POST"] && ![requestMethod isEqualToString:@"PUT"]) {
			[self setRequestMethod:@"POST"];
		}
		[self addRequestHeader:@"Content-Length" value:[NSString stringWithFormat:@"%llu",[self postLength]]];
	}
	[self setHaveBuiltPostBody:YES];
}

// Sets up storage for the post body
- (void)setupPostBody
{
	if ([self shouldStreamPostDataFromDisk]) {
		if (![self postBodyFilePath]) {
			[self setPostBodyFilePath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]]];
			[self setDidCreateTemporaryPostDataFile:YES];
		}
		if (![self postBodyWriteStream]) {
			[self setPostBodyWriteStream:[[[NSOutputStream alloc] initToFileAtPath:[self postBodyFilePath] append:NO] autorelease]];
			[[self postBodyWriteStream] open];
		}
	} else {
		if (![self postBody]) {
			[self setPostBody:[[[NSMutableData alloc] init] autorelease]];
		}
	}	
}

- (void)appendPostData:(NSData *)data
{
	[self setupPostBody];
	if ([data length] == 0) {
		return;
	}
	if ([self shouldStreamPostDataFromDisk]) {
		[[self postBodyWriteStream] write:[data bytes] maxLength:[data length]];
	} else {
		[[self postBody] appendData:data];
	}
}

- (void)appendPostDataFromFile:(NSString *)file
{
	[self setupPostBody];
	NSInputStream *stream = [[[NSInputStream alloc] initWithFileAtPath:file] autorelease];
	[stream open];
	int bytesRead;
	while ([stream hasBytesAvailable]) {
		
		unsigned char buffer[1024*256];
		bytesRead = [stream read:buffer maxLength:sizeof(buffer)];
		if (bytesRead == 0) {
			break;
		}
		if ([self shouldStreamPostDataFromDisk]) {
			[[self postBodyWriteStream] write:buffer maxLength:bytesRead];
		} else {
			[[self postBody] appendData:[NSData dataWithBytes:buffer length:bytesRead]];
		}
	}
	[stream close];
}

#pragma mark get information about this request

- (BOOL)isFinished 
{
	return [self complete];
}


- (void)cancel
{
	// Request may already be complete
	if ([self complete] || [self isCancelled]) {
		return;
	}
	[self failWithError:ASIRequestCancelledError];
	[super cancel];
	[self cancelLoad];
	[self setComplete:YES];

}


// Call this method to get the received data as an NSString. Don't use for binary data!
- (NSString *)responseString
{
	NSData *data = [self responseData];
	if (!data) {
		return nil;
	}
	
	return [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:[self responseEncoding]] autorelease];
}

- (BOOL)isResponseCompressed
{
	NSString *encoding = [[self responseHeaders] objectForKey:@"Content-Encoding"];
	return encoding && [encoding rangeOfString:@"gzip"].location != NSNotFound;
}

- (NSData *)responseData
{	
	if ([self isResponseCompressed]) {
		return [ASIHTTPRequest uncompressZippedData:[self rawResponseData]];
	} else {
		return [self rawResponseData];
	}
}


#pragma mark request logic

// Create the request
- (void)main
{
	
	[pool release];
	pool = [[NSAutoreleasePool alloc] init];
	
	[self setComplete:NO];
	
	if (![self url]) {
		[self failWithError:ASIUnableToCreateRequestError];
		return;		
	}
	
	if (![self haveBuiltPostBody]) {
		[self buildPostBody];
	}
	
	// If we're redirecting, we'll already have a CFHTTPMessageRef
	if (request) {
		CFRelease(request);
	}
	
    // Create a new HTTP request.
	request = CFHTTPMessageCreateRequest(kCFAllocatorDefault, (CFStringRef)[self requestMethod], (CFURLRef)[self url], [self useHTTPVersionOne] ? kCFHTTPVersion1_0 : kCFHTTPVersion1_1);
    if (!request) {
		[self failWithError:ASIUnableToCreateRequestError];
		return;
    }
	
	
	// If we've already talked to this server and have valid credentials, let's apply them to the request
	if ([self useSessionPersistance]) {
		if (sessionCredentials && sessionAuthentication) {
			if (!CFHTTPMessageApplyCredentialDictionary(request, sessionAuthentication, (CFMutableDictionaryRef)sessionCredentials, NULL)) {
				[ASIHTTPRequest setSessionAuthentication:NULL];
				[ASIHTTPRequest setSessionCredentials:nil];
			}
		}
	}
	
	// Add cookies from the persistant (mac os global) store
	if ([self useCookiePersistance] ) {
		NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[self url]];
		if (cookies) {
			[[self requestCookies] addObjectsFromArray:cookies];
		}
	}
	
	// Apply request cookies
	NSArray *cookies;
	if ([self mainRequest]) {
		cookies = [[self mainRequest] requestCookies];
	} else {
		cookies = [self requestCookies];
	}
	if ([cookies count] > 0) {
		NSHTTPCookie *cookie;
		NSString *cookieHeader = nil;
		for (cookie in cookies) {
			if (!cookieHeader) {
				cookieHeader = [NSString stringWithFormat: @"%@=%@",[cookie name],[cookie value]];
			} else {
				cookieHeader = [NSString stringWithFormat: @"%@; %@=%@",cookieHeader,[cookie name],[cookie value]];
			}
		}
		if (cookieHeader) {
			[self addRequestHeader:@"Cookie" value:cookieHeader];
		}
	}
	
	// Build and set the user agent string if the request does not already have a custom user agent specified
	if (![[self requestHeaders] objectForKey:@"User-Agent"]) {
		NSString *userAgentString = [ASIHTTPRequest defaultUserAgentString];
		if (userAgentString) {
			[self addRequestHeader:@"User-Agent" value:userAgentString];
		}
	}

	
	// Accept a compressed response
	if ([self allowCompressedResponse]) {
		[self addRequestHeader:@"Accept-Encoding" value:@"gzip"];
	}
	
	// Configure a compressed request body
	if ([self shouldCompressRequestBody]) {
		[self addRequestHeader:@"Content-Encoding" value:@"gzip"];
	}
	
	// Should this request resume an existing download?
	if ([self allowResumeForFileDownloads] && [self downloadDestinationPath] && [self temporaryFileDownloadPath] && [[NSFileManager defaultManager] fileExistsAtPath:[self temporaryFileDownloadPath]]) {
		[self setPartialDownloadSize:[[[NSFileManager defaultManager] fileAttributesAtPath:[self temporaryFileDownloadPath] traverseLink:NO] fileSize]];
		[self addRequestHeader:@"Range" value:[NSString stringWithFormat:@"bytes=%llu-",[self partialDownloadSize]]];
	}
	
	// Add custom headers
	NSDictionary *headers;
	
	//Add headers from the main request if this is a HEAD request generated by an ASINetworkQueue
	if ([self mainRequest]) {
		headers = [mainRequest requestHeaders];
	} else {
		headers = [self requestHeaders];
	}	
	NSString *header;
	for (header in headers) {
		CFHTTPMessageSetHeaderFieldValue(request, (CFStringRef)header, (CFStringRef)[[self requestHeaders] objectForKey:header]);
	}
	
	[self loadRequest];
	
}

- (void)startRequest
{
	[[self cancelledLock] lock];
	
	if ([self isCancelled]) {
		[[self cancelledLock] unlock];
		return;
	}
	
	[self setAuthenticationLock:[[[NSConditionLock alloc] initWithCondition:1] autorelease]];
	
	[self setComplete:NO];
	[self setTotalBytesRead:0];
	[self setLastBytesRead:0];
	
	// If we're retrying a request after an authentication failure, let's remove any progress we made
	if ([self lastBytesSent] > 0) {
		[self removeUploadProgressSoFar];
	}
	
	[self setLastBytesSent:0];
	if ([self shouldResetProgressIndicators]) {
		[self setContentLength:0];
		[self resetDownloadProgress:0];
	}
	[self setResponseHeaders:nil];
	if (![self downloadDestinationPath]) {
		[self setRawResponseData:[[[NSMutableData alloc] init] autorelease]];
    }
    // Create the stream for the request
	
	// Do we need to stream the request body from disk
	if ([self shouldStreamPostDataFromDisk] && [self postBodyFilePath] && [[NSFileManager defaultManager] fileExistsAtPath:[self postBodyFilePath]]) {
		
		// Are we gzipping the request body?
		if ([self compressedPostBodyFilePath] && [[NSFileManager defaultManager] fileExistsAtPath:[self compressedPostBodyFilePath]]) {
			[self setPostBodyReadStream:[ASIInputStream inputStreamWithFileAtPath:[self compressedPostBodyFilePath]]];
		} else {
			[self setPostBodyReadStream:[ASIInputStream inputStreamWithFileAtPath:[self postBodyFilePath]]];
		}
		readStream = CFReadStreamCreateForStreamedHTTPRequest(kCFAllocatorDefault, request,(CFReadStreamRef)[self postBodyReadStream]);
    } else {
		
		// If we have a request body, we'll stream it from memory using our custom stream, so that we can measure bandwidth use and it can be bandwidth-throttled if nescessary
		if ([self postBody]) {
			if ([self shouldCompressRequestBody] && [self compressedPostBody]) {
				[self setPostBodyReadStream:[ASIInputStream inputStreamWithData:[self compressedPostBody]]];
			} else if ([self postBody]) {
				[self setPostBodyReadStream:[ASIInputStream inputStreamWithData:[self postBody]]];
			}
			readStream = CFReadStreamCreateForStreamedHTTPRequest(kCFAllocatorDefault, request,(CFReadStreamRef)[self postBodyReadStream]);
		
		} else {
			readStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, request);
		}
	}
	if (!readStream) {
		[[self cancelledLock] unlock];
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:ASIInternalErrorWhileBuildingRequestType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unable to create read stream",NSLocalizedDescriptionKey,nil]]];
        return;
    }

	// Tell CFNetwork not to validate SSL certificates
	if (!validatesSecureCertificate) {
		CFReadStreamSetProperty(readStream, kCFStreamPropertySSLSettings, [NSMutableDictionary dictionaryWithObject:(NSString *)kCFBooleanFalse forKey:(NSString *)kCFStreamSSLValidatesCertificateChain]); 
	}
	
	
	// Handle proxy settings

	// Have details of the proxy been set on this request
	if (![self proxyHost] && ![self proxyPort]) {
		
		// If not, we need to figure out what they'll be
		
		NSArray *proxies = nil;
		
		// Have we been given a proxy auto config file?
		if ([self PACurl]) {
			
			proxies = [ASIHTTPRequest proxiesForURL:[self url] fromPAC:[self PACurl]];

		// Detect proxy settings and apply them	
		} else {
		
			#if TARGET_OS_IPHONE
			#if !defined(TARGET_IPHONE_SIMULATOR) || __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_2_2
			NSDictionary *proxySettings = [(NSDictionary *)CFNetworkCopySystemProxySettings() autorelease];
			#else
			// Can't detect proxies in 2.2.1 Simulator
			NSDictionary *proxySettings = [NSMutableDictionary dictionary];	
			#endif
			#else
			NSDictionary *proxySettings = [(NSDictionary *)SCDynamicStoreCopyProxies(NULL) autorelease];
			#endif

			proxies = [(NSArray *)CFNetworkCopyProxiesForURL((CFURLRef)[self url], (CFDictionaryRef)proxySettings) autorelease];
			
			// Now check to see if the proxy settings contained a PAC url, we need to run the script to get the real list of proxies if so
			NSDictionary *settings = [proxies objectAtIndex:0];
			if ([settings objectForKey:(NSString *)kCFProxyAutoConfigurationURLKey]) {
				proxies = [ASIHTTPRequest proxiesForURL:[self url] fromPAC:[settings objectForKey:(NSString *)kCFProxyAutoConfigurationURLKey]];
			}
		}
		
		if (!proxies) {
			CFRelease(readStream);
			readStream = NULL;
			[[self cancelledLock] unlock];
			[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:ASIInternalErrorWhileBuildingRequestType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unable to obtain information on proxy servers needed for request",NSLocalizedDescriptionKey,nil]]];
			return;			
		}
		// I don't really understand why the dictionary returned by CFNetworkCopyProxiesForURL uses different key names from CFNetworkCopySystemProxySettings/SCDynamicStoreCopyProxies
		// and why its key names are documented while those we actually need to use don't seem to be (passing the kCF* keys doesn't seem to work)
		if ([proxies count] > 0) {
			NSDictionary *settings = [proxies objectAtIndex:0];
			[self setProxyHost:[settings objectForKey:(NSString *)kCFProxyHostNameKey]];
			[self setProxyPort:[[settings objectForKey:(NSString *)kCFProxyPortNumberKey] intValue]];
		}
	}
	if ([self proxyHost] && [self proxyPort]) {
		NSMutableDictionary *proxyToUse = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self proxyHost],kCFStreamPropertyHTTPProxyHost,[NSNumber numberWithInt:[self proxyPort]],kCFStreamPropertyHTTPProxyPort,nil];
		CFReadStreamSetProperty(readStream, kCFStreamPropertyHTTPProxy, proxyToUse);
	}
	
    // Set the client
	CFStreamClientContext ctxt = {0, self, NULL, NULL, NULL};
    if (!CFReadStreamSetClient(readStream, kNetworkEvents, ReadStreamClientCallBack, &ctxt)) {
        CFRelease(readStream);
        readStream = NULL;
		[[self cancelledLock] unlock];
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:ASIInternalErrorWhileBuildingRequestType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unable to setup read stream",NSLocalizedDescriptionKey,nil]]];
        return;
    }
    
    // Schedule the stream
    CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), ASIHTTPRequestRunMode);
    
    // Start the HTTP connection
    if (!CFReadStreamOpen(readStream)) {
        CFReadStreamSetClient(readStream, 0, NULL, NULL);
        CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), ASIHTTPRequestRunMode);
        CFRelease(readStream);
        readStream = NULL;
		[[self cancelledLock] unlock];
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:ASIInternalErrorWhileBuildingRequestType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unable to start HTTP connection",NSLocalizedDescriptionKey,nil]]];
        return;
    }
	[[self cancelledLock] unlock];
	
	
	if (shouldResetProgressIndicators) {
		double amount = 1;
		if (showAccurateProgress) {
			amount = postLength;
		}
		[self resetUploadProgress:amount];
	}	
	// Record when the request started, so we can timeout if nothing happens
	[self setLastActivityTime:[NSDate date]];	
}

// This is the 'main loop' for the request. Basically, it runs the runloop that our network stuff is attached to, and checks to see if we should cancel or timeout
- (void)loadRequest
{
	[self startRequest];
	

	// Wait for the request to finish
	while (!complete) {
		
		// This may take a while, so we'll release the pool each cycle to stop a giant backlog of autoreleased objects building up
		[pool release];
		pool = [[NSAutoreleasePool alloc] init];
		
		NSDate *now = [NSDate date];
		
		// See if we need to timeout
		if (lastActivityTime && timeOutSeconds > 0 && [now timeIntervalSinceDate:lastActivityTime] > timeOutSeconds) {
			
			// Prevent timeouts before 128KB* has been sent when the size of data to upload is greater than 128KB* (*32KB on iPhone 3.0 SDK)
			// This is to workaround the fact that kCFStreamPropertyHTTPRequestBytesWrittenCount is the amount written to the buffer, not the amount actually sent
			// This workaround prevents erroneous timeouts in low bandwidth situations (eg iPhone)
			if (totalBytesSent || postLength <= uploadBufferSize || (uploadBufferSize > 0 && totalBytesSent > uploadBufferSize)) {
				[self failWithError:ASIRequestTimedOutError];
				[self cancelLoad];
				[self setComplete:YES];
				break;
			}
		}
		
		// Do we need to redirect?
		if ([self needsRedirect]) {
			[self cancelLoad];
			[self setNeedsRedirect:NO];
			[self setRedirectCount:[self redirectCount]+1];
			if ([self redirectCount] > RedirectionLimit) {
				// Some naughty / badly coded website is trying to force us into a redirection loop. This is not cool.
				[self failWithError:ASITooMuchRedirectionError];
				[self setComplete:YES];
			} else {
				// Go all the way back to the beginning and build the request again, so that we can apply any new cookies
				[self main];
			}
			break;
		}
		
		// See if our NSOperationQueue told us to cancel
		if ([self isCancelled]) {
			break;
		}
		
		// Find out if we've sent any more data than last time, and reset the timeout if so
		if (totalBytesSent > lastBytesSent) {
			[self setLastActivityTime:[NSDate date]];
			[self setLastBytesSent:totalBytesSent];
		}
		
		// Find out how much data we've uploaded so far
		[[self cancelledLock] lock];
		[self setTotalBytesSent:[[(NSNumber *)CFReadStreamCopyProperty(readStream, kCFStreamPropertyHTTPRequestBytesWrittenCount) autorelease] unsignedLongLongValue]];
		[[self cancelledLock] unlock];
		
		[self updateProgressIndicators];
		
		// Measure bandwidth used, and throttle if nescessary
		[ASIHTTPRequest measureBandwidthUsage];
		
		// This thread should wait for 1/4 second for the stream to do something. We'll stop early if it does.
		CFRunLoopRunInMode(ASIHTTPRequestRunMode,0,YES);
	}
	
	[pool release];
	pool = nil;
}

// Cancel loading and clean up
- (void)cancelLoad
{
	[[self cancelledLock] lock];
    if (readStream) {
        CFReadStreamClose(readStream);
        CFReadStreamSetClient(readStream, kCFStreamEventNone, NULL, NULL);
        CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), ASIHTTPRequestRunMode);
        CFRelease(readStream);
        readStream = NULL;
    }
	
	[[self postBodyReadStream] close];
	
    if (rawResponseData) {
		[self setRawResponseData:nil];
	
	// If we were downloading to a file
	} else if (temporaryFileDownloadPath) {
		[fileDownloadOutputStream close];
		
		// If we haven't said we might want to resume, let's remove the temporary file too
		if (![self allowResumeForFileDownloads]) {
			[[NSFileManager defaultManager] removeItemAtPath:temporaryFileDownloadPath error:NULL];
		}
	}
	
	// Clean up any temporary file used to store request body for streaming
	if ([self didCreateTemporaryPostDataFile]) {
		[self removePostDataFile];
	}
	
	[self setResponseHeaders:nil];
	[[self cancelledLock] unlock];
}


- (void)removeTemporaryDownloadFile
{
	if (temporaryFileDownloadPath) {
		NSError *removeError = nil;
		[[NSFileManager defaultManager] removeItemAtPath:temporaryFileDownloadPath error:&removeError];
		if (removeError) {
			[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:ASIFileManagementError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Failed to delete file at %@ with error: %@",temporaryFileDownloadPath,removeError],NSLocalizedDescriptionKey,removeError,NSUnderlyingErrorKey,nil]]];
		}
		[self setTemporaryFileDownloadPath:nil];
	}
}

- (void)removePostDataFile
{
	if ([self postBodyFilePath]) {
		NSError *removeError = nil;
		[[NSFileManager defaultManager] removeItemAtPath:[self postBodyFilePath] error:&removeError];
		if (removeError) {
			[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:ASIFileManagementError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Failed to delete file at %@ with error: %@",[self postBodyFilePath],removeError],NSLocalizedDescriptionKey,removeError,NSUnderlyingErrorKey,nil]]];
		}
		[self setPostBodyFilePath:nil];
	}
	if ([self compressedPostBodyFilePath]) {
		NSError *removeError = nil;
		[[NSFileManager defaultManager] removeItemAtPath:[self compressedPostBodyFilePath] error:&removeError];
		if (removeError) {
			[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:ASIFileManagementError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Failed to delete file at %@ with error: %@",[self compressedPostBodyFilePath],removeError],NSLocalizedDescriptionKey,removeError,NSUnderlyingErrorKey,nil]]];
		}
		[self setCompressedPostBodyFilePath:nil];
	}
}


#pragma mark upload/download progress


- (void)updateProgressIndicators
{
	
	//Only update progress if this isn't a HEAD request used to preset the content-length
	if (!mainRequest) {
		if ([self showAccurateProgress] || ([self complete] && ![self updatedProgress])) {
			[self updateUploadProgress];
			[self updateDownloadProgress];
		}
	}
	
}


- (void)setUploadProgressDelegate:(id)newDelegate
{
	uploadProgressDelegate = newDelegate;
	
	// If the uploadProgressDelegate is an NSProgressIndicator, we set it's MaxValue to 1.0 so we can treat it similarly to UIProgressViews
	SEL selector = @selector(setMaxValue:);
	if ([uploadProgressDelegate respondsToSelector:selector]) {
		double max = 1.0;
		NSMethodSignature *signature = [[uploadProgressDelegate class] instanceMethodSignatureForSelector:selector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setTarget:uploadProgressDelegate];
		[invocation setSelector:selector];
		[invocation setArgument:&max atIndex:2];
		[invocation invoke];
		
	}	
}

- (void)setDownloadProgressDelegate:(id)newDelegate
{
	downloadProgressDelegate = newDelegate;
	
	// If the downloadProgressDelegate is an NSProgressIndicator, we set it's MaxValue to 1.0 so we can treat it similarly to UIProgressViews
	SEL selector = @selector(setMaxValue:);
	if ([downloadProgressDelegate respondsToSelector:selector]) {
		double max = 1.0;
		NSMethodSignature *signature = [[downloadProgressDelegate class] instanceMethodSignatureForSelector:selector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setSelector:@selector(setMaxValue:)];
		[invocation setArgument:&max atIndex:2];
		[invocation invokeWithTarget:downloadProgressDelegate];
	}	
}


- (void)resetUploadProgress:(unsigned long long)value
{
	[progressLock lock];
	
	// Request this request's own upload progress delegate
	if (uploadProgressDelegate) {
		[ASIHTTPRequest setProgress:0 forProgressIndicator:uploadProgressDelegate];
	}
	[progressLock unlock];
}		

- (void)updateUploadProgress
{
	[[self cancelledLock] lock];
	if ([self isCancelled]) {
		[[self cancelledLock] unlock];
		return;
	}
	
	// If this is the first time we've written to the buffer, byteCount will be the size of the buffer (currently seems to be 128KB on both Leopard and iPhone 2.2.1, 32KB on iPhone 3.0)
	// If request body is less than the buffer size, byteCount will be the total size of the request body
	// We will remove this from any progress display, as kCFStreamPropertyHTTPRequestBytesWrittenCount does not tell us how much data has actually be written
	if (totalBytesSent > 0 && uploadBufferSize == 0 && totalBytesSent != postLength) {
		[self setUploadBufferSize:totalBytesSent];
		SEL selector = @selector(setUploadBufferSize:);
		if ([queue respondsToSelector:selector]) {
			NSMethodSignature *signature = nil;
			signature = [[queue class] instanceMethodSignatureForSelector:selector];
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
			[invocation setTarget:queue];
			[invocation setSelector:selector];
			[invocation setArgument:&totalBytesSent atIndex:2];
			[invocation invoke];
		}
	}
	

	
	[[self cancelledLock] unlock];

	if (totalBytesSent == 0) {
		return;
	}
	
		
	// Update the progress queue, if we have one
	SEL selector = @selector(incrementUploadProgressBy:);
	if ([queue respondsToSelector:selector]) {
		unsigned long long value = 0;
		if (showAccurateProgress) {
			if (totalBytesSent == postLength || lastBytesSent > 0) {
				value = totalBytesSent-lastBytesSent;
			} else {
				value = 0;
			}
		} else {
			value = 1;
			[self setUpdatedProgress:YES];
		}
		
		NSMethodSignature *signature = nil;
		signature = [[queue class] instanceMethodSignatureForSelector:selector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setTarget:queue];
		[invocation setSelector:selector];
		[invocation setArgument:&value atIndex:2];
		[invocation invoke];
	}

	// Update this request's own upload progress delegate
	if (uploadProgressDelegate) {
		[ASIHTTPRequest setProgress:(double)(1.0*(totalBytesSent-uploadBufferSize)/(postLength-uploadBufferSize)) forProgressIndicator:uploadProgressDelegate];
		
	}

}


- (void)resetDownloadProgress:(unsigned long long)value
{
	[progressLock lock];	
	
	// Reset download progress for this request in the queue
	SEL selector = @selector(incrementDownloadSizeBy:);
	if ([queue respondsToSelector:selector]) {
		NSMethodSignature *signature = [[queue class] instanceMethodSignatureForSelector:selector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setTarget:queue];
		[invocation setSelector:selector];
		[invocation setArgument:&value atIndex:2];
		[invocation invoke];
	}
	
	// Request this request's own download progress delegate
	if (downloadProgressDelegate) {
		[ASIHTTPRequest setProgress:0 forProgressIndicator:downloadProgressDelegate];
	}
	[progressLock unlock];
}	

- (void)updateDownloadProgress
{
	
	
	// We won't update download progress until we've examined the headers, since we might need to authenticate
	if (responseHeaders) {
		
		unsigned long long bytesReadSoFar = totalBytesRead+partialDownloadSize;

		// We're using a progress queue or compatible controller to handle progress
		SEL selector = @selector(incrementDownloadProgressBy:);
		if ([queue respondsToSelector:@selector(incrementDownloadProgressBy:)]) {
			
			NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
			
			unsigned long long value = 0;
			if ([self showAccurateProgress]) {
				value = bytesReadSoFar-[self lastBytesRead];
			} else {
				value = 1;
				[self setUpdatedProgress:YES];
			}
			
			
			NSMethodSignature *signature = [[queue class] instanceMethodSignatureForSelector:selector];
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
			[invocation setTarget:queue];
			[invocation setSelector:selector];
			[invocation setArgument:&value atIndex:2];
			[invocation invoke];
			
			[thePool release];
		}
			
		if (downloadProgressDelegate && contentLength > 0)  {
			[ASIHTTPRequest setProgress:(double)(1.0*bytesReadSoFar/(contentLength+partialDownloadSize)) forProgressIndicator:downloadProgressDelegate];
		}
		
		[self setLastBytesRead:bytesReadSoFar];
	}
	
}

-(void)removeUploadProgressSoFar
{
	
	// We're using a progress queue or compatible controller to handle progress
	SEL selector = @selector(decrementUploadProgressBy:);
	if ([queue respondsToSelector:selector]) {
		unsigned long long value = 0-lastBytesSent;
		
		NSMethodSignature *signature = [[queue class] instanceMethodSignatureForSelector:selector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setTarget:queue];
		[invocation setSelector:selector];
		[invocation setArgument:&value atIndex:2];
		[invocation invoke];
		
	}
	
	if (uploadProgressDelegate) {
		[ASIHTTPRequest setProgress:0 forProgressIndicator:uploadProgressDelegate];
	}
}


+ (void)setProgress:(double)progress forProgressIndicator:(id)indicator
{

	SEL selector;
	[progressLock lock];
	
	// Cocoa Touch: UIProgressView
	if ([indicator respondsToSelector:@selector(setProgress:)]) {
		selector = @selector(setProgress:);
		NSMethodSignature *signature = [[indicator class] instanceMethodSignatureForSelector:selector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setSelector:selector];
		float progressFloat = (float)progress; // UIProgressView wants a float for the progress parameter
		[invocation setArgument:&progressFloat atIndex:2];

		// If we're running in the main thread, update the progress straight away. Otherwise, it's not that urgent
		[invocation performSelectorOnMainThread:@selector(invokeWithTarget:) withObject:indicator waitUntilDone:[NSThread isMainThread]];

		
	// Cocoa: NSProgressIndicator
	} else if ([indicator respondsToSelector:@selector(setDoubleValue:)]) {
		selector = @selector(setDoubleValue:);
		NSMethodSignature *signature = [[indicator class] instanceMethodSignatureForSelector:selector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setSelector:selector];
		[invocation setArgument:&progress atIndex:2];
		

		[invocation performSelectorOnMainThread:@selector(invokeWithTarget:) withObject:indicator waitUntilDone:[NSThread isMainThread]];
		
	}
	[progressLock unlock];
}


#pragma mark handling request complete / failure

// Subclasses might override this method to process the result in the same thread
// If you do this, don't forget to call [super requestFinished] to let the queue / delegate know we're done
- (void)requestFinished
{
	if ([self error] || [self mainRequest]) {
		return;
	}
	// Let the queue know we are done
	if ([queue respondsToSelector:@selector(requestDidFinish:)]) {
		[queue performSelectorOnMainThread:@selector(requestDidFinish:) withObject:self waitUntilDone:[NSThread isMainThread]];		
	}
	
	// Let the delegate know we are done
	if (didFinishSelector && [delegate respondsToSelector:didFinishSelector]) {
		[delegate performSelectorOnMainThread:didFinishSelector withObject:self waitUntilDone:[NSThread isMainThread]];		
	}
}

// Subclasses might override this method to perform error handling in the same thread
// If you do this, don't forget to call [super failWithError:] to let the queue / delegate know we're done
- (void)failWithError:(NSError *)theError
{
	[self setComplete:YES];
	
	if ([self isCancelled] || [self error]) {
		return;
	}
	
	// If this is a HEAD request created by an ASINetworkQueue or compatible queue delegate, make the main request fail
	if ([self mainRequest]) {
		ASIHTTPRequest *mRequest = [self mainRequest];
		[mRequest setError:theError];

		// Let the queue know something went wrong
		if ([queue respondsToSelector:@selector(requestDidFail:)]) {
			[queue performSelectorOnMainThread:@selector(requestDidFail:) withObject:mRequest waitUntilDone:[NSThread isMainThread]];		
		}
	
	} else {
		[self setError:theError];
		
		// Let the queue know something went wrong
		if ([queue respondsToSelector:@selector(requestDidFail:)]) {
			[queue performSelectorOnMainThread:@selector(requestDidFail:) withObject:self waitUntilDone:[NSThread isMainThread]];		
		}
		
		// Let the delegate know something went wrong
		if (didFailSelector && [delegate respondsToSelector:didFailSelector]) {
			[delegate performSelectorOnMainThread:didFailSelector withObject:self waitUntilDone:[NSThread isMainThread]];	
		}
	}
}

#pragma mark parsing HTTP response headers

- (BOOL)readResponseHeadersReturningAuthenticationFailure
{
	[self setNeedsProxyAuthentication:NO];
	BOOL isAuthenticationChallenge = NO;
	CFHTTPMessageRef headers = (CFHTTPMessageRef)CFReadStreamCopyProperty(readStream, kCFStreamPropertyHTTPResponseHeader);
	if (CFHTTPMessageIsHeaderComplete(headers)) {
		
		CFDictionaryRef headerFields = CFHTTPMessageCopyAllHeaderFields(headers);
		[self setResponseHeaders:(NSDictionary *)headerFields];

		CFRelease(headerFields);
		[self setResponseStatusCode:CFHTTPMessageGetResponseStatusCode(headers)];
		
		// Is the server response a challenge for credentials?
		isAuthenticationChallenge = ([self responseStatusCode] == 401);
		if ([self responseStatusCode] == 407) {
			isAuthenticationChallenge = YES;
			[self setNeedsProxyAuthentication:YES];
		}
		
		// We won't reset the download progress delegate if we got an authentication challenge
		if (!isAuthenticationChallenge) {
			
			// See if we got a Content-length header
			NSString *cLength = [responseHeaders valueForKey:@"Content-Length"];
			if (cLength) {
				[self setContentLength:CFStringGetIntValue((CFStringRef)cLength)];
				if ([self mainRequest]) {
					[[self mainRequest] setContentLength:contentLength];
				}
				if ([self showAccurateProgress] && [self shouldResetProgressIndicators]) {
					[self resetDownloadProgress:[self contentLength]+[self partialDownloadSize]];
				}
			}
			
			// Handle response text encoding
			// If the Content-Type header specified an encoding, we'll use that, otherwise we use defaultStringEncoding (which defaults to NSISOLatin1StringEncoding)
			NSString *contentType = [[self responseHeaders] objectForKey:@"Content-Type"];
			NSStringEncoding encoding = [self defaultResponseEncoding];
			if (contentType) {

				NSString *charsetSeparator = @"charset=";
				NSScanner *charsetScanner = [NSScanner scannerWithString: contentType];
				NSString *IANAEncoding = nil;

				if ([charsetScanner scanUpToString: charsetSeparator intoString: NULL] && [charsetScanner scanLocation] < [contentType length])
				{
					[charsetScanner setScanLocation: [charsetScanner scanLocation] + [charsetSeparator length]];
					[charsetScanner scanUpToString: @";" intoString: &IANAEncoding];
				}

				if (IANAEncoding) {
					CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)IANAEncoding);
					if (cfEncoding != kCFStringEncodingInvalidId) {
						encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
					}
				}
			}
			[self setResponseEncoding:encoding];
			
			// Handle cookies
			NSArray *newCookies = [NSHTTPCookie cookiesWithResponseHeaderFields:responseHeaders forURL:url];
			[self setResponseCookies:newCookies];
			
			if ([self useCookiePersistance]) {
				
				// Store cookies in global persistent store
				[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:newCookies forURL:url mainDocumentURL:nil];
				
				// We also keep any cookies in the sessionCookies array, so that we have a reference to them if we need to remove them later
				NSHTTPCookie *cookie;
				for (cookie in newCookies) {
					[ASIHTTPRequest addSessionCookie:cookie];
				}
			}
			// Do we need to redirect?
			if ([self shouldRedirect] && [responseHeaders valueForKey:@"Location"]) {
				if ([self responseStatusCode] > 300 && [self responseStatusCode] < 308 && [self responseStatusCode] != 304) {
					if ([self responseStatusCode] == 303) {
						[self setRequestMethod:@"GET"];
						[self setPostBody:nil];
						[self setPostLength:0];
						[self setRequestHeaders:nil];
					}
					[self setURL:[[NSURL URLWithString:[responseHeaders valueForKey:@"Location"] relativeToURL:[self url]] absoluteURL]];
					[self setNeedsRedirect:YES];
					
					// Clear the request cookies
					// This means manually added cookies will not be added to the redirect request - only those stored in the global persistent store
					// But, this is probably the safest option - we might be redirecting to a different domain
					[self setRequestCookies:[NSMutableArray array]];
				}
			}
			
		}
		
	}
	CFRelease(headers);
	return isAuthenticationChallenge;
}

#pragma mark http authentication

- (void)saveProxyCredentialsToKeychain:(NSMutableDictionary *)newCredentials
{
	NSURLCredential *authenticationCredentials = [NSURLCredential credentialWithUser:[newCredentials objectForKey:(NSString *)kCFHTTPAuthenticationUsername]
																			password:[newCredentials objectForKey:(NSString *)kCFHTTPAuthenticationPassword]
																		 persistence:NSURLCredentialPersistencePermanent];
	
	if (authenticationCredentials) {
		[ASIHTTPRequest saveCredentials:authenticationCredentials forHost:[self proxyHost] port:[self proxyPort] protocol:[[self url] scheme] realm:[self proxyAuthenticationRealm]];
	}	
}


- (void)saveCredentialsToKeychain:(NSMutableDictionary *)newCredentials
{
	NSURLCredential *authenticationCredentials = [NSURLCredential credentialWithUser:[newCredentials objectForKey:(NSString *)kCFHTTPAuthenticationUsername]
																			password:[newCredentials objectForKey:(NSString *)kCFHTTPAuthenticationPassword]
																		 persistence:NSURLCredentialPersistencePermanent];
	
	if (authenticationCredentials) {
		[ASIHTTPRequest saveCredentials:authenticationCredentials forHost:[[self url] host] port:[[[self url] port] intValue] protocol:[[self url] scheme] realm:[self authenticationRealm]];
	}	
}

- (BOOL)applyProxyCredentials:(NSMutableDictionary *)newCredentials
{
	[self setProxyAuthenticationRetryCount:[self proxyAuthenticationRetryCount]+1];
	
	if (newCredentials && proxyAuthentication && request) {

		// Apply whatever credentials we've built up to the old request
		if (CFHTTPMessageApplyCredentialDictionary(request, proxyAuthentication, (CFMutableDictionaryRef)newCredentials, NULL)) {
			
			//If we have credentials and they're ok, let's save them to the keychain
			if (useKeychainPersistance) {
				[self saveProxyCredentialsToKeychain:newCredentials];
			}
			if (useSessionPersistance) {
				[ASIHTTPRequest setSessionProxyAuthentication:proxyAuthentication];
				[ASIHTTPRequest setSessionProxyCredentials:newCredentials];
			}
			[self setProxyCredentials:newCredentials];
			return YES;
		}
	}
	return NO;
}

- (BOOL)applyCredentials:(NSMutableDictionary *)newCredentials
{
	[self setAuthenticationRetryCount:[self authenticationRetryCount]+1];
	
	if (newCredentials && requestAuthentication && request) {
		// Apply whatever credentials we've built up to the old request
		if (CFHTTPMessageApplyCredentialDictionary(request, requestAuthentication, (CFMutableDictionaryRef)newCredentials, NULL)) {
			
			//If we have credentials and they're ok, let's save them to the keychain
			if (useKeychainPersistance) {
				[self saveCredentialsToKeychain:newCredentials];
			}
			if (useSessionPersistance) {
				
				[ASIHTTPRequest setSessionAuthentication:requestAuthentication];
				[ASIHTTPRequest setSessionCredentials:newCredentials];
			}
			[self setRequestCredentials:newCredentials];
			return YES;
		}
	}
	return NO;
}

- (NSMutableDictionary *)findProxyCredentials
{
	NSMutableDictionary *newCredentials = [[[NSMutableDictionary alloc] init] autorelease];
	
	// Is an account domain needed? (used currently for NTLM only)
	if (CFHTTPAuthenticationRequiresAccountDomain(proxyAuthentication)) {
		if (![self proxyDomain]) {
			[self setProxyDomain:@""];
		}
		[newCredentials setObject:[self proxyDomain] forKey:(NSString *)kCFHTTPAuthenticationAccountDomain];
	}
	
	// Get the authentication realm
	[self setProxyAuthenticationRealm:nil];
	if (!CFHTTPAuthenticationRequiresAccountDomain(proxyAuthentication)) {
		[self setProxyAuthenticationRealm:[(NSString *)CFHTTPAuthenticationCopyRealm(proxyAuthentication) autorelease]];
	}
	
	NSString *user = nil;
	NSString *pass = nil;
	

	// If this is a HEAD request generated by an ASINetworkQueue, we'll try to use the details from the main request
	if ([self mainRequest] && [[self mainRequest] proxyUsername] && [[self mainRequest] proxyPassword]) {
		user = [[self mainRequest] proxyUsername];
		pass = [[self mainRequest] proxyPassword];
		
		// Let's try to use the ones set in this object
	} else if ([self proxyUsername] && [self proxyPassword]) {
		user = [self proxyUsername];
		pass = [self proxyPassword];
	}		

	
	// Ok, that didn't work, let's try the keychain
	if ((!user || !pass) && useKeychainPersistance) {
		NSURLCredential *authenticationCredentials = [ASIHTTPRequest savedCredentialsForHost:[self proxyHost] port:[self proxyPort] protocol:[[self url] scheme] realm:[self proxyAuthenticationRealm]];
		if (authenticationCredentials) {
			user = [authenticationCredentials user];
			pass = [authenticationCredentials password];
		}
		
	}
	
	// If we have a username and password, let's apply them to the request and continue
	if (user && pass) {
		
		[newCredentials setObject:user forKey:(NSString *)kCFHTTPAuthenticationUsername];
		[newCredentials setObject:pass forKey:(NSString *)kCFHTTPAuthenticationPassword];
		return newCredentials;
	}
	return nil;
}


- (NSMutableDictionary *)findCredentials
{
	NSMutableDictionary *newCredentials = [[[NSMutableDictionary alloc] init] autorelease];
	
	// Is an account domain needed? (used currently for NTLM only)
	if (CFHTTPAuthenticationRequiresAccountDomain(requestAuthentication)) {
		if (!domain) {
			[self setDomain:@""];
		}
		[newCredentials setObject:domain forKey:(NSString *)kCFHTTPAuthenticationAccountDomain];
	}
	
	// Get the authentication realm
	[self setAuthenticationRealm:nil];
	if (!CFHTTPAuthenticationRequiresAccountDomain(requestAuthentication)) {
		[self setAuthenticationRealm:[(NSString *)CFHTTPAuthenticationCopyRealm(requestAuthentication) autorelease]];
	}
	
	// First, let's look at the url to see if the username and password were included
	NSString *user = [[self url] user];
	NSString *pass = [[self url] password];
	
	// If the username and password weren't in the url
	if (!user || !pass) {
		
		// If this is a HEAD request generated by an ASINetworkQueue, we'll try to use the details from the main request
		if ([self mainRequest] && [[self mainRequest] username] && [[self mainRequest] password]) {
			user = [[self mainRequest] username];
			pass = [[self mainRequest] password];
			
		// Let's try to use the ones set in this object
		} else if ([self username] && [self password]) {
			user = [self username];
			pass = [self password];
		}		
		
	}
	
	// Ok, that didn't work, let's try the keychain
	if ((!user || !pass) && useKeychainPersistance) {
		NSURLCredential *authenticationCredentials = [ASIHTTPRequest savedCredentialsForHost:[[self url] host] port:[[[self url] port] intValue] protocol:[[self url] scheme] realm:[self authenticationRealm]];
		if (authenticationCredentials) {
			user = [authenticationCredentials user];
			pass = [authenticationCredentials password];
		}
		
	}
	
	// If we have a username and password, let's apply them to the request and continue
	if (user && pass) {
		
		[newCredentials setObject:user forKey:(NSString *)kCFHTTPAuthenticationUsername];
		[newCredentials setObject:pass forKey:(NSString *)kCFHTTPAuthenticationPassword];
		return newCredentials;
	}
	return nil;
}

// Called by delegate to resume loading once authentication info has been populated
- (void)retryWithAuthentication
{
	[[self authenticationLock] lockWhenCondition:1];
	[[self authenticationLock] unlockWithCondition:2];
}

- (BOOL)askDelegateForProxyCredentials
{
	// If we have a delegate, we'll see if it can handle proxyAuthorizationNeededForRequest:.
	// Otherwise, we'll try the queue (if this request is part of one) and it will pass the message on to its own delegate
	id authorizationDelegate = [self delegate];
	if (!authorizationDelegate) {
		authorizationDelegate = [self queue];
	}
	
	if ([authorizationDelegate respondsToSelector:@selector(proxyAuthorizationNeededForRequest:)]) {
		[authorizationDelegate performSelectorOnMainThread:@selector(proxyAuthorizationNeededForRequest:) withObject:self waitUntilDone:[NSThread isMainThread]];
		[[self authenticationLock] lockWhenCondition:2];
		[[self authenticationLock] unlockWithCondition:1];
		
		return YES;
	}
	return NO;
}

- (void)attemptToApplyProxyCredentialsAndResume
{
	
	// Read authentication data
	if (!proxyAuthentication) {
		CFHTTPMessageRef responseHeader = (CFHTTPMessageRef) CFReadStreamCopyProperty(readStream,kCFStreamPropertyHTTPResponseHeader);
		proxyAuthentication = CFHTTPAuthenticationCreateFromResponse(NULL, responseHeader);
		CFRelease(responseHeader);
		proxyAuthenticationMethod = (NSString *)CFHTTPAuthenticationCopyMethod(proxyAuthentication);
	}
	
	// If we haven't got a CFHTTPAuthenticationRef by now, something is badly wrong, so we'll have to give up
	if (!proxyAuthentication) {
		[self cancelLoad];
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:ASIInternalErrorWhileApplyingCredentialsType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Failed to get authentication object from response headers",NSLocalizedDescriptionKey,nil]]];
		return;
	}
	
	// See if authentication is valid
	CFStreamError err;		
	if (!CFHTTPAuthenticationIsValid(proxyAuthentication, &err)) {
		
		CFRelease(proxyAuthentication);
		proxyAuthentication = NULL;
		
		// check for bad credentials, so we can give the delegate a chance to replace them
		if (err.domain == kCFStreamErrorDomainHTTP && (err.error == kCFStreamErrorHTTPAuthenticationBadUserName || err.error == kCFStreamErrorHTTPAuthenticationBadPassword)) {
			
			[self setProxyCredentials:nil];
			[self setLastActivityTime:nil];
			if ([self askDelegateForProxyCredentials]) {
				[self attemptToApplyProxyCredentialsAndResume];
				return;
			}
		}
		[self cancelLoad];
		[self failWithError:ASIAuthenticationError];
		return;
	}

	[self cancelLoad];
	
	if (proxyCredentials) {
		
		// We use startRequest rather than starting all over again in load request because NTLM requires we reuse the request
		if (((proxyAuthenticationMethod != (NSString *)kCFHTTPAuthenticationSchemeNTLM) || proxyAuthenticationRetryCount < 2) && [self applyCredentials:proxyCredentials]) {
			[self startRequest];
			
		// We've failed NTLM authentication twice, we should assume our credentials are wrong
		} else if (proxyAuthenticationMethod == (NSString *)kCFHTTPAuthenticationSchemeNTLM && proxyAuthenticationRetryCount == 2) {
			[self failWithError:ASIAuthenticationError];
			
		// Something went wrong, we'll have to give up
		} else {
			[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:ASIInternalErrorWhileApplyingCredentialsType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Failed to apply proxy credentials to request",NSLocalizedDescriptionKey,nil]]];
		}
		
	// Are a user name & password needed?
	}  else if (CFHTTPAuthenticationRequiresUserNameAndPassword(proxyAuthentication)) {
		
		NSMutableDictionary *newCredentials = [self findProxyCredentials];
		
		//If we have some credentials to use let's apply them to the request and continue
		if (newCredentials) {
			
			if ([self applyProxyCredentials:newCredentials]) {
				[self startRequest];
			} else {
				[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:ASIInternalErrorWhileApplyingCredentialsType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Failed to apply proxy credentials to request",NSLocalizedDescriptionKey,nil]]];
			}
			return;
		}
		
		if ([self askDelegateForProxyCredentials]) {
			[self attemptToApplyProxyCredentialsAndResume];
			return;
		}
		
		// The delegate isn't interested, we'll have to give up
		[self failWithError:ASIAuthenticationError];
		return;
	}
	
}

- (BOOL)askDelegateForCredentials
{
	// If we have a delegate, we'll see if it can handle proxyAuthorizationNeededForRequest:.
	// Otherwise, we'll try the queue (if this request is part of one) and it will pass the message on to its own delegate
	id authorizationDelegate = [self delegate];
	if (!authorizationDelegate) {
		authorizationDelegate = [self queue];
	}
	
	if ([authorizationDelegate respondsToSelector:@selector(authorizationNeededForRequest:)]) {
		[authorizationDelegate performSelectorOnMainThread:@selector(authorizationNeededForRequest:) withObject:self waitUntilDone:[NSThread isMainThread]];
		[[self authenticationLock] lockWhenCondition:2];
		[[self authenticationLock] unlockWithCondition:1];
		
		return YES;
	}
	return NO;
}

- (void)attemptToApplyCredentialsAndResume
{
	if ([self needsProxyAuthentication]) {
		[self attemptToApplyProxyCredentialsAndResume];
		return;
	}
	
	// Read authentication data
	if (!requestAuthentication) {
		CFHTTPMessageRef responseHeader = (CFHTTPMessageRef) CFReadStreamCopyProperty(readStream,kCFStreamPropertyHTTPResponseHeader);
		requestAuthentication = CFHTTPAuthenticationCreateFromResponse(NULL, responseHeader);
		CFRelease(responseHeader);
		authenticationMethod = (NSString *)CFHTTPAuthenticationCopyMethod(requestAuthentication);
	}
	
	if (!requestAuthentication) {
		[self cancelLoad];
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:ASIInternalErrorWhileApplyingCredentialsType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Failed to get authentication object from response headers",NSLocalizedDescriptionKey,nil]]];
		return;
	}
	
	// See if authentication is valid
	CFStreamError err;		
	if (!CFHTTPAuthenticationIsValid(requestAuthentication, &err)) {
		
		CFRelease(requestAuthentication);
		requestAuthentication = NULL;
		
		// check for bad credentials, so we can give the delegate a chance to replace them
		if (err.domain == kCFStreamErrorDomainHTTP && (err.error == kCFStreamErrorHTTPAuthenticationBadUserName || err.error == kCFStreamErrorHTTPAuthenticationBadPassword)) {
			
			[self setRequestCredentials:nil];
			
			[self setLastActivityTime:nil];
			
			if ([self askDelegateForCredentials]) {
				[self attemptToApplyCredentialsAndResume];
				return;
			}
		}
		[self cancelLoad];
		[self failWithError:ASIAuthenticationError];
		return;
	}
	
	[self cancelLoad];
	
	if (requestCredentials) {
		
		if (((authenticationMethod != (NSString *)kCFHTTPAuthenticationSchemeNTLM) || authenticationRetryCount < 2) && [self applyCredentials:requestCredentials]) {
			[self startRequest];
			
			// We've failed NTLM authentication twice, we should assume our credentials are wrong
		} else if (authenticationMethod == (NSString *)kCFHTTPAuthenticationSchemeNTLM && authenticationRetryCount == 2) {
			[self failWithError:ASIAuthenticationError];
			
		} else {
			[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:ASIInternalErrorWhileApplyingCredentialsType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Failed to apply credentials to request",NSLocalizedDescriptionKey,nil]]];
		}
		
		// Are a user name & password needed?
	}  else if (CFHTTPAuthenticationRequiresUserNameAndPassword(requestAuthentication)) {
		
		NSMutableDictionary *newCredentials = [self findCredentials];
		
		//If we have some credentials to use let's apply them to the request and continue
		if (newCredentials) {
			
			if ([self applyCredentials:newCredentials]) {
				[self startRequest];
			} else {
				[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:ASIInternalErrorWhileApplyingCredentialsType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Failed to apply credentials to request",NSLocalizedDescriptionKey,nil]]];
			}
			return;
		}
		
		if ([self askDelegateForCredentials]) {
			[self attemptToApplyCredentialsAndResume];
			return;
		}
		
		// The delegate isn't interested, we'll have to give up
		[self failWithError:ASIAuthenticationError];
		return;
	}
	
}


#pragma mark stream status handlers


- (void)handleNetworkEvent:(CFStreamEventType)type
{	
    // Dispatch the stream events.
    switch (type) {
        case kCFStreamEventHasBytesAvailable:
            [self handleBytesAvailable];
            break;
            
        case kCFStreamEventEndEncountered:
            [self handleStreamComplete];
            break;
            
        case kCFStreamEventErrorOccurred:
            [self handleStreamError];
            break;
            
        default:
            break;
    }
}


- (void)handleBytesAvailable
{
	
	if (![self responseHeaders]) {
		if ([self readResponseHeadersReturningAuthenticationFailure]) {
			[self attemptToApplyCredentialsAndResume];
			return;
		}
	}
	if ([self needsRedirect]) {
		return;
	}
	int bufferSize = 2048;
	if (contentLength > 262144) {
		bufferSize = 65536;
	} else if (contentLength > 65536) {
		bufferSize = 16384;
	}
	
	// Reduce the buffer size if we're receiving data too quickly when bandwidth throttling is active
	// This just augments the throttling done in measureBandwidthUsage to reduce the amount we go over the limit
	
	if ([[self class] isBandwidthThrottled]) {
		[bandwidthThrottlingLock lock];
		if (maxBandwidthPerSecond > 0) {
			long long maxSize  = (long long)maxBandwidthPerSecond-(long long)bandwidthUsedInLastSecond;
			if (maxSize < 0) {
				// We aren't supposed to read any more data right now, but we'll read a single byte anyway so the CFNetwork's buffer isn't full
				bufferSize = 1;
			} else if (maxSize/4 < bufferSize) {
				// We were going to fetch more data that we should be allowed, so we'll reduce the size of our read
				bufferSize = maxSize/4;
			}
		}
		if (bufferSize < 1) {
			bufferSize = 1;
		}
		[bandwidthThrottlingLock unlock];
	}

	
    UInt8 buffer[bufferSize];
    CFIndex bytesRead = CFReadStreamRead(readStream, buffer, sizeof(buffer));
	
	
    // Less than zero is an error
    if (bytesRead < 0) {
        [self handleStreamError];
		
	// If zero bytes were read, wait for the EOF to come.
    } else if (bytesRead) {
		
		[self setTotalBytesRead:[self totalBytesRead]+bytesRead];
		[self setLastActivityTime:[NSDate date]];
		
		// For bandwidth measurement / throttling
		[ASIHTTPRequest incrementBandwidthUsedInLastSecond:bytesRead];
		
		// Are we downloading to a file?
		if ([self downloadDestinationPath]) {
			if (![self fileDownloadOutputStream]) {
				BOOL append = NO;
				if (![self temporaryFileDownloadPath]) {
					[self setTemporaryFileDownloadPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]]];
				} else if ([self allowResumeForFileDownloads]) {
					append = YES;
				}
				
				[self setFileDownloadOutputStream:[[[NSOutputStream alloc] initToFileAtPath:temporaryFileDownloadPath append:append] autorelease]];
				[fileDownloadOutputStream open];
			}
			[fileDownloadOutputStream write:buffer maxLength:bytesRead];
			
		//Otherwise, let's add the data to our in-memory store
		} else {
			[rawResponseData appendBytes:buffer length:bytesRead];
		}
    }
}

- (void)handleStreamComplete
{
	//Try to read the headers (if this is a HEAD request handleBytesAvailable may not be called)
	if (![self responseHeaders]) {
		if ([self readResponseHeadersReturningAuthenticationFailure]) {
			[self attemptToApplyCredentialsAndResume];
			return;
		}
	}
	if ([self needsRedirect]) {
		return;
	}
	[progressLock lock];	
	
	[self setComplete:YES];
	[self updateProgressIndicators];
	
	[[self cancelledLock] lock];
    if (readStream) {
        CFReadStreamClose(readStream);
        CFReadStreamSetClient(readStream, kCFStreamEventNone, NULL, NULL);
        CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), ASIHTTPRequestRunMode);
        CFRelease(readStream);
        readStream = NULL;
    }
	
	[[self postBodyReadStream] close];
	
	NSError *fileError = nil;
	
	// Delete up the request body temporary file, if it exists
	if (didCreateTemporaryPostDataFile) {
		[self removePostDataFile];
	}
	
	// Close the output stream as we're done writing to the file
	if (temporaryFileDownloadPath) {
		[fileDownloadOutputStream close];
		
		// Decompress the file (if necessary) directly to the destination path
		if ([self isResponseCompressed]) {
			int decompressionStatus = [ASIHTTPRequest uncompressZippedDataFromFile:temporaryFileDownloadPath toFile:downloadDestinationPath];
			if (decompressionStatus != Z_OK) {
				fileError = [NSError errorWithDomain:NetworkRequestErrorDomain code:ASIFileManagementError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Decompression of %@ failed with code %hi",temporaryFileDownloadPath,decompressionStatus],NSLocalizedDescriptionKey,nil]];
			}
				
			[self removeTemporaryDownloadFile];
		} else {
					
			//Remove any file at the destination path
			NSError *moveError = nil;
			if ([[NSFileManager defaultManager] fileExistsAtPath:downloadDestinationPath]) {
				[[NSFileManager defaultManager] removeItemAtPath:downloadDestinationPath error:&moveError];
				if (moveError) {
					fileError = [NSError errorWithDomain:NetworkRequestErrorDomain code:ASIFileManagementError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Unable to remove file at path '%@'",downloadDestinationPath],NSLocalizedDescriptionKey,moveError,NSUnderlyingErrorKey,nil]];
				}
			}
					
			//Move the temporary file to the destination path
			if (!fileError) {
				[[NSFileManager defaultManager] moveItemAtPath:temporaryFileDownloadPath toPath:downloadDestinationPath error:&moveError];
				if (moveError) {
					fileError = [NSError errorWithDomain:NetworkRequestErrorDomain code:ASIFileManagementError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Failed to move file from '%@' to '%@'",temporaryFileDownloadPath,downloadDestinationPath],NSLocalizedDescriptionKey,moveError,NSUnderlyingErrorKey,nil]];
				}
			}
		}
	}
	[[self cancelledLock] unlock];
	[progressLock unlock];
	
	if (fileError) {
		[self failWithError:fileError];
	} else {
		[self requestFinished];
	}
}


- (void)handleStreamError
{
	NSError *underlyingError = [(NSError *)CFReadStreamCopyError(readStream) autorelease];
	
	[self cancelLoad];
	[self setComplete:YES];
	
	if (![self error]) { // We may already have handled this error
		
		
		NSString *reason = @"A connection failure occurred";
		
		// We'll use a custom error message for SSL errors, but you should always check underlying error if you want more details
		// For some reason SecureTransport.h doesn't seem to be available on iphone, so error codes hard-coded
		// Also, iPhone seems to handle errors differently from Mac OS X - a self-signed certificate returns a different error code on each platform, so we'll just provide a general error
		if ([[underlyingError domain] isEqualToString:NSOSStatusErrorDomain]) {
			if ([underlyingError code] <= -9800 && [underlyingError code] >= -9818) {
				reason = [NSString stringWithFormat:@"%@: SSL problem (possibily a bad/expired/self-signed certificate)",reason];
			}
		}
		
		[self failWithError:[NSError errorWithDomain:NetworkRequestErrorDomain code:ASIConnectionFailureErrorType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:reason,NSLocalizedDescriptionKey,underlyingError,NSUnderlyingErrorKey,nil]]];
	}
    [super cancel];
}

#pragma mark managing the session

+ (void)setSessionCredentials:(NSMutableDictionary *)newCredentials
{
	[sessionCredentials release];
	sessionCredentials = [newCredentials retain];
}

+ (void)setSessionAuthentication:(CFHTTPAuthenticationRef)newAuthentication
{
	if (sessionAuthentication) {
		CFRelease(sessionAuthentication);
	}
	sessionAuthentication = newAuthentication;
	if (newAuthentication) {
		CFRetain(sessionAuthentication);
	}
}

+ (void)setSessionProxyCredentials:(NSMutableDictionary *)newCredentials
{
	[sessionProxyCredentials release];
	sessionProxyCredentials = [newCredentials retain];
}

+ (void)setSessionProxyAuthentication:(CFHTTPAuthenticationRef)newAuthentication
{
	if (sessionProxyAuthentication) {
		CFRelease(sessionProxyAuthentication);
	}
	sessionProxyAuthentication = newAuthentication;
	if (newAuthentication) {
		CFRetain(sessionProxyAuthentication);
	}
}


#pragma mark keychain storage

+ (void)saveCredentials:(NSURLCredential *)credentials forHost:(NSString *)host port:(int)port protocol:(NSString *)protocol realm:(NSString *)realm
{
	NSURLProtectionSpace *protectionSpace = [[[NSURLProtectionSpace alloc] initWithHost:host
																				   port:port
																			   protocol:protocol
																				  realm:realm
																   authenticationMethod:NSURLAuthenticationMethodDefault] autorelease];
	
	
	NSURLCredentialStorage *storage = [NSURLCredentialStorage sharedCredentialStorage];
	[storage setDefaultCredential:credentials forProtectionSpace:protectionSpace];
}

+ (NSURLCredential *)savedCredentialsForHost:(NSString *)host port:(int)port protocol:(NSString *)protocol realm:(NSString *)realm
{
	NSURLProtectionSpace *protectionSpace = [[[NSURLProtectionSpace alloc] initWithHost:host
																				   port:port
																			   protocol:protocol
																				  realm:realm
																   authenticationMethod:NSURLAuthenticationMethodDefault] autorelease];
	
	
	NSURLCredentialStorage *storage = [NSURLCredentialStorage sharedCredentialStorage];
	return [storage defaultCredentialForProtectionSpace:protectionSpace];
}

+ (void)removeCredentialsForHost:(NSString *)host port:(int)port protocol:(NSString *)protocol realm:(NSString *)realm
{
	NSURLProtectionSpace *protectionSpace = [[[NSURLProtectionSpace alloc] initWithHost:host
																				   port:port
																			   protocol:protocol
																				  realm:realm
																   authenticationMethod:NSURLAuthenticationMethodDefault] autorelease];
	
	
	NSURLCredentialStorage *storage = [NSURLCredentialStorage sharedCredentialStorage];
	[storage removeCredential:[storage defaultCredentialForProtectionSpace:protectionSpace] forProtectionSpace:protectionSpace];
	
}


+ (NSMutableArray *)sessionCookies
{
	if (!sessionCookies) {
		[ASIHTTPRequest setSessionCookies:[[[NSMutableArray alloc] init] autorelease]];
	}
	return sessionCookies;
}

+ (void)setSessionCookies:(NSMutableArray *)newSessionCookies
{
	[sessionCookiesLock lock];
	// Remove existing cookies from the persistent store
	for (NSHTTPCookie *cookie in sessionCookies) {
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
	}
	[sessionCookies release];
	sessionCookies = [newSessionCookies retain];
	[sessionCookiesLock unlock];
}

+ (void)addSessionCookie:(NSHTTPCookie *)newCookie
{
	// Called to ensure sessionCookies exists first, as we won't be able to create it when we have the lock
	[[ASIHTTPRequest sessionCookies] count];
	
	[sessionCookiesLock lock];
	NSHTTPCookie *cookie;
	int i;
	int max = [[ASIHTTPRequest sessionCookies] count];
	for (i=0; i<max; i++) {
		cookie = [[ASIHTTPRequest sessionCookies] objectAtIndex:i];
		if ([[cookie domain] isEqualToString:[newCookie domain]] && [[cookie path] isEqualToString:[newCookie path]] && [[cookie name] isEqualToString:[newCookie name]]) {
			[[ASIHTTPRequest sessionCookies] removeObjectAtIndex:i];
			break;
		}
	}
	[[ASIHTTPRequest sessionCookies] addObject:newCookie];
	[sessionCookiesLock unlock];
}

// Dump all session data (authentication and cookies)
+ (void)clearSession
{
	[ASIHTTPRequest setSessionAuthentication:NULL];
	[ASIHTTPRequest setSessionCredentials:nil];
	[ASIHTTPRequest setSessionCookies:nil];
}

#pragma mark gzip decompression

//
// Contributed by Shaun Harrison of Enormego, see: http://developers.enormego.com/view/asihttprequest_gzip
// Based on this: http://deusty.blogspot.com/2007/07/gzip-compressiondecompression.html
//
+ (NSData *)uncompressZippedData:(NSData*)compressedData
{
	if ([compressedData length] == 0) return compressedData;
	
	unsigned full_length = [compressedData length];
	unsigned half_length = [compressedData length] / 2;
	
	NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
	BOOL done = NO;
	int status;
	
	z_stream strm;
	strm.next_in = (Bytef *)[compressedData bytes];
	strm.avail_in = [compressedData length];
	strm.total_out = 0;
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	
	if (inflateInit2(&strm, (15+32)) != Z_OK) return nil;
	
	while (!done) {
		// Make sure we have enough room and reset the lengths.
		if (strm.total_out >= [decompressed length]) {
			[decompressed increaseLengthBy: half_length];
		}
		strm.next_out = [decompressed mutableBytes] + strm.total_out;
		strm.avail_out = [decompressed length] - strm.total_out;
		
		// Inflate another chunk.
		status = inflate (&strm, Z_SYNC_FLUSH);
		if (status == Z_STREAM_END) {
			done = YES;
		} else if (status != Z_OK) {
			break;
		}
	}
	if (inflateEnd (&strm) != Z_OK) return nil;
	
	// Set real length.
	if (done) {
		[decompressed setLength: strm.total_out];
		return [NSData dataWithData: decompressed];
	} else {
		return nil;
	}
}

// NOTE: To debug this method, turn off Data Formatters in Xcode or you'll crash on closeFile
+ (int)uncompressZippedDataFromFile:(NSString *)sourcePath toFile:(NSString *)destinationPath
{
	// Create an empty file at the destination path
	[[NSFileManager defaultManager] createFileAtPath:destinationPath contents:[NSData data] attributes:nil];
	
	// Get a FILE struct for the source file
	NSFileHandle *inputFileHandle = [NSFileHandle fileHandleForReadingAtPath:sourcePath];
	FILE *source = fdopen([inputFileHandle fileDescriptor], "r");
	
	// Get a FILE struct for the destination path
	NSFileHandle *outputFileHandle = [NSFileHandle fileHandleForWritingAtPath:destinationPath];
	FILE *dest = fdopen([outputFileHandle fileDescriptor], "w");
	
	
	// Uncompress data in source and save in destination
	int status = [ASIHTTPRequest uncompressZippedDataFromSource:source toDestination:dest];
	
	// Close the files
	fclose(dest);
	fclose(source);
	[inputFileHandle closeFile];
	[outputFileHandle closeFile];	
	return status;
}

//
// From the zlib sample code by Mark Adler, code here:
//	http://www.zlib.net/zpipe.c
//
#define CHUNK 16384

+ (int)uncompressZippedDataFromSource:(FILE *)source toDestination:(FILE *)dest
{
    int ret;
    unsigned have;
    z_stream strm;
    unsigned char in[CHUNK];
    unsigned char out[CHUNK];
	
    /* allocate inflate state */
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.avail_in = 0;
    strm.next_in = Z_NULL;
    ret = inflateInit2(&strm, (15+32));
    if (ret != Z_OK)
        return ret;
	
    /* decompress until deflate stream ends or end of file */
    do {
        strm.avail_in = fread(in, 1, CHUNK, source);
        if (ferror(source)) {
            (void)inflateEnd(&strm);
            return Z_ERRNO;
        }
        if (strm.avail_in == 0)
            break;
        strm.next_in = in;
		
        /* run inflate() on input until output buffer not full */
        do {
            strm.avail_out = CHUNK;
            strm.next_out = out;
            ret = inflate(&strm, Z_NO_FLUSH);
            assert(ret != Z_STREAM_ERROR);  /* state not clobbered */
            switch (ret) {
				case Z_NEED_DICT:
					ret = Z_DATA_ERROR;     /* and fall through */
				case Z_DATA_ERROR:
				case Z_MEM_ERROR:
					(void)inflateEnd(&strm);
					return ret;
            }
            have = CHUNK - strm.avail_out;
            if (fwrite(&out, 1, have, dest) != have || ferror(dest)) {
                (void)inflateEnd(&strm);
                return Z_ERRNO;
            }
        } while (strm.avail_out == 0);
		
        /* done when inflate() says it's done */
    } while (ret != Z_STREAM_END);
	
    /* clean up and return */
    (void)inflateEnd(&strm);
    return ret == Z_STREAM_END ? Z_OK : Z_DATA_ERROR;
}


#pragma mark gzip compression

// Based on this from Robbie Hanson: http://deusty.blogspot.com/2007/07/gzip-compressiondecompression.html

+ (NSData *)compressData:(NSData*)uncompressedData
{
	if ([uncompressedData length] == 0) return uncompressedData;
	
	z_stream strm;
	
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	strm.opaque = Z_NULL;
	strm.total_out = 0;
	strm.next_in=(Bytef *)[uncompressedData bytes];
	strm.avail_in = [uncompressedData length];
	
	// Compresssion Levels:
	//   Z_NO_COMPRESSION
	//   Z_BEST_SPEED
	//   Z_BEST_COMPRESSION
	//   Z_DEFAULT_COMPRESSION
	
	if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
	
	NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
	
	do {
		
		if (strm.total_out >= [compressed length])
			[compressed increaseLengthBy: 16384];
		
		strm.next_out = [compressed mutableBytes] + strm.total_out;
		strm.avail_out = [compressed length] - strm.total_out;
		
		deflate(&strm, Z_FINISH);  
		
	} while (strm.avail_out == 0);
	
	deflateEnd(&strm);
	
	[compressed setLength: strm.total_out];
	return [NSData dataWithData:compressed];
}

// NOTE: To debug this method, turn off Data Formatters in Xcode or you'll crash on closeFile
+ (int)compressDataFromFile:(NSString *)sourcePath toFile:(NSString *)destinationPath
{
	// Create an empty file at the destination path
	[[NSFileManager defaultManager] createFileAtPath:destinationPath contents:[NSData data] attributes:nil];
	
	// Get a FILE struct for the source file
	NSFileHandle *inputFileHandle = [NSFileHandle fileHandleForReadingAtPath:sourcePath];
	FILE *source = fdopen([inputFileHandle fileDescriptor], "r");

	// Get a FILE struct for the destination path
	NSFileHandle *outputFileHandle = [NSFileHandle fileHandleForWritingAtPath:destinationPath];
	FILE *dest = fdopen([outputFileHandle fileDescriptor], "w");

	// compress data in source and save in destination
	int status = [ASIHTTPRequest compressDataFromSource:source toDestination:dest];

	// Close the files
	fclose(dest);
	fclose(source);
	
	// We have to close both of these explictly because CFReadStreamCreateForStreamedHTTPRequest() seems to go bonkers otherwise
	[inputFileHandle closeFile];
	[outputFileHandle closeFile];

	return status;
}

//
// Also from the zlib sample code  at http://www.zlib.net/zpipe.c
// 
+ (int)compressDataFromSource:(FILE *)source toDestination:(FILE *)dest
{
    int ret, flush;
    unsigned have;
    z_stream strm;
    unsigned char in[CHUNK];
    unsigned char out[CHUNK];
	
    /* allocate deflate state */
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    ret = deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY);
    if (ret != Z_OK)
        return ret;
	
    /* compress until end of file */
    do {
        strm.avail_in = fread(in, 1, CHUNK, source);
        if (ferror(source)) {
            (void)deflateEnd(&strm);
            return Z_ERRNO;
        }
        flush = feof(source) ? Z_FINISH : Z_NO_FLUSH;
        strm.next_in = in;
		
        /* run deflate() on input until output buffer not full, finish
		 compression if all of source has been read in */
        do {
            strm.avail_out = CHUNK;
            strm.next_out = out;
            ret = deflate(&strm, flush);    /* no bad return value */
            assert(ret != Z_STREAM_ERROR);  /* state not clobbered */
            have = CHUNK - strm.avail_out;
            if (fwrite(out, 1, have, dest) != have || ferror(dest)) {
                (void)deflateEnd(&strm);
                return Z_ERRNO;
            }
        } while (strm.avail_out == 0);
        assert(strm.avail_in == 0);     /* all input will be used */
		
        /* done when last data in file processed */
    } while (flush != Z_FINISH);
    assert(ret == Z_STREAM_END);        /* stream will be complete */
	
    /* clean up and return */
    (void)deflateEnd(&strm);
    return Z_OK;
}

#pragma mark get user agent

+ (NSString *)defaultUserAgentString
{
	NSBundle *bundle = [NSBundle mainBundle];
	
	// Attempt to find a name for this application
	NSString *appName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
	if (!appName) {
		appName = [bundle objectForInfoDictionaryKey:@"CFBundleName"];	
	}
	// If we couldn't find one, we'll give up (and ASIHTTPRequest will use the standard CFNetwork user agent)
	if (!appName) {
		return nil;
	}
	NSString *appVersion = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
	NSString *deviceName;;
	NSString *OSName;
	NSString *OSVersion;
	
	NSString *locale = [[NSLocale currentLocale] localeIdentifier];
	
#if TARGET_OS_IPHONE
	UIDevice *device = [UIDevice currentDevice];
	deviceName = [device model];
	OSName = [device systemName];
	OSVersion = [device systemVersion];
	
#else
	deviceName = @"Macintosh";
	OSName = @"Mac OS X";
	
	// From http://www.cocoadev.com/index.pl?DeterminingOSVersion
	// We won't bother to check for systems prior to 10.4, since ASIHTTPRequest only works on 10.5+
    OSErr err;
    SInt32 versionMajor, versionMinor, versionBugFix;
	if ((err = Gestalt(gestaltSystemVersionMajor, &versionMajor)) != noErr) return nil;
	if ((err = Gestalt(gestaltSystemVersionMinor, &versionMinor)) != noErr) return nil;
	if ((err = Gestalt(gestaltSystemVersionBugFix, &versionBugFix)) != noErr) return nil;
	OSVersion = [NSString stringWithFormat:@"%u.%u.%u", versionMajor, versionMinor, versionBugFix];
	
#endif
	// Takes the form "My Application 1.0 (Macintosh; Mac OS X 10.5.7; en_GB)"
	return [NSString stringWithFormat:@"%@ %@ (%@; %@ %@; %@)", appName, appVersion, deviceName, OSName, OSVersion, locale];
}

#pragma mark proxy autoconfiguration

// Returns an array of proxies to use for a particular url, given the url of a PAC script
+ (NSArray *)proxiesForURL:(NSURL *)theURL fromPAC:(NSURL *)pacScriptURL
{
	// From: http://developer.apple.com/samplecode/CFProxySupportTool/listing1.html
	// Work around <rdar://problem/5530166>.  This dummy call to 
	// CFNetworkCopyProxiesForURL initialise some state within CFNetwork 
	// that is required by CFNetworkCopyProxiesForAutoConfigurationScript.
	(void) CFNetworkCopyProxiesForURL((CFURLRef)theURL, NULL);
	
	NSStringEncoding encoding;
	NSError *err = nil;
	NSString *script = [NSString stringWithContentsOfURL:pacScriptURL usedEncoding:&encoding error:&err];
	if (err) {
		return nil;
	}
	CFErrorRef err2 = NULL;
	// Obtain the list of proxies by running the autoconfiguration script
	NSArray *proxies = [(NSArray *)CFNetworkCopyProxiesForAutoConfigurationScript((CFStringRef)script,(CFURLRef)theURL, &err2) autorelease];
	if (err2) {
		return nil;
	}
	return proxies;
}

#pragma mark mime-type detection

+ (NSString *)mimeTypeForFileAtPath:(NSString *)path
{
	// NSTask does seem to exist in the 2.2.1 SDK, though it's not in the 3.0 SDK. It's probably best if we just use a generic mime type on iPhone all the time.
#if TARGET_OS_IPHONE
	return @"application/octet-stream";
	
	// Grab the mime type using an NSTask to run the 'file' program, with the Mac OS-specific parameters to grab the mime type
	// Perhaps there is a better way to do this?
#else
	NSTask *task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath: @"/usr/bin/file"];
	[task setArguments:[NSMutableArray arrayWithObjects:@"-Ib",path,nil]];
	
    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
	
    NSFileHandle *file = [outputPipe fileHandleForReading];
	
	[task launch];
	[task waitUntilExit];
	
	if ([task terminationStatus] != 0) {
		return @"application/octet-stream";	
	}
	
	NSString *mimeTypeString = [[[[NSString alloc] initWithData:[file readDataToEndOfFile] encoding: NSUTF8StringEncoding] autorelease] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	return [[mimeTypeString componentsSeparatedByString:@";"] objectAtIndex:0];
#endif
}

#pragma mark bandwidth measurement / throttling

+ (BOOL)isBandwidthThrottled
{
#if TARGET_OS_IPHONE
	[bandwidthThrottlingLock lock];

	BOOL throttle = isBandwidthThrottled || (!shouldThrottleBandwithForWWANOnly && (maxBandwidthPerSecond));
	[bandwidthThrottlingLock unlock];
	return throttle;
#else
	[bandwidthThrottlingLock lock];
	BOOL throttle = (maxBandwidthPerSecond);
	[bandwidthThrottlingLock unlock];
	return throttle;
#endif
}

+ (unsigned long)maxBandwidthPerSecond
{
	[bandwidthThrottlingLock lock];
	unsigned long amount = maxBandwidthPerSecond;
	[bandwidthThrottlingLock unlock];
	return amount;
}

+ (void)setMaxBandwidthPerSecond:(unsigned long)bytes
{
	[bandwidthThrottlingLock lock];
	maxBandwidthPerSecond = bytes;
	[bandwidthThrottlingLock unlock];
}

+ (void)incrementBandwidthUsedInLastSecond:(unsigned long)bytes
{
	[bandwidthThrottlingLock lock];
	bandwidthUsedInLastSecond += bytes;
	//NSLog(@"used in last second: %lu",bandwidthUsedInLastSecond);
	[bandwidthThrottlingLock unlock];
}

+ (void)recordBandwidthUsage
{
	if (bandwidthUsedInLastSecond == 0) {
		[bandwidthUsageTracker removeAllObjects];
	} else {
		NSTimeInterval interval = [bandwidthMeasurementDate timeIntervalSinceNow];
		while ((interval < 0 || [bandwidthUsageTracker count] > 5) && [bandwidthUsageTracker count] > 0) {
			[bandwidthUsageTracker removeObjectAtIndex:0];
			interval++;
		}
	}
	//NSLog(@"Used: %qi",bandwidthUsedInLastSecond);
	[bandwidthUsageTracker addObject:[NSNumber numberWithUnsignedLong:bandwidthUsedInLastSecond]];
	[bandwidthMeasurementDate release];
	bandwidthMeasurementDate = [[NSDate dateWithTimeIntervalSinceNow:1] retain];
	bandwidthUsedInLastSecond = 0;
	
	int measurements = [bandwidthUsageTracker count];
	unsigned long long totalBytes = 0;
	for (NSNumber *bytes in bandwidthUsageTracker) {
		totalBytes += [bytes unsignedLongValue];
	}
	averageBandwidthUsedPerSecond = totalBytes/measurements;		
}

+ (unsigned long)averageBandwidthUsedPerSecond
{
	[bandwidthThrottlingLock lock];
	
	if (!bandwidthMeasurementDate || [bandwidthMeasurementDate timeIntervalSinceNow] < 0) {
		[self recordBandwidthUsage];
	}
	unsigned long amount = 	averageBandwidthUsedPerSecond;
	[bandwidthThrottlingLock unlock];
	return amount;
}

+ (void)measureBandwidthUsage
{
	// Other requests may have to wait for this lock if we're sleeping, but this is fine, since in that case we already know they shouldn't be sending or receiving data
	[bandwidthThrottlingLock lock];

	if (!bandwidthMeasurementDate || [bandwidthMeasurementDate timeIntervalSinceNow] < -0) {
		[self recordBandwidthUsage];
	}
	
	// Are we performing bandwidth throttling?
	if (maxBandwidthPerSecond > 0) {	
		// How much data can we still send or receive this second?
		long long bytesRemaining = (long long)maxBandwidthPerSecond - (long long)bandwidthUsedInLastSecond;
				
		// Have we used up our allowance?
		if (bytesRemaining < 8) {
			
			// Yes, put this request to sleep until a second is up
			[NSThread sleepUntilDate:bandwidthMeasurementDate];
			[self recordBandwidthUsage];
		}
	}
	[bandwidthThrottlingLock unlock];
}

#if TARGET_OS_IPHONE
+ (void)setShouldThrottleBandwidthForWWAN:(BOOL)throttle
{
	if (throttle) {
		[ASIHTTPRequest throttleBandwidthForWWANUsingLimit:ASIWWANBandwidthThrottleAmount];
	} else {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"kNetworkReachabilityChangedNotification" object:nil];
		[ASIHTTPRequest setMaxBandwidthPerSecond:0];
		[bandwidthThrottlingLock lock];
		shouldThrottleBandwithForWWANOnly = NO;
		[bandwidthThrottlingLock unlock];
	}
}

+ (void)throttleBandwidthForWWANUsingLimit:(unsigned long)limit
{	
	[bandwidthThrottlingLock lock];
	shouldThrottleBandwithForWWANOnly = YES;
	maxBandwidthPerSecond = limit;
	[[Reachability sharedReachability] setNetworkStatusNotificationsEnabled:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:@"kNetworkReachabilityChangedNotification" object:nil];
	[bandwidthThrottlingLock unlock];
	[ASIHTTPRequest reachabilityChanged:nil];
}

+ (void)reachabilityChanged:(NSNotification *)note
{
	[bandwidthThrottlingLock lock];	
	if ([[Reachability sharedReachability] internetConnectionStatus] == ReachableViaCarrierDataNetwork) {
		isBandwidthThrottled = YES;
	} else {
		isBandwidthThrottled = NO;
	}
	[bandwidthThrottlingLock unlock];
}
#endif

+ (unsigned long)maxUploadReadLength
{

	[bandwidthThrottlingLock lock];
	
	// We'll split our bandwidth allowance into 4 (which is the default for an ASINetworkQueue's max concurrent operations count) to give all running requests a fighting chance of reading data this cycle
	long long toRead = maxBandwidthPerSecond/4;
	if (maxBandwidthPerSecond > 0 && (bandwidthUsedInLastSecond + toRead > maxBandwidthPerSecond)) {
		toRead = maxBandwidthPerSecond-bandwidthUsedInLastSecond;
		if (toRead < 0) {
			toRead = 0;
		}
	}

	if (toRead == 0 || !bandwidthMeasurementDate || [bandwidthMeasurementDate timeIntervalSinceNow] < -0) {
		//NSLog(@"sleep");
		[NSThread sleepUntilDate:bandwidthMeasurementDate];
		[self recordBandwidthUsage];
	}
	[bandwidthThrottlingLock unlock];	
	return toRead;
}

@synthesize username;
@synthesize password;
@synthesize domain;
@synthesize proxyUsername;
@synthesize proxyPassword;
@synthesize proxyDomain;
@synthesize url;
@synthesize delegate;
@synthesize queue;
@synthesize uploadProgressDelegate;
@synthesize downloadProgressDelegate;
@synthesize useKeychainPersistance;
@synthesize useSessionPersistance;
@synthesize useCookiePersistance;
@synthesize downloadDestinationPath;
@synthesize temporaryFileDownloadPath;
@synthesize didFinishSelector;
@synthesize didFailSelector;
@synthesize authenticationRealm;
@synthesize proxyAuthenticationRealm;
@synthesize error;
@synthesize complete;
@synthesize requestHeaders;
@synthesize responseHeaders;
@synthesize responseCookies;
@synthesize requestCookies;
@synthesize requestCredentials;
@synthesize responseStatusCode;
@synthesize rawResponseData;
@synthesize lastActivityTime;
@synthesize timeOutSeconds;
@synthesize requestMethod;
@synthesize postBody;
@synthesize compressedPostBody;
@synthesize contentLength;
@synthesize partialDownloadSize;
@synthesize postLength;
@synthesize shouldResetProgressIndicators;
@synthesize mainRequest;
@synthesize totalBytesRead;
@synthesize totalBytesSent;
@synthesize showAccurateProgress;
@synthesize uploadBufferSize;
@synthesize defaultResponseEncoding;
@synthesize responseEncoding;
@synthesize allowCompressedResponse;
@synthesize allowResumeForFileDownloads;
@synthesize userInfo;
@synthesize postBodyFilePath;
@synthesize compressedPostBodyFilePath;
@synthesize postBodyWriteStream;
@synthesize postBodyReadStream;
@synthesize shouldStreamPostDataFromDisk;
@synthesize didCreateTemporaryPostDataFile;
@synthesize useHTTPVersionOne;
@synthesize lastBytesRead;
@synthesize lastBytesSent;
@synthesize cancelledLock;
@synthesize haveBuiltPostBody;
@synthesize fileDownloadOutputStream;
@synthesize authenticationRetryCount;
@synthesize proxyAuthenticationRetryCount;
@synthesize updatedProgress;
@synthesize shouldRedirect;
@synthesize validatesSecureCertificate;
@synthesize needsRedirect;
@synthesize redirectCount;
@synthesize shouldCompressRequestBody;
@synthesize authenticationLock;
@synthesize needsProxyAuthentication;
@synthesize proxyCredentials;
@synthesize proxyHost;
@synthesize proxyPort;
@synthesize PACurl;
@end


