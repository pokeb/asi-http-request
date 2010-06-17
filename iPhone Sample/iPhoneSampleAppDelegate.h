//
//  iPhoneSampleAppDelegate.h
//  Part of the ASIHTTPRequest sample project - see http://allseeing-i.com/ASIHTTPRequest for details
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright All-Seeing Interactive 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface iPhoneSampleAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {
    UIWindow *window;
    UITabBarController *tabBarController;
	IBOutlet UILabel *statusMessage;

}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;

@end
