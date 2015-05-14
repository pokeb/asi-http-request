//
//  ASIS3RequestTests.m
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 12/07/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import "ASISCSRequestTests.h"
#import "ASINetworkQueue.h"
#import "ASIS3BucketObject.h"
#import "ASIS3ObjectRequest.h"
#import "ASIS3BucketRequest.h"
#import "ASIS3ServiceRequest.h"

// Fill in these to run the tests that actually connect and manipulate objects on S3
static NSString *accessKey = @"";
static NSString *secretAccessKey = @"";

// You should run these tests on a bucket that does not yet exist
static NSString *bucket = @"test-009";



// Stop clang complaining about undeclared selectors
@interface ASISCSRequestTests () {
    
	ASINetworkQueue *networkQueue;
	float progress;
}

- (void)GETRequestDone:(ASIHTTPRequest *)request;
- (void)GETRequestFailed:(ASIHTTPRequest *)request;
- (void)PUTRequestDone:(ASIHTTPRequest *)request;
- (void)PUTRequestFailed:(ASIHTTPRequest *)request;
- (void)DELETERequestDone:(ASIHTTPRequest *)request;
- (void)DELETERequestFailed:(ASIHTTPRequest *)request;

@property (retain, nonatomic) ASINetworkQueue *networkQueue;

@end

@implementation ASISCSRequestTests

- (void)logRequest:(ASIHTTPRequest *)request {
    
    GHTestLog(@"Request =============================\n");
    GHTestLog(@"%@: %@", [request requestMethod], [request url]);
    GHTestLog(@"%@", [request requestHeaders]);
    
    GHTestLog(@"\n\nResponse =============================\n");
    GHTestLog(@"%d: %@", [request responseStatusCode], [request responseStatusMessage]);
    GHTestLog(@"%@", [request responseHeaders]);
    GHTestLog(@"%@", [request responseString]);
}


- (NSString *)randomStringWithLength:(int)len {
    
    NSString *letters = @"abcdefghijklmnopqrstuvwxyz0123456789";
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity:len];
    
    for (int i=0; i<len; i++) {
        
        [randomString appendFormat:@"%C", [letters characterAtIndex:arc4random() % [letters length]]];
    }
    
    return randomString;
}


- (void)testListBucket {
    
    ASIS3ServiceRequest *serviceRequest = [ASIS3ServiceRequest serviceRequest];
    [serviceRequest setSecretAccessKey:secretAccessKey];
	[serviceRequest setAccessKey:accessKey];
    
    //[self prepare];
    
    [serviceRequest startSynchronous];
    
    
    [self logRequest:serviceRequest];
    
    GHTestLog(@"%@", [serviceRequest buckets]);
    
	GHAssertNil([serviceRequest error], [NSString stringWithFormat:@"%@, %@", [[serviceRequest error] description], [serviceRequest url]]);
}

- (void)testFailure
{
	// Needs expanding to cover more failure states - this is just a test to ensure Amazon's error description is being added to the error
	
	// We're actually going to try with the Amazon example details, but the request will fail because the date is old
	NSString *exampleSecretAccessKey = @"uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o";
	NSString *exampleAccessKey = @"1234567890";
	NSString *exampleBucket = @"johnsmith";
	NSString *key = @"photos/puppy.jpg";
	NSString *dateString = @"Tue, 27 Mar 2007 19:36:42 +0000";
	ASIS3Request *request = [ASIS3ObjectRequest requestWithBucket:exampleBucket key:key];
	[request setDateString:dateString];
	[request setSecretAccessKey:exampleSecretAccessKey];
	[request setAccessKey:exampleAccessKey];
	[request startSynchronous];
	GHAssertNotNil([request error], @"Failed to generate an error when the request was not correctly signed");
	
	BOOL success = ([[request error] code] == ASIS3ResponseErrorType);
	GHAssertTrue(success, @"Generated error had the wrong error code");
	
	success = ([[[request error] localizedDescription] isEqualToString:@"The provided token has expired.()"]);
	GHAssertTrue(success, @"Generated error had the wrong description");
	
	// Ensure a bucket request will correctly parse an error from S3
	request = [ASIS3BucketRequest requestWithBucket:exampleBucket];
	[request setDateString:dateString];
	[request setSecretAccessKey:exampleSecretAccessKey];
	[request setAccessKey:exampleAccessKey];
	[request startSynchronous];
	GHAssertNotNil([request error],@"Failed to generate an error when the request was not correctly signed");	
	
	success = ([[request error] code] == ASIS3ResponseErrorType);
	GHAssertTrue(success,@"Generated error had the wrong error code");	
	
	success = ([[[request error] localizedDescription] isEqualToString:@"The provided token has expired.()"]);
	GHAssertTrue(success,@"Generated error had the wrong description");
	
	// Ensure a service request will correctly parse an error from S3
	request = [ASIS3ServiceRequest serviceRequest];
	[request setDateString:dateString];
	[request setSecretAccessKey:exampleSecretAccessKey];
	[request setAccessKey:exampleAccessKey];
	[request startSynchronous];
    //[self logRequest:request];
	GHAssertNotNil([request error], @"Failed to generate an error when the request was not correctly signed");	
	
	success = ([[request error] code] == ASIS3ResponseErrorType);
	GHAssertTrue(success, @"Generated error had the wrong error code");
	
	success = ([[[request error] localizedDescription] isEqualToString:@"The provided token has expired.()"]);
	GHAssertTrue(success, @"Generated error had the wrong description");
}

