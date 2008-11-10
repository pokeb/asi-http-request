//
//  QueueViewController.h
//  asi-http-request
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ASINetworkQueue;

@interface QueueViewController : UIViewController {
	ASINetworkQueue *networkQueue;
	
	IBOutlet UIImageView *imageView1;
	IBOutlet UIImageView *imageView2;
	IBOutlet UIImageView *imageView3;
	IBOutlet UIProgressView *progressIndicator;
	IBOutlet UISwitch *accurateProgress;
	
}

- (IBAction)fetchThreeImages:(id)sender;

@end
