//
//  ASICloudFilesObject.h
//  iPhone
//
//  Created by Michael Mayo on 1/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ASICloudFilesObject : NSObject {
	NSString *name;
	NSString *hash;
	NSUInteger bytes;
	NSString *contentType;
	NSDate *lastModified;
	NSData *data;
	NSDictionary *metadata;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *hash;
@property (nonatomic) NSUInteger bytes;
@property (nonatomic, retain) NSString *contentType;
@property (nonatomic, retain) NSDate *lastModified;
@property (nonatomic, retain) NSData *data;	
@property (nonatomic, retain) NSDictionary *metadata;

+ (id)object;

@end