- (void)createTestBucket
{
    //return;
    /*
    if (!bucket) {
        
        [bucket release], bucket = nil;
        bucket = [[NSString stringWithFormat:@"test-%@", [self randomStringWithLength:10]] retain];
    }
     */
    
	// Test creating a bucket
	ASIS3BucketRequest *bucketRequest = [ASIS3BucketRequest PUTRequestWithBucket:bucket];
	[bucketRequest setSecretAccessKey:secretAccessKey];
	[bucketRequest setAccessKey:accessKey];
	[bucketRequest startSynchronous];
    [self logRequest:bucketRequest];
	GHAssertNil([bucketRequest error], @"Failed to create a bucket");
}

// To run this test, uncomment and fill in your S3 access details
- (void)testREST
{
	//[self createTestBucket];
	
	BOOL success = (![secretAccessKey isEqualToString:@""] && ![accessKey isEqualToString:@""] && ![bucket isEqualToString:@""]);
	GHAssertTrue(success, @"You need to supply your S3 access details to run the REST test (see the top of ASIS3RequestTests.m)");
	
	// Test creating a bucket
    
	ASIS3BucketRequest *bucketRequest = [ASIS3BucketRequest PUTRequestWithBucket:bucket];
	[bucketRequest setSecretAccessKey:secretAccessKey];
	[bucketRequest setAccessKey:accessKey];
	[bucketRequest startSynchronous];
	GHAssertNil([bucketRequest error],@"Failed to create a bucket");	
	
     
	// List buckets to make sure the bucket is there
	ASIS3ServiceRequest *serviceRequest = [ASIS3ServiceRequest serviceRequest];
	[serviceRequest setSecretAccessKey:secretAccessKey];
	[serviceRequest setAccessKey:accessKey];
	[serviceRequest startSynchronous];
	GHAssertNil([serviceRequest error],@"Failed to fetch the list of buckets from S3");
	
	BOOL foundBucket = NO;
	for (ASIS3Bucket *theBucket in [serviceRequest buckets]) {
		if ([[theBucket name] isEqualToString:bucket]) {
			foundBucket = YES;
			break;
		}
	}
	GHAssertTrue(foundBucket,@"Failed to retrive the newly-created bucket in a list of buckets");
	
	NSString *key = @"test";
	
	// Create the file
	NSString *text = @"This is my content";
	NSString *filePath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"testfile.txt"];
	[[text dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filePath atomically:NO];
	
	// PUT the file
	ASIS3ObjectRequest *request = [ASIS3ObjectRequest PUTRequestForFile:filePath withBucket:bucket key:key];
	[request setSecretAccessKey:secretAccessKey];
	[request setAccessKey:accessKey];
	[request setStorageClass:ASIS3StorageClassReducedRedundancy];
	[request startSynchronous];
	success = [[request responseString] isEqualToString:@""];
	GHAssertTrue(success,@"Failed to PUT a file to S3");	

	// GET the file
	request = [ASIS3ObjectRequest requestWithBucket:bucket key:key];
	[request setSecretAccessKey:secretAccessKey];
	[request setAccessKey:accessKey];
	[request startSynchronous];
	success = [[request responseString] isEqualToString:@"This is my content"];
	GHAssertTrue(success,@"Failed to GET the correct data from S3");

	// Test fetch subresource
	request = [ASIS3ObjectRequest requestWithBucket:bucket key:key subResource:@"acl"];
	[request setSecretAccessKey:secretAccessKey];
	[request setAccessKey:accessKey];
	[request startSynchronous];
	success = ([[request responseString] rangeOfString:@"<AccessControlPolicy"].location != NSNotFound);
	GHAssertTrue(success,@"Failed to GET a subresource");
	
	// COPY the file
	request = [ASIS3ObjectRequest COPYRequestFromBucket:bucket key:key toBucket:bucket key:@"test-copy"];
	[request setSecretAccessKey:secretAccessKey];
	[request setAccessKey:accessKey];
	[request startSynchronous];
    [self logRequest:request];
	GHAssertNil([request error],@"Failed to COPY a file");
	
	// GET the copy
	request = [ASIS3ObjectRequest requestWithBucket:bucket key:@"test-copy"];
	[request setSecretAccessKey:secretAccessKey];
	[request setAccessKey:accessKey];
	[request startSynchronous];
	success = [[request responseString] isEqualToString:@"This is my content"];
	GHAssertTrue(success,@"Failed to GET the correct data from S3");	
	
	// HEAD the copy
	request = [ASIS3ObjectRequest HEADRequestWithBucket:bucket key:@"test-copy"];
	[request setSecretAccessKey:secretAccessKey];
	[request setAccessKey:accessKey];
	[request startSynchronous];
	success = [[request responseString] isEqualToString:@""];
	GHAssertTrue(success,@"Got a response body for a HEAD request");
	
	// Test listing the objects in this bucket
	ASIS3BucketRequest *listRequest = [ASIS3BucketRequest requestWithBucket:bucket];
	[listRequest setSecretAccessKey:secretAccessKey];
	[listRequest setAccessKey:accessKey];
	[listRequest startSynchronous];
	GHAssertNil([listRequest error],@"Failed to download a list from S3");
	success = [[listRequest objects] count];
	GHAssertTrue(success,@"The file didn't show up in the list");	

	// Test again with a prefix query
	listRequest = [ASIS3BucketRequest requestWithBucket:bucket];
	[listRequest setPrefix:@"test"];
	[listRequest setSecretAccessKey:secretAccessKey];
	[listRequest setAccessKey:accessKey];
	[listRequest startSynchronous];
	GHAssertNil([listRequest error],@"Failed to download a list from S3");
	success = [[listRequest objects] count];
	GHAssertTrue(success,@"The file didn't show up in the list");
	
	// DELETE the file
	request = [ASIS3ObjectRequest requestWithBucket:bucket key:key];
	[request setSecretAccessKey:secretAccessKey];
	[request setRequestMethod:@"DELETE"];
	[request setAccessKey:accessKey];
	[request startSynchronous];
	success = [[request responseString] isEqualToString:@""];
	GHAssertTrue(success,@"Failed to DELETE the file from S3");	
	
	// (Also DELETE the copy we made)
	request = [ASIS3ObjectRequest requestWithBucket:bucket key:@"test-copy"];
	[request setSecretAccessKey:secretAccessKey];
	[request setRequestMethod:@"DELETE"];
	[request setAccessKey:accessKey];
	[request startSynchronous];
	success = [[request responseString] isEqualToString:@""];
	GHAssertTrue(success,@"Failed to DELETE the copy from S3");	
	
	// Attempt to COPY the file, even though it is no longer there
	request = [ASIS3ObjectRequest COPYRequestFromBucket:bucket key:key toBucket:bucket key:@"test-copy"];
	[request setSecretAccessKey:secretAccessKey];
	[request setAccessKey:accessKey];
	[request startSynchronous];
	GHAssertNotNil([request error],@"Failed generate an error for what should have been a failed COPY");
	
	success = [[[request error] localizedDescription] isEqualToString:@"The specified key does not exist."];
	GHAssertTrue(success, @"Got the wrong error message");	
	
	// PUT some data
	NSData *data = [@"Hello" dataUsingEncoding:NSUTF8StringEncoding];
	request = [ASIS3ObjectRequest PUTRequestForData:data withBucket:bucket key:key];
	[request setMimeType:@"text/plain"];
	[request setSecretAccessKey:secretAccessKey];
	[request setAccessKey:accessKey];
	[request startSynchronous];
	success = [[request responseString] isEqualToString:@""];
	GHAssertTrue(success,@"Failed to PUT data to S3");
	
	// GET the data to check it uploaded properly
	request = [ASIS3ObjectRequest requestWithBucket:bucket key:key];
	[request setSecretAccessKey:secretAccessKey];
	[request setAccessKey:accessKey];
	[request startSynchronous];
	success = [[request responseString] isEqualToString:@"Hello"];
	GHAssertTrue(success,@"Failed to GET the correct data from S3");	
	
	// clean up (Delete it)
	request = [ASIS3ObjectRequest requestWithBucket:bucket key:key];
	[request setSecretAccessKey:secretAccessKey];
	[request setRequestMethod:@"DELETE"];
	[request setAccessKey:accessKey];
	[request startSynchronous];
	success = [[request responseString] isEqualToString:@""];
	GHAssertTrue(success,@"Failed to DELETE the file from S3");	
	
	// Delete the bucket
    
	bucketRequest = [ASIS3BucketRequest DELETERequestWithBucket:bucket];
	[bucketRequest setSecretAccessKey:secretAccessKey];
	[bucketRequest setAccessKey:accessKey];
	[bucketRequest startSynchronous];
	GHAssertNil([bucketRequest error],@"Failed to delete a bucket");
	
	
}

