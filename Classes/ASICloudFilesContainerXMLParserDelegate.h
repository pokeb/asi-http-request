//
//  ASICloudFilesContainerXMLParserDelegate.h
//  iPhone
//
//  Created by Michael Mayo on 1/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ASICloudFilesRequest.h"

@class ASICloudFilesContainer;

@interface ASICloudFilesContainerXMLParserDelegate : NSObject {

	NSMutableArray *containerObjects;

	// Internally used while parsing the response
	NSString *currentContent;
	NSString *currentElement;
	ASICloudFilesContainer *currentObject;
}

@property (nonatomic, retain) NSMutableArray *containerObjects;

@property (nonatomic, retain) NSString *currentElement;
@property (nonatomic, retain) NSString *currentContent;
@property (nonatomic, retain) ASICloudFilesContainer *currentObject;

@end
