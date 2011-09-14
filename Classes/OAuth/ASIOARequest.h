//
//  ASIOARequest.h
//  iOSSocial
//
//  Created by Christopher White on 9/13/11.
//  Copyright (c) 2011 Mad Races, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIFormDataRequest.h"

extern NSString *const kASIOAuthConsumerKey;
extern NSString *const kASIOAuthConsumerSecret;
extern NSString *const kASIOAuthTokenKey;
extern NSString *const kASIOAuthCallbackKey;
extern NSString *const kASIOAuthCallbackConfirmedKey;
extern NSString *const kASIOAuthTokenSecretKey;
extern NSString *const kASIOAuthSignatureMethodKey;
extern NSString *const kASIOAuthSignatureKey;
extern NSString *const kASIOAuthTimestampKey;
extern NSString *const kASIOAuthNonceKey;
extern NSString *const kASIOAuthVerifierKey;
extern NSString *const kASIOAuthVersionKey;

extern NSString* const kASIOAuthSignatureMethodHMAC_SHA1;

@interface ASIOARequest : ASIFormDataRequest {
    //NSDictionary *_oauthParams;
}

@property(nonatomic, retain)    NSDictionary *oauthParams;
@property (nonatomic, copy)     NSString *realm;

#pragma mark init / dealloc

#pragma mark oauth
+ (NSString *)encodedOAuthParameterForString:(NSString *)str;

@end
