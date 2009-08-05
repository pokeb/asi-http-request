//
//  UploadViewController.h
//  asi-http-request
//
//  Created by Ben Copsey on 31/12/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ASINetworkQueue;

@interface UploadViewController : UIViewController {
	ASINetworkQueue *networkQueue;
	IBOutlet UIProgressView *progressIndicator;
}

- (IBAction)performLargeUpload:(id)sender;
- (IBAction)toggleThrottling:(id)sender;
@end
