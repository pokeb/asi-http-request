//
//  RootViewController.h
//  SCS-iOS-Demo
//
//  Created by Littlebox222 on 14-8-14.
//  Copyright (c) 2014年 Littlebox222. All rights reserved.
//

#import "AppDelegate.h"
#import <UIKit/UIKit.h>

@interface RootViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, ASIHTTPRequestDelegate>;

@property (strong, nonatomic) ASINetworkQueue *globleNetWorkQueue;

@end
