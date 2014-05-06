//
//  ASIOARequest.m
//  iOSSocial
//
//  Created by Christopher White on 9/13/11.
//  Copyright (c) 2011 Mad Races, Inc. All rights reserved.
//

#import "ASIOARequest.h"
#import "ASIOAuthParameter.h"
// HMAC digest
#import <CommonCrypto/CommonHMAC.h>

NSString* const kASIOAuthSignatureMethodHMAC_SHA1 = @"HMAC-SHA1";

// standard OAuth keys
NSString *const kASIOAuthConsumerKey          = @"oauth_consumer_key";
NSString *const kASIOAuthConsumerSecret       = @"oauth_consumer_secret";
NSString *const kASIOAuthTokenKey             = @"oauth_token";
NSString *const kASIOAuthCallbackKey          = @"oauth_callback";
NSString *const kASIOAuthCallbackConfirmedKey = @"oauth_callback_confirmed";
NSString *const kASIOAuthTokenSecretKey       = @"oauth_token_secret";
NSString *const kASIOAuthSignatureMethodKey   = @"oauth_signature_method";
NSString *const kASIOAuthSignatureKey         = @"oauth_signature";
NSString *const kASIOAuthTimestampKey         = @"oauth_timestamp";
NSString *const kASIOAuthNonceKey             = @"oauth_nonce";
NSString *const kASIOAuthVerifierKey          = @"oauth_verifier";
NSString *const kASIOAuthVersionKey           = @"oauth_version";

@implementation ASIOARequest

@synthesize oauthParams;
@synthesize realm;

#pragma mark -
#pragma mark oauth

- (NSString *)normalizedRequestURLStringForRequest:(NSURL *)theURL 
{
    // http://oauth.net/core/1.0a/#anchor13
    
    NSString *scheme = [[theURL scheme] lowercaseString];
    NSString *host = [[theURL host] lowercaseString];
    int port = [[theURL port] intValue];
    
    // NSURL's path method has an unfortunate side-effect of unescaping the path,
    // but CFURLCopyPath does not
    CFStringRef cfPath = CFURLCopyPath((__bridge CFURLRef)theURL);
    NSString *path = [NSMakeCollectable(cfPath) autorelease];
    
    // include only non-standard ports for http or https
    NSString *portStr;
    if (port == 0
        || ([scheme isEqual:@"http"] && port == 80)
        || ([scheme isEqual:@"https"] && port == 443)) {
        portStr = @"";
    } else {
        portStr = [NSString stringWithFormat:@":%u", port];
    }
    
    if ([path length] == 0) {
        path = @"/";
    }
    
    NSString *result = [NSString stringWithFormat:@"%@://%@%@%@",
                        scheme, host, portStr, path];
    return result;
}

