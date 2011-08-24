//
//  ASIDataDecompressorTests.m
//  Mac
//
//  Created by Bob McCune on 24/08/2011.
//  Copyright 2011 All-Seeing Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASITestCase.h"
#import "ASIHTTPRequest.h"
#import "ASIDataDecompressor.h"
#import "ASIDataCompressor.h"
#import <objc/runtime.h>

// Define stub object to aid in testing I/O stream errors
#pragma mark -
#pragma mark NSStream stub object

@interface NSStreamStub : NSObject
@end

@implementation NSStreamStub
- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
	return 1;
}

- (NSInteger)write:(const uint8_t *)buffer maxLength:(NSUInteger)len {
	return 1;
}

- (NSStreamStatus)streamStatus {
	return NSStreamEventErrorOccurred;
}

- (void)open {
	// do nothing
}

- (void)close {
	// do nothing
}

- (NSError *)streamError {
	return [NSError errorWithDomain:@"UnitTestDomain" code:0 userInfo:nil];
}
@end

@interface ASIDataDecompressorStub : NSObject {
@public
	NSError *closeError;
}
@end

@implementation ASIDataDecompressorStub
- (BOOL)streamReady {
	return YES;
}
- (NSData *)uncompressBytes:(Bytef *)bytes length:(NSUInteger)length error:(NSError **)err {
	return [NSData data];
}

- (NSError *)closeStream {
	return closeError;
}
@end

#pragma mark -
#pragma mark Test Case

@interface ASIDataDecompressorTests : ASITestCase
+ (id)streamStub;
+ (id)decompressorStub;
+ (id)closeErrorDecompressorStub;
- (void)verifyErrorState:(NSError *)error;
@end

@implementation ASIDataDecompressorTests

- (void)setUp {
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	
	// Download a 1.7MB text file
	NSString *filePath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"story.txt"];
	if (![fileManager fileExistsAtPath:filePath] || [[[fileManager attributesOfItemAtPath:filePath error:NULL] objectForKey:NSFileSize] unsignedLongLongValue] < 1693961) {
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/the_hound_of_the_baskervilles.text"]];
		[request setDownloadDestinationPath:[[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"story.txt"]];
		[request startSynchronous];
	}	
}

#pragma mark -
#pragma mark Success Case

- (void)testUncompressDataFromFile {
	NSString *sourcePath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"story.txt"];
	
	NSString *compressedFilePath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"story.txt.gz"];
	NSString *decompressedFilePath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"decompressed_story.txt"];
	
	NSError *compressionError = nil;
	// Create compressed version of story.txt
	[ASIDataCompressor compressDataFromFile:sourcePath toFile:compressedFilePath error:&compressionError];
	if (compressionError) {
		GHFail(@"Unable to compress test data file", nil);
	}
	
	NSError *error = nil;
	GHAssertTrue([ASIDataDecompressor uncompressDataFromFile:compressedFilePath toFile:decompressedFilePath error:&error], @"Should have properly decompressed file.");
	GHAssertNil(error, @"No error should have been returned.");
	
	NSString *originalString = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:sourcePath] encoding:NSUTF8StringEncoding error:&error];
	if (error) {
		GHFail(@"Unable to load contents of original file into NSString", nil);
	}
	
	NSString *decompressedString = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:decompressedFilePath] encoding:NSUTF8StringEncoding error:&error];

	if (error) {
		GHFail(@"Unable to load contents of decompressed file into NSString", nil);
	}

	// Compare strings to ensure they are the same
	GHAssertEqualStrings(originalString, decompressedString, @"The original file and decompressed file contents do not match.", nil);
}

#pragma mark -
#pragma mark Failure Cases

- (void)testUncompressData_withInvalidDestinationPath {

	NSString *sourcePath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"story.txt"];
	
	NSError *error = nil;
	GHAssertFalse([ASIDataDecompressor uncompressDataFromFile:sourcePath toFile:nil error:&error], @"Destination path is invalid.  Should have returned false.");
	[self verifyErrorState:error];
}

