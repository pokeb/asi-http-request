//
//  ASIS3RequestTests.m
//  asi-http-request
//
//  Created by Ben Copsey on 12/07/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import "ASIS3RequestTests.h"
#import "ASIS3ListRequest.h"
#import "ASINetworkQueue.h"
#import "ASIS3BucketObject.h"


// Fill in these to run the tests that actually connect and manipulate objects on S3
static NSString *secretAccessKey = @"";
static NSString *accessKey = @"";
static NSString *bucket = @"";



// Used for subclass test
@interface ASIS3RequestSubclass : ASIS3Request {}
@end
@implementation ASIS3RequestSubclass;
@end
@interface ASIS3ListRequestSubclass : ASIS3ListRequest {}
@end
@implementation ASIS3ListRequestSubclass;
@end
@interface ASIS3BucketObjectSubclass : ASIS3BucketObject {}
@end
@implementation ASIS3BucketObjectSubclass;
@end

@implementation ASIS3RequestTests

// All these tests are based on Amazon's examples at: http://docs.amazonwebservices.com/AmazonS3/2006-03-01/
- (void)testAuthenticationHeaderGeneration
{
	NSString *exampleSecretAccessKey = @"uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o";
	NSString *exampleAccessKey = @"0PN5J17HBGZHT7JJ3X82";
	NSString *bucket = @"johnsmith";
	
	// Test GET
	NSString *path = @"/photos/puppy.jpg";
	NSString *dateString = @"Tue, 27 Mar 2007 19:36:42 +0000";
	ASIS3Request *request = [ASIS3Request requestWithBucket:bucket path:path];
	[request setDateString:dateString];
	[request setSecretAccessKey:exampleSecretAccessKey];
	[request setAccessKey:exampleAccessKey];
	[request buildRequestHeaders];
	BOOL success = [[[request requestHeaders] valueForKey:@"Authorization"] isEqualToString:@"AWS 0PN5J17HBGZHT7JJ3X82:xXjDGYUmKxnwqr5KXNPGldn5LbA="];
	GHAssertTrue(success,@"Failed to generate the correct authorisation header for a GET request");
	
	// Test PUT
	path = @"/photos/puppy.jpg";
	dateString = @"Tue, 27 Mar 2007 21:15:45 +0000";
	request = [ASIS3Request requestWithBucket:bucket path:path];
	[request setRequestMethod:@"PUT"];
	[request setMimeType:@"image/jpeg"];
	[request setDateString:dateString];
	[request setSecretAccessKey:exampleSecretAccessKey];
	[request setAccessKey:exampleAccessKey];
	[request buildRequestHeaders];
	success = [[[request requestHeaders] valueForKey:@"Authorization"] isEqualToString:@"AWS 0PN5J17HBGZHT7JJ3X82:hcicpDDvL9SsO6AkvxqmIWkmOuQ="];
	GHAssertTrue(success,@"Failed to generate the correct authorisation header for a PUT request");	
	
	// Test List
	dateString = @"Tue, 27 Mar 2007 19:42:41 +0000";
	ASIS3ListRequest *listRequest = [ASIS3ListRequest listRequestWithBucket:bucket];
	[listRequest setPrefix:@"photos"];
	[listRequest setMaxResultCount:50];
	[listRequest setMarker:@"puppy"];
	[listRequest setDateString:dateString];
	[listRequest setSecretAccessKey:exampleSecretAccessKey];
	[listRequest setAccessKey:exampleAccessKey];
	[listRequest buildRequestHeaders];
	success = [[[listRequest requestHeaders] valueForKey:@"Authorization"] isEqualToString:@"AWS 0PN5J17HBGZHT7JJ3X82:jsRt/rhG+Vtp88HrYL706QhE4w4="];
	GHAssertTrue(success,@"Failed to generate the correct authorisation header for a list request");
	
	// Test fetch ACL
	path = @"/?acl";
	dateString = @"Tue, 27 Mar 2007 19:44:46 +0000";
	request = [ASIS3Request requestWithBucket:bucket path:path];
	[request setDateString:dateString];
	[request setSecretAccessKey:exampleSecretAccessKey];
	[request setAccessKey:exampleAccessKey];
	[request buildRequestHeaders];
	success = [[[request requestHeaders] valueForKey:@"Authorization"] isEqualToString:@"AWS 0PN5J17HBGZHT7JJ3X82:thdUi9VAkzhkniLj96JIrOPGi0g="];
	GHAssertTrue(success,@"Failed to generate the correct authorisation header for a list request");	
	
	// Test Unicode keys
	// (I think Amazon's name for this example is misleading since this test actually only uses URL encoded strings)
	bucket = @"dictionary";
	path = @"/fran%C3%A7ais/pr%c3%a9f%c3%a8re";
	dateString = @"Wed, 28 Mar 2007 01:49:49 +0000";
	request = [ASIS3Request requestWithBucket:bucket path:path];
	[request setDateString:dateString];
	[request setSecretAccessKey:exampleSecretAccessKey];
	[request setAccessKey:exampleAccessKey];
	[request buildRequestHeaders];
	success = [[[request requestHeaders] valueForKey:@"Authorization"] isEqualToString:@"AWS 0PN5J17HBGZHT7JJ3X82:dxhSBHoI6eVSPcXJqEghlUzZMnY="];
	GHAssertTrue(success,@"Failed to generate the correct authorisation header for a list request");		
}

