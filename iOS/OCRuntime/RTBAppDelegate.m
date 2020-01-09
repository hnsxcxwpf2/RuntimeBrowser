//
//  AppDelegate.m
//  OCRuntime
//
//  Created by Nicolas Seriot on 6/14/13.
//  Copyright (c) 2013 Nicolas Seriot. All rights reserved.
//

#import "RTBAppDelegate.h"

#include <sys/types.h>
#include <sys/sysctl.h>

#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"

#import "RTBClassDisplayVC.h"
#import "RTBRuntimeHeader.h"
#import "RTBClass.h"
#import "RTBProtocol.h"
#import "RTBMyIP.h"
#import "RTBRuntime.h"
#import "RTBObjectsTVC.h"

#if (! TARGET_OS_IPHONE)
#import <objc/objc-runtime.h>
#else
#import <objc/runtime.h>
#import <objc/message.h>
#endif

#import "../GCDWebServer/SkflyGCDWebServer.h"


@implementation RTBAppDelegate

//- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
//{
//    // Override point for customization after application launch.
//    return YES;
//}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

//- (void)applicationWillTerminate:(UIApplication *)application
//{
//    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//}


//- (RTBClassDisplayVC *)classDisplayVC {
//	if(_classDisplayVC == nil) {
//		self.classDisplayVC = [[RTBClassDisplayVC alloc] initWithNibName:@"RTBClassDisplayVC" bundle:nil];
//	}
//	return _classDisplayVC;
//}

- (void)useClass:(NSString *)className
{
    RTBObjectsTVC *objectsTVC = [[RTBObjectsTVC alloc] initWithStyle:UITableViewStylePlain];
    Class klass = NSClassFromString(className);
    [objectsTVC setInspectedObject:klass];
    
    UINavigationController *objectsNC = [[UINavigationController alloc] initWithRootViewController:objectsTVC];
    
    UITabBarController *tabBarController = (UITabBarController *)_window.rootViewController;
    [tabBarController presentViewController:objectsNC animated:YES completion:^{
        //do nothing
    }];
}

- (NSString *)myIPAddress
{
    return [[SkflyGCDWebServer sharedInstance] myIPAddress];
}

#pragma mark 关闭Web服务器
- (void)stopWebServer
{
    [[SkflyGCDWebServer sharedInstance] stopWebServer];
}


#pragma mark 入口点
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window.tintColor = [UIColor purpleColor];
    self.window.backgroundColor = [UIColor whiteColor];
    
    NSString *defaultsPath = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"RTBDisplayPropertiesDefaultValues"];
    BOOL startWebServer = [[NSUserDefaults standardUserDefaults] boolForKey:@"RTBEnableWebServer"];
    if(startWebServer)
    {
        [[SkflyGCDWebServer sharedInstance] startWebServer];
        self.webServer=[[SkflyGCDWebServer sharedInstance] webServer];
    }
    return YES;
}

- (UInt16)serverPort
{
    return [[SkflyGCDWebServer sharedInstance] serverPort];
}

- (void)showHeaderForClassName:(NSString *)className
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    RTBClassDisplayVC *classDisplayVC = (RTBClassDisplayVC *)[sb instantiateViewControllerWithIdentifier:@"RTBClassDisplayVC"];
    classDisplayVC.className = className;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:classDisplayVC];
    navigationController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
    self.window.rootViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self.window.rootViewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)showHeaderForProtocol:(RTBProtocol *)protocol
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    RTBClassDisplayVC *classDisplayVC = (RTBClassDisplayVC *)[sb instantiateViewControllerWithIdentifier:@"RTBClassDisplayVC"];
    classDisplayVC.protocolName = [protocol protocolName];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:classDisplayVC];
    navigationController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
    self.window.rootViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self.window.rootViewController presentViewController:navigationController animated:YES completion:nil];
}

//- (IBAction)dismissModalView:(id)sender {
//	[_tabBarController dismissViewControllerAnimated:YES completion:^{
//        //
//    }];
//}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[SkflyGCDWebServer sharedInstance] stopWebServer];
}

@end
