//
//  ASIProgressDelegate.h
//
//  Created by Ben Copsey on 28/03/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved
//


@protocol ASIProgressDelegate

- (void)setDoubleValue:(double)newValue;
- (double)doubleValue;
- (void)incrementBy:(double)amount;
- (void)setMaxValue:(double)newMax;
- (double)maxValue;
@end