- (void)testFailure
{
	// Needs expanding to cover more failure states - this is just a test to ensure Amazon's error description is being added to the error
	
	// We're actually going to try with the Amazon example details, but the request will fail because the date is old
	NSString *exampleSecretAccessKey = @"uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o";
	NSString *exampleAccessKey = @"0PN5J17HBGZHT7JJ3X82";
	NSString *bucket = @"johnsmith";
	NSString *path = @"/photos/puppy.jpg";
	NSString *dateString = @"Tue, 27 Mar 2007 19:36:42 +0000";
	ASIS3Request *request = [ASIS3Request requestWithBucket:bucket path:path];
	[request setDateString:dateString];
	[request setSecretAccessKey:exampleSecretAccessKey];
	[request setAccessKey:exampleAccessKey];
	[request start];
	GHAssertNotNil([request error],@"Failed to generate an error when the request was not correctly signed");
	
	BOOL success = ([[request error] code] == ASIS3ResponseErrorType);
	GHAssertTrue(success,@"Generated error had the wrong error code");	
	
	success = ([[[request error] localizedDescription] isEqualToString:@"The difference between the request time and the current time is too large."]);
	GHAssertTrue(success,@"Generated error had the wrong description");	
	
}

// To run this test, uncomment and fill in your S3 access details
- (void)testREST
{

	BOOL success = (![secretAccessKey isEqualToString:@""] && ![accessKey isEqualToString:@""] && ![bucket isEqualToString:@""]);
	GHAssertTrue(success,@"You need to supply your S3 access details to run the REST test (see the top of ASIS3RequestTests.m)");
	
	NSString *path = @"/test";
	
	// Create the file
	NSString *text = @"This is my content";
	NSString *filePath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"testfile.txt"];
	[[text dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filePath atomically:NO];
	
	// PUT the file
	ASIS3Request *request = [ASIS3Request PUTRequestForFile:filePath withBucket:bucket path:path];
	[request setSecretAccessKey:secretAccessKey];
	[request setAccessKey:accessKey];
	[request start];
	success = [[request responseString] isEqualToString:@""];
	GHAssertTrue(success,@"Failed to PUT a file to S3");	

	// GET the file
	request = [ASIS3Request requestWithBucket:bucket path:path];
	[request setSecretAccessKey:secretAccessKey];
	[request setAccessKey:accessKey];
	[request start];
	success = [[request responseString] isEqualToString:@"This is my content"];
	GHAssertTrue(success,@"Failed to GET the correct data from S3");
	
	// COPY the file
	request = [ASIS3Request COPYRequestFromBucket:bucket path:path toBucket:bucket path:@"/test-copy"];
	[request setSecretAccessKey:secretAccessKey];
	[request setAccessKey:accessKey];
	[request start];
	GHAssertNil([request error],@"Failed to COPY a file");
	
	// GET the copy
	request = [ASIS3Request requestWithBucket:bucket path:@"/test-copy"];
	[request setSecretAccessKey:secretAccessKey];
	[request setAccessKey:accessKey];
	[request start];
	success = [[request responseString] isEqualToString:@"This is my content"];
	GHAssertTrue(success,@"Failed to GET the correct data from S3");	
	
	
	// HEAD the copy
	request = [ASIS3Request HEADRequestWithBucket:bucket path:@"/test-copy"];
	[request setSecretAccessKey:secretAccessKey];
	[request setAccessKey:accessKey];
	[request start];
	success = [[request responseString] isEqualToString:@""];
	GHAssertTrue(success,@"Got a response body for a HEAD request");
	
	// Get a list of files
	ASIS3ListRequest *listRequest = [ASIS3ListRequest listRequestWithBucket:bucket];
	[listRequest setPrefix:@"test"];
	[listRequest setSecretAccessKey:secretAccessKey];
	[listRequest setAccessKey:accessKey];
	[listRequest start];
	GHAssertNil([listRequest error],@"Failed to download a list from S3");
	success = [[listRequest bucketObjects] count];
	GHAssertTrue(success,@"The file didn't show up in the list");	

	// DELETE the file
	request = [ASIS3Request requestWithBucket:bucket path:path];
	[request setSecretAccessKey:secretAccessKey];
	[request setRequestMethod:@"DELETE"];
	[request setAccessKey:accessKey];
	[request start];
	success = [[request responseString] isEqualToString:@""];
	GHAssertTrue(success,@"Failed to DELETE the file from S3");	
	
	// (Also DELETE the copy we made)
	request = [ASIS3Request requestWithBucket:bucket path:@"/test-copy"];
	[request setSecretAccessKey:secretAccessKey];
	[request setRequestMethod:@"DELETE"];
	[request setAccessKey:accessKey];
	[request start];
	success = [[request responseString] isEqualToString:@""];
	GHAssertTrue(success,@"Failed to DELETE the copy from S3");	
	
	// Attempt to COPY the file, even though it is no longer there
	request = [ASIS3Request COPYRequestFromBucket:bucket path:path toBucket:bucket path:@"/test-copy"];
	[request setSecretAccessKey:secretAccessKey];
	[request setAccessKey:accessKey];
	[request start];
	GHAssertNotNil([request error],@"Failed generate an error for what should have been a failed COPY");
	
	success = [[[request error] localizedDescription] isEqualToString:@"The specified key does not exist."];
	GHAssertTrue(success, @"Got the wrong error message");	
}

