//
//  ASICloudFilesContainer.h
//  iPhone
//
//  Created by Michael Mayo on 1/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ASICloudFilesContainer : NSObject {
	NSString *name;
	NSUInteger count;
	NSUInteger bytes;
}

+ (id)container;

@property (nonatomic, retain) NSString *name;
@property (nonatomic) NSUInteger count;
@property (nonatomic) NSUInteger bytes;

@end
