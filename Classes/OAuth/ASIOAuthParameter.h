//
//  ASIOAuthParameter.h
//  iOSSocial
//
//  Created by Christopher White on 9/12/11.
//  Copyright (c) 2011 Mad Races, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

// Borrowed from gtm-oauth

// OAuthParameter is a local class that exists just to make it easier to
// sort descriptor pairs by name and encoded value
@interface ASIOAuthParameter : NSObject {
@private
    NSString *name_;
    NSString *value_;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *value;

+ (ASIOAuthParameter *)parameterWithName:(NSString *)name
                                value:(NSString *)value;

+ (NSArray *)sortDescriptors;
@end
