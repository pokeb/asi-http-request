//
//  ASICloudFilesCDNRequest.h
//  iPhone
//
//  Created by Michael Mayo on 1/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ASICloudFilesRequest.h"


@interface ASICloudFilesCDNRequest : ASICloudFilesRequest {
	NSString *accountName;
	NSString *containerName;
}

@property (nonatomic, retain) NSString *accountName;
@property (nonatomic, retain) NSString *containerName;


// HEAD /<api version>/<account>/<container>
// Response:
// X-CDN-Enabled: True
// X-CDN-URI: http://cdn.cloudfiles.mosso.com/c1234
// X-CDN-TTL: 86400
+ (id)containerInfoRequest:(NSString *)containerName;
- (BOOL)cdnEnabled;
- (NSString *)cdnURI;
- (NSUInteger)cdnTTL;


// GET /<api version>/<account>
// limit, marker, format, enabled_only=true
+ (id)listRequest;
+ (id)listRequestWithLimit:(NSUInteger)limit marker:(NSString *)marker enabledOnly:(BOOL)enabledOnly;
- (NSArray *)containers;


// PUT /<api version>/<account>/<container>
// PUT operations against a Container are used to CDN-enable that Container.
// Include an HTTP header of X-TTL to specify a custom TTL.

// POST /<api version>/<account>/<container>
// POST operations against a CDN-enabled Container are used to adjust CDN attributes.
// The POST operation can be used to set a new TTL cache expiration or to enable/disable public sharing over the CDN.
// X-TTL: 86400
// X-CDN-Enabled: True


@end
