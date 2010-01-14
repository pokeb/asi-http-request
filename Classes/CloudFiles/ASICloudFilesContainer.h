//
//  ASICloudFilesContainer.h
//
//  Created by Michael Mayo on 1/7/10.
//

#import <Foundation/Foundation.h>


@interface ASICloudFilesContainer : NSObject {
	
	// regular container attributes
	NSString *name;
	NSUInteger count;
	NSUInteger bytes;
	
	// CDN container attributes
	BOOL cdnEnabled;
	NSUInteger ttl;
	NSString *cdnURL;
	BOOL logRetention;
	NSString *referrerACL;
	NSString *useragentACL;
}

+ (id)container;

// regular container attributes
@property (nonatomic, retain) NSString *name;
@property (nonatomic) NSUInteger count;
@property (nonatomic) NSUInteger bytes;

// CDN container attributes
@property (nonatomic) BOOL cdnEnabled;
@property (nonatomic) NSUInteger ttl;
@property (nonatomic, retain) NSString *cdnURL;
@property (nonatomic) BOOL logRetention;
@property (nonatomic, retain) NSString *referrerACL;
@property (nonatomic, retain) NSString *useragentACL;

@end