// Will upload a file to S3, gzipping it before uploading
// The file will be stored deflate, and automatically inflated when downloaded
// This means the file will take up less storage space, and will upload and download faster
// The file should still be accessible by any HTTP client that supports gzipped responses (eg browsers, NSURLConnection, etc)
- (void)testGZippedContent
{
	[self createTestBucket];
	
	BOOL success = (![secretAccessKey isEqualToString:@""] && ![accessKey isEqualToString:@""] && ![bucket isEqualToString:@""]);
	GHAssertTrue(success,@"You need to supply your S3 access details to run the gzipped put test (see the top of ASIS3RequestTests.m)");
	
	// Create the file
	NSString *text = @"This is my content This is my content This is my content This is my content This is my content This is my content";
	NSString *filePath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"testfile.txt"];
	[[text dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filePath atomically:NO];
	
	NSString *key = @"gzipped-data";
	ASIS3ObjectRequest *request = [ASIS3ObjectRequest PUTRequestForFile:filePath withBucket:bucket key:key];
	[request setSecretAccessKey:secretAccessKey];
	[request setAccessKey:accessKey];
	[request setShouldCompressRequestBody:YES];
	[request setAccessPolicy:ASIS3AccessPolicyPublicRead]; // We'll make it public
	[request startSynchronous];
	success = [[request responseString] isEqualToString:@""];
	GHAssertTrue(success,@"Failed to PUT the gzipped file");		
	
	// GET the file
	request = [ASIS3ObjectRequest requestWithBucket:bucket key:key];
	[request setSecretAccessKey:secretAccessKey];
	[request setAccessKey:accessKey];
	[request startSynchronous];
	success = [[request responseString] isEqualToString:text];
	GHAssertTrue(success,@"Failed to GET the correct data from S3");	
	
	success = [[[request responseHeaders] valueForKey:@"Content-Encoding"] isEqualToString:@"gzip"];
	GHAssertTrue(success,@"Failed to GET the correct data from S3");	
	
	// Now grab the data using something other than ASIHTTPRequest to ensure other HTTP clients can parse the gzipped content
	NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@.sinastorage.cn/gzipped-data",bucket]]] returningResponse:NULL error:NULL];
	NSString *string = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding] autorelease];
	success = [string isEqualToString:text];
	GHAssertTrue(success,@"Failed to GET the correct data from S3");	
	
	// Cleanup
	request = [ASIS3ObjectRequest DELETERequestWithBucket:bucket key:key];
	[request setSecretAccessKey:secretAccessKey];
	[request setAccessKey:accessKey];
	[request startSynchronous];
	
}


