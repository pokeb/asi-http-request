//
//  AppDelegate.m
//  SCS-iOS-Demo
//
//  Created by Littlebox222 on 14-8-14.
//  Copyright (c) 2014年 Littlebox222. All rights reserved.
//

#import "AppDelegate.h"
#import "RootViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    if ([kAccessKey isEqualToString:@"YOUR ACCESSKEY"] || [kSecretKey isEqualToString:@"YOUR SECRETKEY"]) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误" message:@"请在AppDelegate.h中填写您的accessKey与secretKey" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
        
    }else {
        RootViewController *rootViewController = [[[RootViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
        rootViewController.title = @"操作结果见控制台";
        UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:rootViewController] autorelease];
        [self.window setRootViewController:nav];
    }
    
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{

}

@end
