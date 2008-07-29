//
//  ASIHTTPRequest.m
//
//  Created by Ben Copsey on 04/10/2007.
//  Copyright 2007-2008 All-Seeing Interactive. All rights reserved.
//
//  Portions are based on the ImageClient example from Apple:
//  See: http://developer.apple.com/samplecode/ImageClient/listing37.html

#import "ASIHTTPRequest.h"

static NSString *NetworkRequestErrorDomain = @"com.Your-Company.Your-Product.NetworkError.";

static const CFOptionFlags kNetworkEvents = kCFStreamEventOpenCompleted |
                                            kCFStreamEventHasBytesAvailable |
                                            kCFStreamEventEndEncountered |
                                            kCFStreamEventErrorOccurred;


static CFMutableDictionaryRef sharedCredentials = NULL;
static CFHTTPAuthenticationRef sharedAuthentication = NULL;

static void ReadStreamClientCallBack(CFReadStreamRef readStream, CFStreamEventType type, void *clientCallBackInfo) {
    [((ASIHTTPRequest*)clientCallBackInfo) handleNetworkEvent: type];
}




@implementation ASIHTTPRequest



#pragma mark init / dealloc

- (id)initWithURL:(NSURL *)newURL
{
	[super init];
	url = [newURL retain];
	return self;
}

- (id)init {
	[super init];
	postData = nil;
	fileData = nil;
	username = nil;
	password = nil;
	requestHeaders = nil;
	authenticationRealm = nil;
	outputStream = nil;
	authentication = NULL;
	credentials = NULL;
	request = NULL;
	usesKeychain = NO;
	didFinishSelector = @selector(requestFinished:);
	didFailSelector = @selector(requestFailed:);
	delegate = nil;
	return self;	
}

- (void)dealloc
{
	if (authentication) {
		CFRelease(authentication);
	}
	if (credentials) {
		CFRelease(credentials);
	}
	if (request) {
		CFRelease(request);
	}
	[self cancelLoad];
	[error release];
	[postData release];
	[fileData release];
	[requestHeaders release];
	[downloadDestinationPath release];
	[outputStream release];
	[username release];
	[password release];
	[authenticationRealm release];
	[url release];
	[authenticationLock release];
	[super dealloc];
}


#pragma mark setup request

- (void)addRequestHeader:(NSString *)header value:(NSString *)value
{
	if (!requestHeaders) {
		requestHeaders = [[NSMutableDictionary alloc] init];
	}
	[requestHeaders setObject:value forKey:header];
}


- (void)setPostValue:(id)value forKey:(NSString *)key
{
	if (!postData) {
		postData = [[NSMutableDictionary alloc] init];
	}
	[postData setValue:value forKey:key];
}

- (void)setFile:(NSString *)filePath forKey:(NSString *)key
{
	if (!fileData) {
		fileData = [[NSMutableDictionary alloc] init];
	}
	[fileData setValue:filePath forKey:key];
}

- (void)setUsername:(NSString *)newUsername andPassword:(NSString *)newPassword
{
	[username release];
	username = [newUsername retain];
	[password release];
	password = [newPassword retain];
}



#pragma mark get information about this request

- (BOOL)isFinished 
{
	return complete;
}

- (double)totalBytesRead
{
	return totalBytesRead;
}

// Call this method to get the recieved data as an NSString. Don't use for Binary data!
- (NSString *)dataString
{
	if (!receivedData) {
		return nil;
	}
	return [[[NSString alloc] initWithBytes:[(NSData *)receivedData bytes] length:[(NSData *)receivedData length] encoding:NSUTF8StringEncoding] autorelease];
}


#pragma mark request logic

