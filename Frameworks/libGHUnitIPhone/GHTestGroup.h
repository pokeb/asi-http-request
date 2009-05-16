//
//  GHTestGroup.h
//
//  Created by Gabriel Handford on 1/16/09.
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

//
// Portions of this file fall under the following license, marked with:
// GTM_BEGIN : GTM_END
//
//  Copyright 2008 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not
//  use this file except in compliance with the License.  You may obtain a copy
//  of the License at
// 
//  http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
//  License for the specific language governing permissions and limitations under
//  the License.
//

#import "GHTest.h"
#import "GHTestCase.h"

/*!
 @brief Interface for a group of tests.

 This group conforms to the GHTest protocol as well (see Composite pattern).
 */
@protocol GHTestGroup <GHTest>
- (NSString *)name;
- (id<GHTestGroup>)parent;
- (NSArray *)children;
@end

/*!
 @brief A collection of tests (or test groups).

 A test group is a collection of id<GHTest>, that may represent a set of test case methods. 
 
 For example, if you had the following GHTestCase.

 @code
 @interface FooTest : GHTestCase {}
 - (void)testFoo;
 - (void)testBar;
 @end
 @endcode
 
 The GHTestGroup would consist of and array of GHTest, [FooTest#testFoo and FooTest#testBar], 
 each test being a target and selector pair.

 A test group may also consist of a group of groups (since GHTestGroup conforms to GHTest),
 and this might represent a GHTestSuite.
 */
@interface GHTestGroup : NSObject <GHTestDelegate, GHTestGroup> {
	
	id<GHTestDelegate> delegate_; // weak
	id<GHTestGroup> parent_; // weak
	
	NSMutableArray *children_; // of id<GHTest>
		
	NSString *name_; // The name of the test group (usually the class name of the test case
	NSTimeInterval interval_; // Total time of child tests
	GHTestStatus status_; // Current status of the group (current status of running or completed child tests)
	GHTestStats stats_; // Current stats for the group (aggregate of child test stats)
	
	id testCase_; // Is set if test is created from initWithTestCase:delegate:
	id<GHTest> currentTest_; // weak
	
	NSException *exception_; // If exception happens in group setUpClass/tearDownClass
	
	BOOL ignore_;
}

@property (readonly, nonatomic) NSArray *children;
@property (assign, nonatomic) id<GHTestDelegate> delegate;
@property (assign, nonatomic) id<GHTestGroup> parent;
@property (readonly, nonatomic) id testCase;

@property (readonly, nonatomic) NSString *identifier;
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) GHTestStatus status;

@property (readonly, nonatomic) NSTimeInterval interval;
@property (readonly, nonatomic) GHTestStats stats;

@property (assign, nonatomic) BOOL ignore;

/*!
 Create an empty test group.
 @param name The name of the test group
 @param delegate Delegate, notifies of test start and end
 @result New test group
 */
- (id)initWithName:(NSString *)name delegate:(id<GHTestDelegate>)delegate;

/*!
 Create test group from a test case.

 A test group is a collection of GHTest. 
 @param testCase Test case, could be a subclass of SenTestCase or GHTestCase
 @param delegate Delegate, notifies of test start and end
 @result New test group
 */
- (id)initWithTestCase:(id)testCase delegate:(id<GHTestDelegate>)delegate;

/*!
 Create test group from a single test.
 @param testCase
 @param selector Test to run
 @param delegate
 */
- (id)initWithTestCase:(id)testCase selector:(SEL)selector delegate:(id<GHTestDelegate>)delegate;

/*!
 Create test group from a test case.
 @param testCase Test case, could be a subclass of SenTestCase or GHTestCase
 @param delegate Delegate, notifies of test start and end
 @result New test group
 */
+ (GHTestGroup *)testGroupFromTestCase:(id)testCase delegate:(id<GHTestDelegate>)delegate;

/*!
 Add a test case (or test group) to this test group.
 @param testCase Test case, could be a subclass of SenTestCase or GHTestCase
 */
- (void)addTestCase:(id)testCase;

- (void)addTestGroup:(GHTestGroup *)testGroup;

/*!
 Run the test group.
 Will notify delegate as tests are run.
 */
- (void)run;

@end