- (void)testListRequest
{	
	[self createTestBucket];
	
	BOOL success = (![secretAccessKey isEqualToString:@""] && ![accessKey isEqualToString:@""] && ![bucket isEqualToString:@""]);
	GHAssertTrue(success,@"You need to supply your S3 access details to run the list test (see the top of ASIS3RequestTests.m)");
	
	// Firstly, create and upload 5 files
	short i;
	for (i=0; i<5; i++) {
		NSString *text = [NSString stringWithFormat:@"This is the content of file #%hi",i];
		NSString *filePath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:[NSString stringWithFormat:@"%hi.txt",i]];
		[[text dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filePath atomically:NO];
		NSString *key = [NSString stringWithFormat:@"test-file/%hi",i];
		ASIS3ObjectRequest *request = [ASIS3ObjectRequest PUTRequestForFile:filePath withBucket:bucket key:key];
		[request setSecretAccessKey:secretAccessKey];
		[request setAccessKey:accessKey];
		[request startSynchronous];
		GHAssertNil([request error],@"Give up on list request test - failed to upload a file");	
	}
	
	// Test common prefixes
	ASIS3BucketRequest *listRequest = [ASIS3BucketRequest requestWithBucket:bucket];
	[listRequest setSecretAccessKey:secretAccessKey];
	[listRequest setAccessKey:accessKey];
	[listRequest setDelimiter:@"/"];
	[listRequest startSynchronous];
    [self logRequest:listRequest];
    GHTestLog(@"%@", listRequest.objects);
	GHAssertNil([listRequest error],@"Failed to download a list from S3");
	success = NO;
	for (NSString *prefix in [listRequest commonPrefixes]) {
		if ([prefix isEqualToString:@"test-file/"]) {
			success = YES;
		}
	}
	GHAssertTrue(success,@"Failed to obtain a list of common prefixes");
	
	
	// Test truncation
	listRequest = [ASIS3BucketRequest requestWithBucket:bucket];
	[listRequest setSecretAccessKey:secretAccessKey];
	[listRequest setAccessKey:accessKey];
	[listRequest setMaxResultCount:1];
	[listRequest startSynchronous];
    [self logRequest:listRequest];
	GHAssertTrue([listRequest isTruncated],@"Failed to identify what should be a truncated list of results");
	
	// Test urls are built correctly when requesting a subresource
	listRequest = [ASIS3BucketRequest requestWithBucket:bucket subResource:@"acl"];
	[listRequest setSecretAccessKey:secretAccessKey];
	[listRequest setAccessKey:accessKey];
	[listRequest setDelimiter:@"/"];
	[listRequest setPrefix:@"foo"];
	[listRequest setMarker:@"bar"];
	[listRequest setMaxResultCount:5];
	[listRequest buildURL];
	NSString *expectedURL = [NSString stringWithFormat:@"http://%@.sinastorage.cn/?acl&prefix=foo&marker=bar&delimiter=/&max-keys=5",bucket];
	success = ([[[listRequest url] absoluteString] isEqualToString:expectedURL]);
	GHAssertTrue(success,@"Generated the wrong url when requesting a subresource");
	
	
	// Now get a list of the files
	listRequest = [ASIS3BucketRequest requestWithBucket:bucket];
	[listRequest setPrefix:@"test-file"];
	[listRequest setSecretAccessKey:secretAccessKey];
	[listRequest setAccessKey:accessKey];
	[listRequest startSynchronous];
    [self logRequest:listRequest];
	GHAssertNil([listRequest error],@"Failed to download a list from S3");
	success = ([[listRequest objects] count] == 5);
	GHAssertTrue(success,@"List did not contain all files");
	
	// Please don't use an autoreleased operation queue with waitUntilAllOperationsAreFinished in your own code unless you're writing a test like this one
	// (The end result is no better than using synchronous requests) thx - Ben :)
	ASINetworkQueue *queue = [[[ASINetworkQueue alloc] init] autorelease];
	
	// Test fetching all the items
	[queue setRequestDidFinishSelector:@selector(GETRequestDone:)];
	[queue setRequestDidFailSelector:@selector(GETRequestFailed:)];
	[queue setDelegate:self];
	for (ASIS3BucketObject *object in [listRequest objects]) {
		ASIS3ObjectRequest *request = [object GETRequest];
		[request setAccessKey:accessKey];
		[request setSecretAccessKey:secretAccessKey];
		[queue addOperation:request];
	}
	[queue go];
	[queue waitUntilAllOperationsAreFinished];
	
	
	// Test uploading new files for all the items
	[queue setRequestDidFinishSelector:@selector(PUTRequestDone:)];
	[queue setRequestDidFailSelector:@selector(PUTRequestFailed:)];
	[queue setDelegate:self];
	i=0;
	// For each one, we'll just upload the same content again
	for (ASIS3BucketObject *object in [listRequest objects]) {
		NSString *oldFilePath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:[NSString stringWithFormat:@"%hi.txt",i]];;
		ASIS3Request *request = [object PUTRequestWithFile:oldFilePath];
		[request setAccessKey:accessKey];
		[request setSecretAccessKey:secretAccessKey];
		[queue addOperation:request];
		i++;
	}
	[queue go];
	[queue waitUntilAllOperationsAreFinished];
	
	
	// Test deleting all the items
	[queue setRequestDidFinishSelector:@selector(DELETERequestDone:)];
	[queue setRequestDidFailSelector:@selector(DELETERequestFailed:)];
	[queue setDelegate:self];
	i=0;

	for (ASIS3BucketObject *object in [listRequest objects]) {
		ASIS3ObjectRequest *request = [object DELETERequest];
		[request setAccessKey:accessKey];
		[request setSecretAccessKey:secretAccessKey];
		[queue addOperation:request];
		i++;
	}
	[queue go];
	[queue waitUntilAllOperationsAreFinished];
	
	// Grab the list again, it should be empty now
	listRequest = [ASIS3BucketRequest requestWithBucket:bucket];
	[listRequest setPrefix:@"test-file"];
	[listRequest setSecretAccessKey:secretAccessKey];
	[listRequest setAccessKey:accessKey];
	[listRequest startSynchronous];
	GHAssertNil([listRequest error],@"Failed to download a list from S3");
	success = ([[listRequest objects] count] == 0);
	GHAssertTrue(success,@"List contained files that should have been deleted");
	
}