// Create the request
- (void)main
{
	complete = NO;

	// We'll make a post request only if the user specified post data
	NSString *method = @"GET";
	if ([postData count] > 0 || [fileData count] > 0) {
		method = @"POST";
	}
	
    // Create a new HTTP request.
	request = CFHTTPMessageCreateRequest(kCFAllocatorDefault, (CFStringRef)method, (CFURLRef)url, kCFHTTPVersion1_1);
    if (!request) {
		[self failWithProblem:[NSString stringWithFormat:@"Unable to create request for: %@",url]];
		return;
    }

	if (sharedAuthentication && sharedCredentials) {
		CFHTTPMessageApplyCredentialDictionary(request, sharedAuthentication, sharedCredentials, NULL);
	}

	//Set your own boundary string only if really obsessive. We don't bother to check if post data contains the boundary, since it's pretty unlikely that it does.
	NSString *stringBoundary = @"0xKhTmLbOuNdArY";
	
	//Add custom headers
	NSString *header;
	for (header in requestHeaders) {
		CFHTTPMessageSetHeaderFieldValue(request, (CFStringRef)header, (CFStringRef)[requestHeaders objectForKey:header]);
	}
	CFHTTPMessageSetHeaderFieldValue(request, (CFStringRef)@"Content-Type", (CFStringRef)[NSString stringWithFormat:@"multipart/form-data; boundary=%@",stringBoundary]);
		
	
	if ([postData count] > 0 || [fileData count] > 0) {
		
		NSMutableData *postBody = [NSMutableData data];
		[postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
		
		//Adds post data
		NSData *endItemBoundary = [[NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding];
		NSEnumerator *e = [postData keyEnumerator];
		NSString *key;
		while (key = [e nextObject]) {
			[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",key] dataUsingEncoding:NSUTF8StringEncoding]];
			[postBody appendData:[[postData objectForKey:key] dataUsingEncoding:NSUTF8StringEncoding]];
			[postBody appendData:endItemBoundary];
		}
		
		//Adds files to upload
		NSData *contentTypeHeader = [[NSString stringWithString:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding];
		e = [fileData keyEnumerator];
		while (key = [e nextObject]) {
			NSString *filePath = [fileData objectForKey:key];
			[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n",key,[filePath lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
			[postBody appendData:contentTypeHeader];
			[postBody appendData:[NSData dataWithContentsOfMappedFile:filePath]];
			[postBody appendData:endItemBoundary];
		}
		
		[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
		
		// Set the body.
		CFHTTPMessageSetBody(request, (CFDataRef)postBody);
		
		postLength = [postBody length];
	}
	
	[self loadRequest];

}


// Start the request
- (void)loadRequest
{
	[authenticationLock release];
	authenticationLock = [[NSConditionLock alloc] initWithCondition:1];
	
	complete = NO;
	totalBytesRead = 0;
	lastBytesRead = 0;
	lastBytesSent = 0;
	contentLength = 0;
	haveExaminedHeaders = NO;
    receivedData = CFDataCreateMutable(NULL, 0);
    
    // Create the stream for the request.
    readStream = CFReadStreamCreateForStreamedHTTPRequest(kCFAllocatorDefault, request,readStream);
    if (!readStream) {
		[self failWithProblem:@"Unable to create read stream"];
        return;
    }
    
    // Set the client
	CFStreamClientContext ctxt = {0, self, NULL, NULL, NULL};
    if (!CFReadStreamSetClient(readStream, kNetworkEvents, ReadStreamClientCallBack, &ctxt)) {
        CFRelease(readStream);
        readStream = NULL;
		[self failWithProblem:@"Unable to setup read stream"];
        return;
    }
    
    // Schedule the stream
    CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    
    // Start the HTTP connection
    if (!CFReadStreamOpen(readStream)) {
        CFReadStreamSetClient(readStream, 0, NULL, NULL);
        CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFRelease(readStream);
        readStream = NULL;
		[self failWithProblem:@"Unable to start http connection"];
        return;
    }

	
	if (uploadProgressDelegate) {
		[self performSelectorOnMainThread:@selector(resetUploadProgress:) withObject:[NSNumber numberWithDouble:postLength] waitUntilDone:YES];
	}

	
	// Wait for the request to finish
	NSDate* endDate = [NSDate distantFuture];
	while (!complete) {
		
		// See if our NSOperationQueue told us to cancel
		if ([self isCancelled]) {
			[self failWithProblem:@"The request was cancelled"];
			[self cancelLoad];
			complete = YES;
			break;
		}
		[self updateProgressIndicators];
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:endDate];
	}
}

// Cancel loading and clean up
- (void)cancelLoad
{
    if (readStream) {
        CFReadStreamClose(readStream);
        CFReadStreamSetClient(readStream, kCFStreamEventNone, NULL, NULL);
        CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFRelease(readStream);
        readStream = NULL;
    }
	
    if (receivedData) {
        CFRelease(receivedData);
        receivedData = NULL;
		
		//If we were downloading to a file, let's remove it
	} else if (downloadDestinationPath) {
		[outputStream close];
		[[NSFileManager defaultManager] removeFileAtPath:downloadDestinationPath handler:nil];
	}
	
	haveExaminedHeaders = NO;
}



#pragma mark upload/download progress


- (void)updateProgressIndicators
{
	[self updateUploadProgress];
	[self updateDownloadProgress];

}

// Rather than reset the value to 0, it simply adds the size of the upload to the max.
// This allows multiple requests to use the same progress indicator, but you'll need to remember to set the indicator's value to 0 before you start!
// Alternatively, change or overidde this method to set the progress to 0 if you're only ever tracking the progress of a single request at a time
- (void)resetUploadProgress:(NSNumber *)max
{
	[uploadProgressDelegate setMaxValue:[uploadProgressDelegate maxValue]+[max doubleValue]];
}		

- (void)updateUploadProgress
{
	if (uploadProgressDelegate) {
		double byteCount = [[(NSNumber *)CFReadStreamCopyProperty (readStream, kCFStreamPropertyHTTPRequestBytesWrittenCount) autorelease] doubleValue];
		[uploadProgressDelegate incrementBy:byteCount-lastBytesSent];
		lastBytesSent = byteCount;
	} 
}


// Will only be called if we get a content-length header.
// Rather than reset the value to 0, it simply adds the size of the download to the max.
// This allows multiple requests to use the same progress indicator, but you'll need to remember to set the indicator's value to 0 before you start!
// Alternatively, change or overidde this method to set the progress to 0 if you're only ever tracking the progress of a single request at a time
- (void)resetDownloadProgress:(NSNumber *)max
{
	[downloadProgressDelegate setMaxValue:[downloadProgressDelegate maxValue]+[max doubleValue]];
}	

- (void)updateDownloadProgress
{
	if (downloadProgressDelegate) {
		[downloadProgressDelegate incrementBy:totalBytesRead-lastBytesRead];
		lastBytesRead = totalBytesRead;
	} 
}

#pragma mark handling request complete / failure


// Subclasses can override this method to process the result in the same thread
// If not overidden, it will call the didFinishSelector on the delegate, if one has been setup
- (void)requestFinished
{
	if (didFinishSelector && ![self isCancelled] && [delegate respondsToSelector:didFinishSelector]) {
		[delegate performSelectorOnMainThread:didFinishSelector withObject:self waitUntilDone:YES];		
	}
}



// Subclasses can override this method to perform error handling in the same thread
// If not overidden, it will call the didFailSelector on the delegate (by default requestFailed:)`
- (void)failWithProblem:(NSString *)problem
{
	complete = YES;
	if (!error) {
		[self setError:[NSError errorWithDomain:NetworkRequestErrorDomain 
									 code:1 
								 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"An error occurred",@"Title",
										   problem,@"Description",nil]]];
		NSLog(problem);
		
		if (didFailSelector && ![self isCancelled] && [delegate respondsToSelector:didFailSelector]) {
			[delegate performSelectorOnMainThread:didFailSelector withObject:self waitUntilDone:YES];		
		}
	}
}


#pragma mark http authentication


// Parse the response headers to get the content-length, and check to see if we need to authenticate
- (BOOL)isAuthorizationFailure
 {
    CFHTTPMessageRef responseHeaders = (CFHTTPMessageRef)CFReadStreamCopyProperty(readStream, kCFStreamPropertyHTTPResponseHeader);
	BOOL isAuthenticationChallenge = NO;
    if (responseHeaders) {
		if (CFHTTPMessageIsHeaderComplete(responseHeaders)) {
			
			// Is the server response a challenge for credentials?
			isAuthenticationChallenge = (CFHTTPMessageGetResponseStatusCode(responseHeaders) == 401);
			
			if (!isAuthenticationChallenge) {
				
				//See if we got a Content-length header
				CFStringRef cLength = CFHTTPMessageCopyHeaderFieldValue(responseHeaders,CFSTR("Content-Length"));
				if (cLength) {
					contentLength = CFStringGetDoubleValue(cLength);
					if (downloadProgressDelegate) {
						[self performSelectorOnMainThread:@selector(resetDownloadProgress:) withObject:[NSNumber numberWithDouble:contentLength] waitUntilDone:YES];
					}
					CFRelease(cLength);
				}
			}

		}
        CFRelease(responseHeaders);

    }	
	return isAuthenticationChallenge;
}

// Called by delegate to resume loading once authentication info has been populated
- (void)retryWithAuthentication
{
	[authenticationLock lockWhenCondition:1];
	[authenticationLock unlockWithCondition:2];
}



- (void)applyCredentialsAndResume {
    // Apply whatever credentials we've built up to the old request
    if (!CFHTTPMessageApplyCredentialDictionary(request, authentication, credentials, NULL)) {
        [self failWithProblem:@"Failed to apply credentials to request"];
    } else {
		
		//If we have credentials and they're ok, let's save them to the keychain
		if (usesKeychain) {
			NSURLCredential *authenticationCredentials = [NSURLCredential credentialWithUser:(NSString *)CFDictionaryGetValue(credentials, kCFHTTPAuthenticationUsername)
																		  password:(NSString *)CFDictionaryGetValue(credentials, kCFHTTPAuthenticationPassword)
																		  persistence:NSURLCredentialPersistencePermanent];
		
			if (authenticationCredentials) {
				[ASIHTTPRequest saveCredentials:authenticationCredentials forHost:[url host] port:[[url port] intValue] protocol:[url scheme] realm:authenticationRealm];
			}
		}
		
        // Now that we've updated our request, retry the load
		[self loadRequest];
    }
}


- (void)applyCredentialsLoad
{
	// Get the authentication information
	if (!authentication) {
		CFHTTPMessageRef responseHeader = (CFHTTPMessageRef) CFReadStreamCopyProperty(readStream,kCFStreamPropertyHTTPResponseHeader);
		authentication = CFHTTPAuthenticationCreateFromResponse(NULL, responseHeader);
		CFRelease(responseHeader);
	}	
	CFStreamError err;
	if (!authentication) {
		// the newly created authentication object is bad, must return
		[self failWithProblem:@"Failed to get authentication object from response headers"];
		return;
	
		
	//Authentication is not valid, we need to get new ones
	} else if (!CFHTTPAuthenticationIsValid(authentication, &err)) {
		
		// destroy authentication and credentials
		if (credentials) {
			CFRelease(credentials);
			credentials = NULL;
		}
		CFRelease(authentication);
		authentication = NULL;
		
		// check for bad credentials (to be treated separately)
		if (err.domain == kCFStreamErrorDomainHTTP && (err.error == kCFStreamErrorHTTPAuthenticationBadUserName || err.error == kCFStreamErrorHTTPAuthenticationBadPassword)) {
			ignoreError = YES;	
			if ([delegate respondsToSelector:@selector(authorizationNeededForRequest:)]) {
				[delegate performSelectorOnMainThread:@selector(authorizationNeededForRequest:) withObject:self waitUntilDone:YES];
				[authenticationLock lockWhenCondition:2];
				[authenticationLock unlock];
				[self applyCredentialsLoad];
				return;
			}
		}
		[self setError:[self authenticationError]];
		complete = YES;
		
		
	} else {
		
		[self cancelLoad];
		
		if (credentials) {
			[self applyCredentialsAndResume];
		
		// are a user name & password needed?
		}  else if (CFHTTPAuthenticationRequiresUserNameAndPassword(authentication)) {


			// Build the credentials dictionary
			credentials = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
			
			
            [authenticationRealm release];
			authenticationRealm = nil;
            
            // Get the authentication realm
            if (!CFHTTPAuthenticationRequiresAccountDomain(authentication)) {
                authenticationRealm = (NSString *)CFHTTPAuthenticationCopyRealm(authentication);
            }
			
			//First, let's look at the url to see if the username and password were included
			CFStringRef user = (CFStringRef)[url user];
			CFStringRef pass = (CFStringRef)[url password];
			
			//If the username and password weren't in the url, let's try to use the ones set in this object
			if ((!user || !pass) && username && password) {
				user = (CFStringRef)username;
				pass = (CFStringRef)password;
			}
			
			//Ok, that didn't work, let's try the keychain
			if ((!user || !pass) && usesKeychain) {
				NSURLCredential *authenticationCredentials = [ASIHTTPRequest savedCredentialsForHost:[url host] port:443 protocol:[url scheme] realm:authenticationRealm];
				if (authenticationCredentials) {
					user = (CFStringRef)[authenticationCredentials user];
					pass = (CFStringRef)[authenticationCredentials password];
				}
				
			}
			
			//If we have a  username and password, let's apply them to the request and continue
			if (user && pass) {
				
				CFDictionarySetValue(credentials, kCFHTTPAuthenticationUsername, user);
				CFDictionarySetValue(credentials, kCFHTTPAuthenticationPassword, pass);	
				
				[self applyCredentialsAndResume];
				return;
			}
			if (credentials) {
				CFRelease(credentials);
				credentials = NULL;
			}
			//We've got no credentials, let's ask the delegate to sort this out
			ignoreError = YES;	
			if ([delegate respondsToSelector:@selector(authorizationNeededForRequest:)]) {
				[delegate performSelectorOnMainThread:@selector(authorizationNeededForRequest:) withObject:self waitUntilDone:YES];
				[authenticationLock lockWhenCondition:2];
				[authenticationLock unlock];
				[self applyCredentialsLoad];
				return;
			}
			[self setError:[self authenticationError]];
			complete = YES;
			return;
			

		//We don't need a username or password, let's carry on
		} else {
			[self applyCredentialsAndResume];
		}
	}	
}

- (NSError *)authenticationError
{
	return [NSError errorWithDomain:NetworkRequestErrorDomain 
							   code:2 
						   userInfo:[NSDictionary dictionaryWithObjectsAndKeys: @"Permission Denied",@"Title",
									 @"Your username and password were incorrect.",@"Description",nil]];
	
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

	if (!haveExaminedHeaders) {
		haveExaminedHeaders = YES;
		if ([self isAuthorizationFailure]) {
			[self applyCredentialsLoad];
			return;
		}
	}

    UInt8 buffer[2048];
    CFIndex bytesRead = CFReadStreamRead(readStream, buffer, sizeof(buffer));
	  
	
    // Less than zero is an error
    if (bytesRead < 0) {
        [self handleStreamError];
    
    // If zero bytes were read, wait for the EOF to come.
    } else if (bytesRead) {
	
		totalBytesRead += bytesRead;
	
		// Are we downloading to a file?
		if (downloadDestinationPath) {
			if (!outputStream) {
				outputStream = [[NSOutputStream alloc] initToFileAtPath:downloadDestinationPath append:NO];
				[outputStream open];
			}
			[outputStream write:buffer maxLength:bytesRead];
			
		//Otherwise, let's add the data to our in-memory store
		} else {
			CFDataAppendBytes(receivedData, buffer, bytesRead);
		}
    }
}


- (void)handleStreamComplete
{
	complete = YES;
	[self updateUploadProgress];
	[self updateDownloadProgress];
    if (readStream) {
        CFReadStreamClose(readStream);
        CFReadStreamSetClient(readStream, kCFStreamEventNone, NULL, NULL);
        CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFRelease(readStream);
        readStream = NULL;
    }
	
	//close the output stream as we're done writing to the file
	if (downloadDestinationPath) {
		[outputStream close];
	}

	[self requestFinished];
}


- (void)handleStreamError
{
	complete = YES;	
	NSError *err = [(NSError *)CFReadStreamCopyError(readStream) autorelease];

	[self cancelLoad];
	
	if (!error) { //We may already have handled this error
		[self failWithProblem:[NSString stringWithFormat: @"An error occurred: %@",[err localizedDescription]]];
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

@synthesize url;
@synthesize delegate;
@synthesize uploadProgressDelegate;
@synthesize downloadProgressDelegate;
@synthesize usesKeychain;
@synthesize downloadDestinationPath;
@synthesize didFinishSelector;
@synthesize didFailSelector;
@synthesize authenticationRealm;
@synthesize error;
@synthesize complete;

@end
