//
//  GHTestViewController.h
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

#import "GHTestViewModel.h"
#import "GHTestGroup.h"

@interface GHTestViewController : NSViewController {
	NSSplitView *splitView_;
	NSView *statusView_;
	NSView *detailsView_;
	
	NSTextField *statusLabel_;
	NSProgressIndicator *progressIndicator_;
	NSOutlineView *outlineView_;
	
	NSSegmentedControl *textSegmentedControl_;
	NSTextView *textView_;
	
	BOOL wrapInTextView_;
	
	GHTestViewModel *model_;
}

// Assign since they are retained as subviews
@property (assign, nonatomic) IBOutlet NSSplitView *splitView;
@property (assign, nonatomic) IBOutlet NSView *statusView;
@property (assign, nonatomic) IBOutlet NSView *detailsView;
@property (assign, nonatomic) IBOutlet NSTextField *statusLabel;
@property (assign, nonatomic) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign, nonatomic) IBOutlet NSOutlineView *outlineView;
@property (assign, nonatomic) IBOutlet NSSegmentedControl *textSegmentedControl;
@property (assign, nonatomic) IBOutlet NSTextView *textView;
@property (assign, nonatomic) BOOL wrapInTextView;
@property (readonly, nonatomic) id<GHTest> selectedTest;

@property (copy, nonatomic) NSString *status;

- (void)log:(NSString *)log;
- (void)test:(id<GHTest>)test didLog:(NSString *)message;

- (void)updateTest:(id<GHTest>)test;

- (void)setRoot:(id<GHTestGroup>)root;

- (void)selectFirstFailure;

- (GHTestNode *)findFailure;
- (GHTestNode *)findFailureFromNode:(GHTestNode *)node;

- (IBAction)copy:(id)sender;

@end
