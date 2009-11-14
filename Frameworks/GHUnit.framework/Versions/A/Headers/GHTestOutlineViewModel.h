//
//  GHTestOutlineViewModel.h
//  GHUnit
//
//  Created by Gabriel Handford on 7/17/09.
//  Copyright 2009. All rights reserved.
//

#import "GHTestViewModel.h"
@class GHTestOutlineViewModel;


@protocol GHTestOutlineViewModelDelegate <NSObject>
- (void)testOutlineViewModelDidChangeSelection:(GHTestOutlineViewModel *)testOutlineViewModel;
@end


@interface GHTestOutlineViewModel : GHTestViewModel {
	id<GHTestOutlineViewModelDelegate> delegate_; // weak
	
	NSButtonCell *editCell_;
}

@property (assign, nonatomic) id<GHTestOutlineViewModelDelegate> delegate;

@end