// Will upload a file to S3, gzipping it before uploading
// The file will be stored deflate, and automatically inflated when downloaded
// This means the file will take up less storage space, and will upload and download faster
// The file should still be accessible by any HTTP client that supports gzipped responses (eg browsers, NSURLConnection, etc)
- (void)testGZippedContent
{
	
	BOOL success = (![secretAccessKey isEqualToString:@""] && ![accessKey isEqualToString:@""] && ![bucket isEqualToString:@""]);
	GHAssertTrue(success,@"You need to supply your S3 access details to run the gzipped put test (see the top of ASIS3RequestTests.m)");
	
	// Create the file
	NSString *text = @"This is my content This is my content This is my content This is my content This is my content This is my content";
	NSString *filePath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"testfile.txt"];
	[[text dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filePath atomically:NO];
	
	NSString *path = @"/gzipped-data";
	ASIS3Request *request = [ASIS3Request PUTRequestForFile:filePath withBucket:bucket path:path];
	[request setSecretAccessKey:secretAccessKey];
	[request setAccessKey:accessKey];
	[request setShouldCompressRequestBody:YES];
	[request setAccessPolicy:ASIS3AccessPolicyPublicRead]; // We'll make it public
	[request start];
	success = [[request responseString] isEqualToString:@""];
	GHAssertTrue(success,@"Failed to PUT the gzipped file");		
	
	// GET the file
	request = [ASIS3Request requestWithBucket:bucket path:path];
	[request setSecretAccessKey:secretAccessKey];
	[request setAccessKey:accessKey];
	[request start];
	success = [[request responseString] isEqualToString:text];
	GHAssertTrue(success,@"Failed to GET the correct data from S3");	
	
	success = [[[request responseHeaders] valueForKey:@"Content-Encoding"] isEqualToString:@"gzip"];
	GHAssertTrue(success,@"Failed to GET the correct data from S3");	
	
	// Now grab the data using something other than ASIHTTPRequest to ensure other HTTP clients can parse the gzipped content
	NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@.s3.amazonaws.com/gzipped-data",bucket]]] returningResponse:NULL error:NULL];
	NSString *string = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding] autorelease];
	success = [string isEqualToString:text];
	GHAssertTrue(success,@"Failed to GET the correct data from S3");		
	
}


