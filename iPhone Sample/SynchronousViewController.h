//
//  SynchronousViewController.h
//  asi-http-request
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SynchronousViewController : UIViewController {
	IBOutlet UITextView *htmlSource;
}
- (IBAction)simpleURLFetch:(id)sender;

@end
