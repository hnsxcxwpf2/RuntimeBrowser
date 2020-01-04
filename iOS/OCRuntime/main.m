//
//  main.m
//  OCRuntime
//
//  Created by Nicolas Seriot on 6/14/13.
//  Copyright (c) 2013 Nicolas Seriot. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RTBAppDelegate.h"

#import "../AAA.h"

int main(int argc, char * argv[])
{
    @autoreleasepool
    {
        //NSLog(@"%@",[AAA myClassMethod]);
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([RTBAppDelegate class]));
    }
}
