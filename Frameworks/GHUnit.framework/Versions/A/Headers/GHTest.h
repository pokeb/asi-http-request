//
//  GHTest.h
//  GHKit
//
//  Created by Gabriel Handford on 1/18/09.
//  Copyright 2009. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

/*!
 Test status.
 */
typedef enum {
	GHTestStatusNone = 0,
	GHTestStatusRunning, // Test is running
	GHTestStatusCancelling, // Test is being cancelled
	GHTestStatusCancelled, // Test was cancelled
	GHTestStatusSucceeded, // Test finished and succeeded
	GHTestStatusErrored, // Test finished and errored
} GHTestStatus;

/*!
 Generate string from GHTestStatus
 @param status
 */
extern NSString* NSStringFromGHTestStatus(GHTestStatus status);

extern BOOL GHTestStatusIsRunning(GHTestStatus status);
extern BOOL GHTestStatusEnded(GHTestStatus status);

/*!
 Test stats.
 */
typedef struct {
	NSInteger succeedCount; // Number of succeeded tests
	NSInteger failureCount; // Number of failed tests
	NSInteger cancelCount; // Number of aborted tests
	NSInteger testCount; // Total number of tests 
} GHTestStats;

/*!
 Create GHTestStats.
 */
extern GHTestStats GHTestStatsMake(NSInteger succeedCount, NSInteger failureCount, NSInteger cancelCount, NSInteger testCount);

extern const GHTestStats GHTestStatsEmpty;

extern NSString *NSStringFromGHTestStats(GHTestStats stats);

@protocol GHTestDelegate;

/*!
 The base interface for a runnable test.
 A runnable with a unique identifier, display name, stats, timer, delegate, log and error handling.
 */
@protocol GHTest <NSObject>

- (void)run;

- (NSString *)identifier;
- (NSString *)name;

- (NSTimeInterval)interval;
- (GHTestStatus)status;
- (GHTestStats)stats;

- (void)setDelegate:(id<GHTestDelegate>)delegate;

- (NSException *)exception;
- (void)setException:(NSException *)exception;

- (NSArray *)log;

- (void)reset;
- (void)cancel;

- (void)setDisabled:(BOOL)disabled;
- (BOOL)isDisabled;
- (NSInteger)disabledCount;

@end

/*!
 Test delegate for notification when a test starts and ends.
 */
@protocol GHTestDelegate <NSObject>
- (void)testDidStart:(id<GHTest>)test source:(id<GHTest>)source;
- (void)testDidUpdate:(id<GHTest>)test source:(id<GHTest>)source;
- (void)testDidEnd:(id<GHTest>)test source:(id<GHTest>)source;
- (void)test:(id<GHTest>)test didLog:(NSString *)message source:(id<GHTest>)source;
@end

/*!
 Delegate which is notified of log messages from inside GHTestCase.
 */
@protocol GHTestCaseLogWriter <NSObject>
- (void)log:(NSString *)message testCase:(id)testCase;
@end

@interface GHTestOperation : NSOperation { 
	id<GHTest> test_;
}
@end

/*!
 Default test implementation with a target/selector pair.
 - Consists of a target/selector
 - Notifies a test delegate
 - Keeps track of status, running time and failures
 - Stores any test specific logging
 */
@interface GHTest : NSObject <GHTest, GHTestCaseLogWriter> {
	
	NSObject<GHTestDelegate> *delegate_; // weak
	
	id target_;
	SEL selector_;
	
	NSString *identifier_;
	NSString *name_;	
	GHTestStatus status_;
	NSTimeInterval interval_;
	BOOL disabled_;
	NSException *exception_; // If failed
		
	NSMutableArray *log_;
}

@property (readonly, nonatomic) id target;
@property (readonly, nonatomic) SEL selector;
@property (readonly, nonatomic) NSString *identifier; // Unique identifier for test
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSTimeInterval interval;
@property (retain, nonatomic) NSException *exception;
@property (readonly, nonatomic) GHTestStatus status;
@property (assign, nonatomic, getter=isDisabled) BOOL disabled;
@property (readonly, nonatomic) NSArray *log;

@property (assign, nonatomic) NSObject<GHTestDelegate> *delegate;

/*!
 Create test with target/selector.
 @param target Target (usually a test case)
 @param selector Selector (usually a test method)
 */
- (id)initWithTarget:(id)target selector:(SEL)selector;

/*!
 Create autoreleased test with target/selector.
 @param target Target (usually a test case)
 @param selector Selector (usually a test method)
 */
+ (id)testWithTarget:(id)target selector:(SEL)selector;

@end