- (void)GETRequestDone:(ASIS3Request *)request
{
    [self logRequest:request];
	NSString *expectedContent = [NSString stringWithFormat:@"This is the content of file #%@",[[[request url] absoluteString] lastPathComponent]];
	BOOL success = ([[request responseString] isEqualToString:expectedContent]);
	GHAssertTrue(success,@"Got the wrong content when downloading one of the files");
	
}

- (void)GETRequestFailed:(ASIS3Request *)request
{
    [self logRequest:request];
	GHAssertTrue(NO,@"GET request failed for one of the items in the list");
}

- (void)PUTRequestDone:(ASIS3Request *)request
{
    [self logRequest:request];
}

- (void)PUTRequestFailed:(ASIS3Request *)request
{
    [self logRequest:request];
	GHAssertTrue(NO,@"PUT request failed for one of the items in the list");
}

- (void)DELETERequestDone:(ASIS3Request *)request
{
    [self logRequest:request];
}

- (void)DELETERequestFailed:(ASIS3Request *)request
{
    [self logRequest:request];
	GHAssertTrue(NO,@"DELETE request failed for one of the items in the list");
}



- (void)s3RequestFailed:(ASIHTTPRequest *)request
{
    [self logRequest:request];
	GHFail(@"Request failed - cannot continue with test");
	[[self networkQueue] cancelAllOperations];
}