- (void)testUncompressDataFromFile_withInvalidSourcePath {
	NSString *destinationPath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"inflated_file.txt"];
	
	NSError *error = nil;
	GHAssertFalse([ASIDataDecompressor uncompressDataFromFile:nil toFile:destinationPath error:&error], @"Source path is invalid.  Should have returned false.");
	[self verifyErrorState:error];
}

- (void)testUncompressDataFromFile_withInputStreamError {
	
	Method realMethod = class_getClassMethod([NSInputStream class], @selector(inputStreamWithFileAtPath:));
	Method stubMethod = class_getClassMethod([self class], @selector(streamStub));

	// swizzle real for stub
	method_exchangeImplementations(stubMethod, realMethod);
	
	NSError *error = nil;
	NSString *sourcePath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"story.txt"];
	NSString *destinationPath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"tmp_out.txt"];

	GHAssertFalse([ASIDataDecompressor uncompressDataFromFile:sourcePath toFile:destinationPath error:&error], @"Decompression should have failed due to input stream error.");
	[self verifyErrorState:error];
	
	// revert methods back to original
	method_exchangeImplementations(realMethod, stubMethod);
}

- (void)testUncompressDataFromFile_withOutputStreamError {
	
	Method realStreamMethod = class_getClassMethod([NSOutputStream class], @selector(outputStreamToFileAtPath:append:));
	Method stubStreamMethod = class_getClassMethod([self class], @selector(streamStub));
	
	Method realDecompressorMethod = class_getClassMethod([ASIDataDecompressor class], @selector(decompressor));
	Method stubDecompressorMethod = class_getClassMethod([self class], @selector(decompressorStub));
	
	// swizzle real for stub
	method_exchangeImplementations(stubStreamMethod, realStreamMethod);
	method_exchangeImplementations(stubDecompressorMethod, realDecompressorMethod);
	
	NSError *error = nil;
	NSString *sourcePath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"story.txt"];
	NSString *destinationPath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"tmp_out.txt"];
	
	GHAssertFalse([ASIDataDecompressor uncompressDataFromFile:sourcePath toFile:destinationPath error:&error], @"Decompression should have failed due to output stream error.");
	[self verifyErrorState:error];
	
	// revert methods back to original
	method_exchangeImplementations(realStreamMethod, stubStreamMethod);
	method_exchangeImplementations(realDecompressorMethod, stubDecompressorMethod);
}

- (void)testUncompressDataFromFile_withDecompressorCloseStreamError {
	
	Method realMethod = class_getClassMethod([ASIDataDecompressor class], @selector(decompressor));
	Method stubMethod = class_getClassMethod([self class], @selector(closeErrorDecompressorStub));
	
	// swizzle real for stub
	method_exchangeImplementations(stubMethod, realMethod);
	
	NSError *error = nil;
	NSString *sourcePath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"story.txt"];
	NSString *destinationPath = [[self filePathForTemporaryTestFiles] stringByAppendingPathComponent:@"tmp_out.txt"];
	
	GHAssertFalse([ASIDataDecompressor uncompressDataFromFile:sourcePath toFile:destinationPath error:&error], @"Decompression should have failed due to output stream error.");
	[self verifyErrorState:error];
	
	// revert methods back to original
	method_exchangeImplementations(realMethod, stubMethod);
}

- (void)verifyErrorState:(NSError *)error {
	GHAssertNotNil(error, @"Expected populated NSError object.  Received nil");
	GHAssertEqualStrings([error domain], NetworkRequestErrorDomain, nil);
	GHAssertTrue([error code] == ASICompressionError, nil);
}

+ (id)streamStub {
	return [[[NSStreamStub alloc] init] autorelease];
}

+ (id)decompressorStub {
	ASIDataDecompressorStub *stub = [[[ASIDataDecompressorStub alloc] init] autorelease];
	stub->closeError = nil;
	return stub; 
}

+ (id)closeErrorDecompressorStub {
	ASIDataDecompressorStub *stub = [[[ASIDataDecompressorStub alloc] init] autorelease];
	stub->closeError = [NSError errorWithDomain:NetworkRequestErrorDomain code:ASICompressionError userInfo:nil];
	return stub; 
}

@end