- (void)testListRequest
{	

	BOOL success = (![secretAccessKey isEqualToString:@""] && ![accessKey isEqualToString:@""] && ![bucket isEqualToString:@""]);
	GHAssertTrue(success,@"You need to supply your S3 access details to run the list test (see the top of ASIS3RequestTests.m)");
	
	// Firstly, create and upload 5 files
	int i;
	for (i=0; i<5; i++) {
		NSString *text = [NSString stringWithFormat:@"This is the content of file #%hi",i];
		NSString *filePath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:[NSString stringWithFormat:@"%hi.txt",i]];
		[[text dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filePath atomically:NO];
		NSString *path = [NSString stringWithFormat:@"/test-file/%hi",i];
		ASIS3Request *request = [ASIS3Request PUTRequestForFile:filePath withBucket:bucket path:path];
		[request setSecretAccessKey:secretAccessKey];
		[request setAccessKey:accessKey];
		[request start];
		GHAssertNil([request error],@"Give up on list request test - failed to upload a file");	
	}
	
	// Now get a list of the files
	ASIS3ListRequest *listRequest = [ASIS3ListRequest listRequestWithBucket:bucket];
	[listRequest setPrefix:@"test-file"];
	[listRequest setSecretAccessKey:secretAccessKey];
	[listRequest setAccessKey:accessKey];
	[listRequest start];
	GHAssertNil([listRequest error],@"Failed to download a list from S3");
	success = ([[listRequest bucketObjects] count] == 5);
	GHAssertTrue(success,@"List did not contain all files");
	
	// Please don't use an autoreleased operation queue with waitUntilAllOperationsAreFinished in your own code unless you're writing a test like this one
	// (The end result is no better than using synchronous requests) thx - Ben :)
	ASINetworkQueue *queue = [[[ASINetworkQueue alloc] init] autorelease];
	
	// Test fetching all the items
	[queue setRequestDidFinishSelector:@selector(GETRequestDone:)];
	[queue setRequestDidFailSelector:@selector(GETRequestFailed:)];
	[queue setDelegate:self];
	for (ASIS3BucketObject *object in [listRequest bucketObjects]) {
		ASIS3Request *request = [object GETRequest];
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
	for (ASIS3BucketObject *object in [listRequest bucketObjects]) {
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

	for (ASIS3BucketObject *object in [listRequest bucketObjects]) {
		ASIS3Request *request = [object DELETERequest];
		[request setAccessKey:accessKey];
		[request setSecretAccessKey:secretAccessKey];
		[queue addOperation:request];
		i++;
	}
	[queue go];
	[queue waitUntilAllOperationsAreFinished];
	
	// Grab the list again, it should be empty now
	listRequest = [ASIS3ListRequest listRequestWithBucket:bucket];
	[listRequest setPrefix:@"test-file"];
	[listRequest setSecretAccessKey:secretAccessKey];
	[listRequest setAccessKey:accessKey];
	[listRequest start];
	GHAssertNil([listRequest error],@"Failed to download a list from S3");
	success = ([[listRequest bucketObjects] count] == 0);
	GHAssertTrue(success,@"List contained files that should have been deleted");
	
}

- (void)GETRequestDone:(ASIS3Request *)request
{
	NSString *expectedContent = [NSString stringWithFormat:@"This is the content of file #%@",[[[request url] absoluteString] lastPathComponent]];
	BOOL success = ([[request responseString] isEqualToString:expectedContent]);
	GHAssertTrue(success,@"Got the wrong content when downloading one of the files");
	
}

- (void)GETRequestFailed:(ASIS3Request *)request
{
	GHAssertTrue(NO,@"GET request failed for one of the items in the list");
}

- (void)PUTRequestDone:(ASIS3Request *)request
{
}

- (void)PUTRequestFailed:(ASIS3Request *)request
{
	GHAssertTrue(NO,@"PUT request failed for one of the items in the list");
}

- (void)DELETERequestDone:(ASIS3Request *)request
{
}

- (void)DELETERequestFailed:(ASIS3Request *)request
{
	GHAssertTrue(NO,@"DELETE request failed for one of the items in the list");
}


// Ensure class convenience constructors return an instance of our subclass
- (void)testSubclasses
{
	ASIS3RequestSubclass *instance = [ASIS3RequestSubclass requestWithBucket:@"bucket" path:@"path"];
	BOOL success = [instance isKindOfClass:[ASIS3RequestSubclass class]];
	GHAssertTrue(success,@"Convenience constructor failed to return an instance of the correct class");	

	instance = [ASIS3RequestSubclass PUTRequestForFile:@"/file" withBucket:@"bucket" path:@"path"];
	success = [instance isKindOfClass:[ASIS3RequestSubclass class]];
	GHAssertTrue(success,@"Convenience constructor failed to return an instance of the correct class");	
	
	instance = [ASIS3RequestSubclass DELETERequestWithBucket:@"bucket" path:@"path"];
	success = [instance isKindOfClass:[ASIS3RequestSubclass class]];
	GHAssertTrue(success,@"Convenience constructor failed to return an instance of the correct class");	
	
	instance = [ASIS3RequestSubclass COPYRequestFromBucket:@"bucket" path:@"path" toBucket:@"bucket" path:@"path2"];
	success = [instance isKindOfClass:[ASIS3RequestSubclass class]];
	GHAssertTrue(success,@"Convenience constructor failed to return an instance of the correct class");	
	
	instance = [ASIS3RequestSubclass HEADRequestWithBucket:@"bucket" path:@"path"];
	success = [instance isKindOfClass:[ASIS3RequestSubclass class]];
	GHAssertTrue(success,@"Convenience constructor failed to return an instance of the correct class");	
	
	ASIS3ListRequestSubclass *instance2 = [ASIS3ListRequestSubclass listRequestWithBucket:@"bucket"];
	success = [instance2 isKindOfClass:[ASIS3ListRequestSubclass class]];
	GHAssertTrue(success,@"Convenience constructor failed to return an instance of the correct class");	
	
	ASIS3BucketObjectSubclass *instance3 = [ASIS3BucketObjectSubclass objectWithBucket:@"bucket"];
	success = [instance3 isKindOfClass:[ASIS3BucketObjectSubclass class]];
	GHAssertTrue(success,@"Convenience constructor failed to return an instance of the correct class");	
}


- (void)s3RequestFailed:(ASIHTTPRequest *)request
{
	GHFail(@"Request failed - cannot continue with test");
	[[self networkQueue] cancelAllOperations];
}

- (void)s3QueueFinished:(ASINetworkQueue *)queue
{
	BOOL success = (progress == 1.0);
	GHAssertTrue(success,@"Failed to update progress properly");
}


- (void)testQueueProgress
{
	[[self networkQueue] cancelAllOperations];
	[self setNetworkQueue:[ASINetworkQueue queue]];
	[[self networkQueue] setDelegate:self];
	[[self networkQueue] setRequestDidFailSelector:@selector(s3RequestFailed:)];
	[[self networkQueue] setQueueDidFinishSelector:@selector(s3QueueFinished:)];	
	[[self networkQueue] setDownloadProgressDelegate:self];
	[[self networkQueue] setShowAccurateProgress:YES];
	
	int i;
	for (i=0; i<5; i++) {
		NSString *path = [NSString stringWithFormat:@"/images/%hi.jpg",i+1];
		ASIS3Request *s3Request = [ASIS3Request requestWithBucket:bucket path:path];
		[s3Request setSecretAccessKey:secretAccessKey];
		[s3Request setAccessKey:accessKey];
		NSString *downloadPath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:[NSString stringWithFormat:@"%hi.jpg",i+1]];
		[s3Request setDownloadDestinationPath:downloadPath];
		[[self networkQueue] addOperation:s3Request];
	}
	
	[[self networkQueue] go];

}
	 
 - (void)setProgress:(float)newProgress;
{
	progress = newProgress;
}

@synthesize networkQueue;

@end
