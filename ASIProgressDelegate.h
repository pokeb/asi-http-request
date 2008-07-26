//
//  ASIProgressDelegate.h
//
//  Created by Ben Copsey on 28/03/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved
//

#import <Cocoa/Cocoa.h>

@protocol ASIProgressDelegate

- (void)incrementProgress;
- (void)setDoubleValue:(double)newValue;
- (void)incrementBy:(double)amount;
- (void)setMaxValue:(double)newMax;
- (double)maxValue;
@end