- (void)s3QueueFinished:(ASINetworkQueue *)queue
{
//	BOOL success = (progress == 1.0);
//	GHAssertTrue(success,@"Failed to update progress properly");
}


- (void)testQueueProgress
{
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/i/logo.png"]];
	[request startSynchronous];
	NSData *data = [request responseData];
	
	[self createTestBucket];

	// Upload objects
	progress = 0;	
	[[self networkQueue] cancelAllOperations];
	[self setNetworkQueue:[ASINetworkQueue queue]];
	[[self networkQueue] setDelegate:self];
	[[self networkQueue] setRequestDidFailSelector:@selector(s3RequestFailed:)];
	[[self networkQueue] setQueueDidFinishSelector:@selector(s3QueueFinished:)];	
	[[self networkQueue] setUploadProgressDelegate:self];
	[[self networkQueue] setShowAccurateProgress:YES];
	[[self networkQueue] setMaxConcurrentOperationCount:1];
	
	short i;
	for (i=0; i<5; i++) {
		
		NSString *key = [NSString stringWithFormat:@"stuff/file%hi.txt", (short)(i+1)];
		
		ASIS3ObjectRequest *s3Request = [ASIS3ObjectRequest PUTRequestForData:data withBucket:bucket key:key];
		[s3Request setSecretAccessKey:secretAccessKey];
		[s3Request setAccessKey:accessKey];
		[s3Request setTimeOutSeconds:20];
		[s3Request setNumberOfTimesToRetryOnTimeout:3];
		[s3Request setMimeType:@"image/png"];
		[[self networkQueue] addOperation:s3Request];
	}
	[[self networkQueue] go];
	[[self networkQueue] waitUntilAllOperationsAreFinished];

	
	// Download objects
	progress = 0;	
	[[self networkQueue] cancelAllOperations];
	[self setNetworkQueue:[ASINetworkQueue queue]];
	[[self networkQueue] setDelegate:self];
	[[self networkQueue] setRequestDidFailSelector:@selector(s3RequestFailed:)];
	[[self networkQueue] setQueueDidFinishSelector:@selector(s3QueueFinished:)];	
	[[self networkQueue] setDownloadProgressDelegate:self];
	[[self networkQueue] setShowAccurateProgress:YES];
	
	for (i=0; i<5; i++) {
		
		NSString *key = [NSString stringWithFormat:@"stuff/file%hi.txt", (short)(i+1)];
		
		ASIS3ObjectRequest *s3Request = [ASIS3ObjectRequest requestWithBucket:bucket key:key];
		[s3Request setSecretAccessKey:secretAccessKey];
		[s3Request setAccessKey:accessKey];
		NSString *downloadPath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:[NSString stringWithFormat:@"%hi.jpg", (short)(i+1)]];
		[s3Request setDownloadDestinationPath:downloadPath];
		[[self networkQueue] addOperation:s3Request];
	}
	
	[[self networkQueue] go];
	[[self networkQueue] waitUntilAllOperationsAreFinished];
	progress = 0;
	
	// Delete objects
	progress = 0;
	
	[[self networkQueue] cancelAllOperations];
	[self setNetworkQueue:[ASINetworkQueue queue]];
	[[self networkQueue] setDelegate:self];
	[[self networkQueue] setRequestDidFailSelector:@selector(s3RequestFailed:)];
	[[self networkQueue] setShowAccurateProgress:YES];
	

	for (i=0; i<5; i++) {
		
		NSString *key = [NSString stringWithFormat:@"stuff/file%hi.txt", (short)(i+1)];
		
		ASIS3ObjectRequest *s3Request = [ASIS3ObjectRequest DELETERequestWithBucket:bucket key:key];
		[s3Request setSecretAccessKey:secretAccessKey];
		[s3Request setAccessKey:accessKey];
		[[self networkQueue] addOperation:s3Request];
	}
	[[self networkQueue] go];
	[[self networkQueue] waitUntilAllOperationsAreFinished];

}
	
