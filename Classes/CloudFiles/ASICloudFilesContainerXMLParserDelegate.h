//
//  ASICloudFilesContainerXMLParserDelegate.h
//
//  Created by Michael Mayo on 1/10/10.
//

#import "ASICloudFilesRequest.h"

@class ASICloudFilesContainer;

// Prevent warning about missing NSXMLParserDelegate on Leopard and iPhone
#if !TARGET_OS_IPHONE && MAC_OS_X_VERSION_10_5 < MAC_OS_X_VERSION_MAX_ALLOWED
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

@property (nonatomic, retain) NSMutableArray *containerObjects;

@property (nonatomic, retain) NSString *currentElement;
@property (nonatomic, retain) NSString *currentContent;
@property (nonatomic, retain) ASICloudFilesContainer *currentObject;

@end
