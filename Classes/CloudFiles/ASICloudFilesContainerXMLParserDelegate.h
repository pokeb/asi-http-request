//
//  ASICloudFilesContainerXMLParserDelegate.h
//
//  Created by Michael Mayo on 1/10/10.
//

#import "ASICloudFilesRequest.h"

@class ASICloudFilesContainer;

#if (!TARGET_OS_IPHONE && MAC_OS_X_VERSION_MIN_REQUIRED >= __MAC_10_6) || (TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0)
@interface ASICloudFilesContainerXMLParserDelegate : NSObject <NSXMLParserDelegate> {
#else
@interface ASICloudFilesContainerXMLParserDelegate : NSObject {
#endif
		
	NSMutableArray *containerObjects;

	// Internally used while parsing the response
	NSString *currentContent;
	NSString *currentElement;
	ASICloudFilesContainer *currentObject;
}

@property (retain) NSMutableArray *containerObjects;

@property (retain) NSString *currentElement;
@property (retain) NSString *currentContent;
@property (retain) ASICloudFilesContainer *currentObject;

@end