// Will be called on Mac OS
- (void)setDoubleValue:(double)newProgress;
{
	progress = (float)newProgress;
}

 - (void)setProgress:(float)newProgress;
{
	progress = newProgress;
}


- (void)testCopy
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	ASIS3ObjectRequest *request = [ASIS3ObjectRequest requestWithBucket:@"foo" key:@"eep"];
	ASIS3ObjectRequest *request2 = [request copy];
	GHAssertNotNil(request2,@"Failed to create a copy");
	
	[pool release];
	
	BOOL success = ([request2 retainCount] > 0);
	GHAssertTrue(success,@"Failed to create a retained copy");
	success = ([request2 isKindOfClass:[ASIS3Request class]]);
	GHAssertTrue(success,@"Copy is of wrong class");
	
	[request2 release];
	
	pool = [[NSAutoreleasePool alloc] init];

	
	ASIS3BucketRequest *request3 = [ASIS3BucketRequest requestWithBucket:@"foo"];
	ASIS3BucketRequest *request4 = [request3 copy];
	GHAssertNotNil(request4,@"Failed to create a copy");
	
	[pool release];
	
	success = ([request4 retainCount] > 0);
	GHAssertTrue(success,@"Failed to create a retained copy");
	success = ([request4 isKindOfClass:[ASIS3BucketRequest class]]);
	GHAssertTrue(success,@"Copy is of wrong class");
	
	[request4 release];
	
	pool = [[NSAutoreleasePool alloc] init];

	
	ASIS3BucketObject *bucketObject = [ASIS3BucketObject objectWithBucket:@"foo"];
	ASIS3BucketObject *bucketObject2 = [bucketObject copy];
	GHAssertNotNil(bucketObject2,@"Failed to create a copy");
	
	[pool release];
	
	success = ([bucketObject2 retainCount] > 0);
	GHAssertTrue(success,@"Failed to create a retained copy");
	
	[bucketObject2 release];
}