+ (NSString *)unencodedOAuthParameterForString:(NSString *)str {
    NSString *plainStr = [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return plainStr;
}

+ (void)addQueryString:(NSString *)query
              toParams:(NSMutableArray *)array {
    // make param objects from the query parameters, and add them
    // to the supplied array
    
    // look for a query like foo=cat&bar=dog
    if ([query length] > 0) {
        // the standard test cases insist that + in the query string
        // be encoded as " " - http://wiki.oauth.net/TestCases
        query = [query stringByReplacingOccurrencesOfString:@"+"
                                                 withString:@" "];
        
        // separate and step through the query parameter assignments
        NSArray *items = [query componentsSeparatedByString:@"&"];
        
        for (NSString *item in items) {
            NSString *name = nil;
            NSString *value = @"";
            
            NSRange equalsRange = [item rangeOfString:@"="];
            if (equalsRange.location != NSNotFound) {
                // the parameter has at least one '='
                name = [item substringToIndex:equalsRange.location];
                
                if (equalsRange.location + 1 < [item length]) {
                    // there are characters after the '='
                    value = [item substringFromIndex:(equalsRange.location + 1)];
                    
                    // remove percent-escapes from the parameter value; they'll be
                    // added back by OAuthParameter
                    value = [[self class] unencodedOAuthParameterForString:value];
                } else {
                    // no characters after the '='
                }
            } else {
                // the parameter has no '='
                name = item;
            }
            
            // remove percent-escapes from the parameter name; they'll be
            // added back by OAuthParameter
            name = [[self class] unencodedOAuthParameterForString:name];
            
            ASIOAuthParameter *param = [ASIOAuthParameter parameterWithName:name
                                                                      value:value];
            [array addObject:param];
        }
    }
}

+ (void)addQueryFromRequest:(NSURL *)theURL
                   toParams:(NSMutableArray *)array {
    // get the query string from the request
    NSString *query = [theURL query];
    [self addQueryString:query toParams:array];
}
/*
+ (void)addBodyFromRequest:(NSURLRequest *)request
                  toParams:(NSMutableArray *)array {
    // add non-GET form parameters to the array of param objects
    NSString *method = [request HTTPMethod];
    if (method != nil && ![method isEqual:@"GET"]) {
        NSString *type = [request valueForHTTPHeaderField:@"Content-Type"];
        if ([type hasPrefix:@"application/x-www-form-urlencoded"]) {
            NSData *data = [request HTTPBody];
            if ([data length] > 0) {
                NSString *str = [[[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding] autorelease];
                if ([str length] > 0) {
                    [[self class] addQueryString:str toParams:array];
                }
            }
        }
    }
}
*/
- (void)addBodyFromRequestToParams:(NSMutableArray *)array {
    // add non-GET form parameters to the array of param objects
    if (self.requestMethod != nil && ![self.requestMethod isEqual:@"GET"]) {
        
        // Handle response text encoding
        /*
        NSStringEncoding charset = 0;
        NSString *mimeType = nil;
        [[self class] parseMimeType:&mimeType andResponseEncoding:&charset fromContentType:[[self responseHeaders] valueForKey:@"Content-Type"]];
         if (charset != 0) {
         [self setResponseEncoding:charset];
         } else {
         [self setResponseEncoding:[self defaultResponseEncoding]];
         }
         */
        
        NSString *type = [self.requestHeaders objectForKey:@"Content-Type"];
        //NSString *type = [request valueForHTTPHeaderField:@"Content-Type"];
        if ([type hasPrefix:@"application/x-www-form-urlencoded"]) {
            NSData *data = [self postBody];
            if ([data length] > 0) {
                NSString *str = [[[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding] autorelease];
                if ([str length] > 0) {
                    [[self class] addQueryString:str toParams:array];
                }
            }
        } else if ([type hasPrefix:@"multipart/form-data"]) {
            
            for (NSDictionary *val in self->postData) {
                NSString *name = nil;
                NSString *value = @"";
                
                value = [val objectForKey:@"value"];
                
                // remove percent-escapes from the parameter value; they'll be
                // added back by OAuthParameter
                value = [[self class] unencodedOAuthParameterForString:value];
                
                name = [val objectForKey:@"key"];
                
                // remove percent-escapes from the parameter name; they'll be
                // added back by OAuthParameter
                name = [[self class] unencodedOAuthParameterForString:name];
                
                ASIOAuthParameter *param = [ASIOAuthParameter parameterWithName:name
                                                                          value:value];
                [array addObject:param];
            }
        }
    }
}

+ (NSString *)paramStringForParams:(NSArray *)params
                            joiner:(NSString *)joiner
                       shouldQuote:(BOOL)shouldQuote
                        shouldSort:(BOOL)shouldSort {
    // create a string by joining the supplied param objects
    
    if (shouldSort) {
        // sort params by name and value
        NSArray *descs = [ASIOAuthParameter sortDescriptors];
        params = [params sortedArrayUsingDescriptors:descs];
    }
    
    // make an array of the encoded name=value items
    NSArray *encodedArray;
    if (shouldQuote) {
        encodedArray = [params valueForKey:@"quotedEncodedParam"];
    } else {
        encodedArray = [params valueForKey:@"encodedParam"];
    }
    
    // join the items
    NSString *result = [encodedArray componentsJoinedByString:joiner];
    return result;
}

+ (NSString *)encodedOAuthParameterForString:(NSString *)str {
    // http://oauth.net/core/1.0a/#encoding_parameters
    
    CFStringRef originalString = (__bridge CFStringRef) str;
    
    CFStringRef leaveUnescaped = CFSTR("ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                                       "abcdefghijklmnopqrstuvwxyz"
                                       "-._~");
    CFStringRef forceEscaped =  CFSTR("%!$&'()*+,/:;=?@");
    
    CFStringRef escapedStr = NULL;
    if (str) {
        escapedStr = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                             originalString,
                                                             leaveUnescaped,
                                                             forceEscaped,
                                                             kCFStringEncodingUTF8);
        [(__bridge id)CFMakeCollectable(escapedStr) autorelease];
    }
    
    return (__bridge NSString *)escapedStr;
}

+ (NSString *)stringWithBase64ForData:(NSData *)data {
    // Cyrus Najmabadi elegent little encoder from
    // http://www.cocoadev.com/index.pl?BaseSixtyFour
    if (data == nil) return nil;
    
    const uint8_t* input = [data bytes];
    NSUInteger length = [data length];
    
    NSUInteger bufferSize = ((length + 2) / 3) * 4;
    NSMutableData* buffer = [NSMutableData dataWithLength:bufferSize];
    
    uint8_t* output = [buffer mutableBytes];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    for (NSUInteger i = 0; i < length; i += 3) {
        NSInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger idx = (i / 3) * 4;
        output[idx + 0] =                    table[(value >> 18) & 0x3F];
        output[idx + 1] =                    table[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    NSString *result = [[[NSString alloc] initWithData:buffer
                                              encoding:NSASCIIStringEncoding] autorelease];
    return result;
}

+ (NSString *)HMACSHA1HashForConsumerSecret:(NSString *)consumerSecret
                                tokenSecret:(NSString *)tokenSecret
                                       body:(NSString *)body {
    NSString *encodedConsumerSecret = [self encodedOAuthParameterForString:consumerSecret];
    NSString *encodedTokenSecret = [self encodedOAuthParameterForString:tokenSecret];
    
    NSString *key = [NSString stringWithFormat:@"%@&%@",
                     encodedConsumerSecret ? encodedConsumerSecret : @"",
                     encodedTokenSecret ? encodedTokenSecret : @""];
    
    NSMutableData *sigData = [NSMutableData dataWithLength:CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1,
           [key UTF8String], [key length],
           [body UTF8String], [body length],
           [sigData mutableBytes]);
    
    NSString *signature = [self stringWithBase64ForData:sigData];
    return signature;
}

- (NSString *)privateKey {
    return [self.oauthParams objectForKey:kASIOAuthConsumerSecret];
}

- (NSString *)tokenSecret {
    return [self.oauthParams objectForKey:kASIOAuthTokenSecretKey];
}

- (NSString *)token {
    return [self.oauthParams objectForKey:kASIOAuthTokenKey];
}

- (NSString *)signatureMethod {
    return [self.oauthParams objectForKey:kASIOAuthSignatureMethodKey];
}

- (NSString *)signatureForParams:(NSMutableArray *)params
                         request:(NSURL *)theURL {
    // construct signature base string per
    // http://oauth.net/core/1.0a/#signing_process
    NSString *requestURLStr = [self normalizedRequestURLStringForRequest:theURL];
    if ([self.requestMethod length] == 0) {
        self.requestMethod = @"GET";
    }
    
    // the signature params exclude the signature
    NSMutableArray *signatureParams = [NSMutableArray arrayWithArray:params];
    
    // add request query parameters
    [[self class] addQueryFromRequest:theURL toParams:signatureParams];
    
    // add parameters from the POST body, if any
    [self addBodyFromRequestToParams:signatureParams];
    
    NSString *paramStr = [[self class] paramStringForParams:signatureParams
                                                     joiner:@"&"
                                                shouldQuote:NO
                                                 shouldSort:YES];
    
    // the base string includes the method, normalized request URL, and params
    NSString *requestURLStrEnc = [[self class] encodedOAuthParameterForString:requestURLStr];
    NSString *paramStrEnc = [[self class] encodedOAuthParameterForString:paramStr];
    
    NSString *sigBaseString = [NSString stringWithFormat:@"%@&%@&%@",
                               self.requestMethod, requestURLStrEnc, paramStrEnc];
    
    NSString *privateKey = [self privateKey];
    NSString *signatureMethod = [self signatureMethod];
    NSString *signature = nil;
    
    if ([signatureMethod isEqual:kASIOAuthSignatureMethodHMAC_SHA1]) {
        NSString *tokenSecret = [self tokenSecret];
        signature = [[self class] HMACSHA1HashForConsumerSecret:privateKey
                                                    tokenSecret:tokenSecret
                                                           body:sigBaseString];
    }
    
    return signature;
}

- (NSString *)timestamp {
    
    //if (timestamp_) return timestamp_; // for testing only
    
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    unsigned long long timestampVal = (unsigned long long) timeInterval;
    NSString *timestamp = [NSString stringWithFormat:@"%qu", timestampVal];
    return timestamp;
}

- (NSString *)nonce {
    
    //if (nonce_) return nonce_; // for testing only
    
    // make a random 64-bit number
    unsigned long long nonceVal = ((unsigned long long) arc4random()) << 32
    | (unsigned long long) arc4random();
    
    NSString *nonce = [NSString stringWithFormat:@"%qu", nonceVal];
    return nonce;
}

- (NSMutableArray *)paramsForKeys:(NSArray *)keys
                          request:(NSURL *)theURL {
    // this is the magic routine that collects the parameters for the specified
    // keys, and signs them
    NSMutableArray *params = [NSMutableArray array];
    
    for (NSString *key in keys) {
        NSString *value = [self.oauthParams objectForKey:key];
        if ([value length] > 0) {
            [params addObject:[ASIOAuthParameter parameterWithName:key
                                                             value:value]];
        }
    }

    // nonce and timestamp are generated on-the-fly by the getters
    if ([keys containsObject:kASIOAuthNonceKey]) {
        NSString *nonce = [self nonce];
        [params addObject:[ASIOAuthParameter parameterWithName:kASIOAuthNonceKey
                                                         value:nonce]];
    }
    
    if ([keys containsObject:kASIOAuthTimestampKey]) {
        NSString *timestamp = [self timestamp];
        [params addObject:[ASIOAuthParameter parameterWithName:kASIOAuthTimestampKey
                                                         value:timestamp]];
    }

    // finally, compute the signature, if requested; the params
    // must be complete for this
    if ([keys containsObject:kASIOAuthSignatureKey]) {
        NSString *signature = [self signatureForParams:params
                                               request:theURL];
        [params addObject:[ASIOAuthParameter parameterWithName:kASIOAuthSignatureKey
                                                         value:signature]];
    }
    
    return params;
}

+ (NSArray *)tokenResourceKeys {
    // keys for accessing a protected resource,
    // http://oauth.net/core/1.0a/#anchor12
    NSArray *keys = [NSArray arrayWithObjects:
                     kASIOAuthConsumerKey,
                     kASIOAuthTokenKey,
                     kASIOAuthSignatureMethodKey,
                     kASIOAuthSignatureKey,
                     kASIOAuthTimestampKey,
                     kASIOAuthNonceKey,
                     kASIOAuthVersionKey, nil];
    return keys;
}

- (void)addAuthorizationHeaderToRequestForKeys:(NSArray *)keys {
    // make all the parameters, including a signature for all
    NSMutableArray *params = [self paramsForKeys:keys 
                                         request:self.url];
    
    // split the params into "oauth_" params which go into the Auth header
    // and others which get added to the query
    NSMutableArray *theOAuthParams = [NSMutableArray array];
    NSMutableArray *extendedParams = [NSMutableArray array];
    
    for (ASIOAuthParameter *param in params) {
        NSString *name = [param name];
        BOOL hasPrefix = [name hasPrefix:@"oauth_"];
        if (hasPrefix) {
            [theOAuthParams addObject:param];
        } else {
            [extendedParams addObject:param];
        }
    }
    
    NSString *paramStr = [[self class] paramStringForParams:theOAuthParams
                                                     joiner:@", "
                                                shouldQuote:YES
                                                 shouldSort:NO];
    
    // include the realm string, if any, in the auth header
    // http://oauth.net/core/1.0a/#auth_header
    NSString *realmParam = @"";
    if ([self.realm length] > 0) {
        NSString *encodedVal = [[self class] encodedOAuthParameterForString:self.realm];
        realmParam = [NSString stringWithFormat:@"realm=\"%@\", ", encodedVal];
    }

    // set the parameters for "oauth_" keys and the realm
    // in the authorization header
    NSString *authHdr = [NSString stringWithFormat:@"OAuth %@%@",
                         realmParam, paramStr];
    [self addRequestHeader:@"Authorization" value:authHdr];
    
    /*
     [request setValue:authHdr forHTTPHeaderField:@"Authorization"];
     
     // add any other params as URL query parameters
     if ([extendedParams count] > 0) {
     [self addParams:extendedParams toRequest:request];
     }
     */
}

- (void)addResourceTokenHeaderToRequestWithOAuthParams {
    // add resource access token params to the request's header
    NSArray *keys = [[self class] tokenResourceKeys];
    [self addAuthorizationHeaderToRequestForKeys:keys];
}

// general entry point for GTL library
- (BOOL)authorizeRequestWithOAuthParams {
    NSString *token = [self token];
    if ([token length] == 0) {
        return NO;
    } else {
        /*
         if ([self shouldUseParamsToAuthorize]) {
         [self addResourceTokenParamsToRequest:request];
         } else {*/
        [self addResourceTokenHeaderToRequestWithOAuthParams];
        //}
        return YES;
    }
}

- (void)buildURL
{
    
}

- (void)buildRequestHeaders
{
	if (![self url]) {
		[self buildURL];
	}
	[super buildRequestHeaders];
    
    [self authorizeRequestWithOAuthParams];
}

@end
