//
//  ASIOAuthParameter.m
//  iOSSocial
//
//  Created by Christopher White on 9/12/11.
//  Copyright (c) 2011 Mad Races, Inc. All rights reserved.
//

#import "ASIOAuthParameter.h"
#import "ASIOARequest.h"

// This class represents key-value pairs so they can be sorted by both
// name and encoded value
@implementation ASIOAuthParameter

@synthesize name = name_;
@synthesize value = value_;

+ (ASIOAuthParameter *)parameterWithName:(NSString *)name
                                   value:(NSString *)value {
    ASIOAuthParameter *obj = [[[self alloc] init] autorelease];
    [obj setName:name];
    [obj setValue:value];
    return obj;
}

- (void)dealloc {
    [name_ release];
    [value_ release];
    [super dealloc];
}

- (NSString *)encodedValue {
    NSString *value = [self value];
    NSString *result = [ASIOARequest encodedOAuthParameterForString:value];
    return result;
}

- (NSString *)encodedName {
    NSString *name = [self name];
    NSString *result = [ASIOARequest encodedOAuthParameterForString:name];
    return result;
}

- (NSString *)encodedParam {
    NSString *str = [NSString stringWithFormat:@"%@=%@",
                     [self encodedName], [self encodedValue]];
    return str;
}

- (NSString *)quotedEncodedParam {
    NSString *str = [NSString stringWithFormat:@"%@=\"%@\"",
                     [self encodedName], [self encodedValue]];
    return str;
}

- (NSString *)description {
    return [self encodedParam];
}

+ (NSArray *)sortDescriptors {
    // sort by name and value
    SEL sel = @selector(compare:);
    
    NSSortDescriptor *desc1, *desc2;
    desc1 = [[[NSSortDescriptor alloc] initWithKey:@"name"
                                         ascending:YES
                                          selector:sel] autorelease];
    desc2 = [[[NSSortDescriptor alloc] initWithKey:@"encodedValue"
                                         ascending:YES
                                          selector:sel] autorelease];
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:desc1, desc2, nil];
    return sortDescriptors;
}

@end