- (void)testHTTPS
{
	[ASIS3Request setSharedAccessKey:accessKey];
	[ASIS3Request setSharedSecretAccessKey:secretAccessKey];

	// Create a bucket
    
	ASIS3Request *request = [ASIS3BucketRequest PUTRequestWithBucket:bucket];
    [request setValidatesSecureCertificate:NO];
	[request setRequestScheme:ASIS3RequestSchemeHTTPS];
	[request startSynchronous];
	GHAssertNil([request error],@"Failed to create a bucket");
    
    
    //ASIS3Request *request;

	// PUT something in it
	NSString *key = @"king";
	request = [ASIS3ObjectRequest PUTRequestForData:[@"fink" dataUsingEncoding:NSUTF8StringEncoding] withBucket:bucket key:key];
	[request setRequestScheme:ASIS3RequestSchemeHTTPS];
	[request startSynchronous];
	BOOL success = [[request responseString] isEqualToString:@""];
	GHAssertTrue(success,@"Failed to PUT some data into S3");

	// GET it
	request = [ASIS3ObjectRequest requestWithBucket:bucket key:key];
	[request setRequestScheme:ASIS3RequestSchemeHTTPS];
	[request startSynchronous];
	success = [[request responseString] isEqualToString:@"fink"];
	GHAssertTrue(success,@"Failed to GET the correct data from S3");

	// DELETE it
	request = [ASIS3ObjectRequest DELETERequestWithBucket:bucket key:@"king"];
	[request setRequestScheme:ASIS3RequestSchemeHTTPS];
	[request startSynchronous];
	success = [[request responseString] isEqualToString:@""];
	GHAssertTrue(success,@"Failed to DELETE the object from S3");

	// Delete the bucket
    
	request = [ASIS3BucketRequest DELETERequestWithBucket:bucket];
	[request setRequestScheme:ASIS3RequestSchemeHTTPS];
	[request startSynchronous];
	GHAssertNil([request error],@"Failed to delete a bucket");

    //sleep(1);
    
    
	[ASIS3Request setSharedAccessKey:nil];
	[ASIS3Request setSharedSecretAccessKey:nil];
}

// Ideally this test would actually parse the ACL XML and check it, but for now it just makes sure S3 doesn't return an error
- (void)testCannedACLs
{
	[ASIS3Request setSharedAccessKey:accessKey];
	[ASIS3Request setSharedSecretAccessKey:secretAccessKey];

	// Create a bucket
    
	ASIS3Request *request = [ASIS3BucketRequest PUTRequestWithBucket:bucket];
	[request setRequestScheme:ASIS3RequestSchemeHTTPS];
	[request startSynchronous];
	GHAssertNil([request error],@"Failed to create a bucket");
    
    
    //ASIS3Request *request;

	NSArray *ACLs = [NSArray arrayWithObjects:ASIS3AccessPolicyPrivate, ASIS3AccessPolicyPublicRead, ASIS3AccessPolicyPublicReadWrite, ASIS3AccessPolicyAuthenticatedRead, nil];

	for (NSString *cannedACL in ACLs) {
		// PUT object
		NSString *key = @"king";
		request = [ASIS3ObjectRequest PUTRequestForData:[@"fink" dataUsingEncoding:NSUTF8StringEncoding] withBucket:bucket key:key];
		[request setAccessPolicy:cannedACL];
		[request startSynchronous];
        [self logRequest:request];
		GHAssertNil([request error],@"Failed to PUT some data into S3");
        
        //sleep(1);
        
		// GET object ACL
		request = [ASIS3ObjectRequest requestWithBucket:bucket key:key subResource:@"acl"];
		[request startSynchronous];
        [self logRequest:request];
		GHAssertNil([request error],@"Failed to fetch the object");
	}

	// DELETE it
	request = [ASIS3ObjectRequest DELETERequestWithBucket:bucket key:@"king"];
	[request setRequestScheme:ASIS3RequestSchemeHTTPS];
	[request startSynchronous];
	BOOL success = [[request responseString] isEqualToString:@""];
	GHAssertTrue(success,@"Failed to DELETE the object from S3");

	// Delete the bucket
    
	request = [ASIS3BucketRequest DELETERequestWithBucket:bucket];
	[request setRequestScheme:ASIS3RequestSchemeHTTPS];
	[request startSynchronous];
	GHAssertNil([request error],@"Failed to delete a bucket");
    

	[ASIS3Request setSharedAccessKey:nil];
	[ASIS3Request setSharedSecretAccessKey:nil];
}


@synthesize networkQueue;

@end
