//
//  GHTest.h
//  GHKit
//
//  Created by Gabriel Handford on 1/17/09.
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

#import "GHTestGroup.h"

@class GHTestNode;

@protocol GHTestNodeDelegate <NSObject>
- (void)testNodeDidChange:(GHTestNode *)node;
@end


/*!
 Test view model for use in a tree view.
 */
@interface GHTestViewModel : NSObject <GHTestNodeDelegate> {
	
	GHTestSuite *suite_;
	GHTestNode *root_;
	
	GHTestRunner *runner_;
	
	NSMutableDictionary *map_; // id<GHTest>#identifier -> GHTestNode

	BOOL editing_;
	NSString *settingsKey_;
	NSMutableDictionary *settings_;
}

@property (readonly, nonatomic) GHTestNode *root;
@property (assign, nonatomic, getter=isEditing) BOOL editing;

/*!
 Create view model with root test group node.
 */
- (id)initWithSuite:(GHTestSuite *)suite;

- (NSString *)name;
- (NSString *)statusString:(NSString *)prefix;

/*!
 Get the test node from the test.
 @param test
 */
- (GHTestNode *)findTestNode:(id<GHTest>)test;

- (GHTestNode *)findFailure;
- (GHTestNode *)findFailureFromNode:(GHTestNode *)node;

/*!
 Register node, so that we can do a lookup later (see #findTestNode).
 @param node
 */
- (void)registerNode:(GHTestNode *)node;

// Return number of test groups
- (NSInteger)numberOfGroups;

// Return number of tests in group
- (NSInteger)numberOfTestsInGroup:(NSInteger)group;

/*!
 Search for path to test.
 @param test
 @result Index path
 */
- (NSIndexPath *)indexPathToTest:(id<GHTest>)test;

- (void)loadDefaults;
- (void)saveDefaults;

- (void)run:(id<GHTestRunnerDelegate>)delegate inParallel:(BOOL)inParallel;

- (void)cancel;

- (BOOL)isRunning;

@end


@interface GHTestNode : NSObject {

	id<GHTest> test_;
	NSMutableArray */* of GHTestNode*/children_;

	id<GHTestNodeDelegate> delegate_;

}


@property (readonly, nonatomic) NSArray */* of GHTestNode*/children;
@property (readonly, nonatomic) id<GHTest> test;
@property (assign, nonatomic) id<GHTestNodeDelegate> delegate;

- (id)initWithTest:(id<GHTest>)test children:(NSArray */*of GHTestNode */)children source:(GHTestViewModel *)source;
+ (GHTestNode *)nodeWithTest:(id<GHTest>)test children:(NSArray */*of GHTestNode */)children source:(GHTestViewModel *)source;

- (NSString *)identifier;
- (NSString *)name;
- (NSString *)nameWithStatus;

- (GHTestStatus)status;
- (NSString *)statusString;
- (NSString *)stackTrace;
- (NSString *)log;
- (BOOL)isRunning;
- (BOOL)isDisabled;
- (BOOL)isEnded;
- (BOOL)isGroupTest; // YES if test has "sub tests"

- (BOOL)isSelected;
- (void)setSelected:(BOOL)selected;

- (BOOL)hasChildren;
- (BOOL)failed;

- (void)notifyChanged;

@end
