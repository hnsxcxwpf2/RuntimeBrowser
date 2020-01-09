/* How to Hook with Logos
 Hooks are written with syntax similar to that of an Objective-C @implementation.
 You don't need to #include <substrate.h>, it will be done automatically, as will
 the generation of a class list and an automatic constructor.
 
 %hook ClassName
 
 // Hooking a class method
 + (id)sharedInstance {
 return %orig;
 }
 
 // Hooking an instance method with an argument.
 - (void)messageName:(int)argument {
 %log; // Write a message about this call, including its class, name and arguments, to the system log.
 
 %orig; // Call through to the original function with its original arguments.
 %orig(nil); // Call through to the original function with a custom argument.
 
 // If you use %orig(), you MUST supply all arguments (except for self and _cmd, the automatically generated ones.)
 }
 
 // Hooking an instance method with no arguments.
 - (id)noArguments {
 %log;
 id awesome = %orig;
 [awesome doSomethingElse];
 
 return awesome;
 }
 
 // Always make sure you clean up after yourself; Not doing so could have grave consequences!
 %end
 */

#include "../GCDWebServer/SkflyGCDWebServer.h"
#include <dlfcn.h>

int tweak_main()
{
    @autoreleasepool
    {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.skfly.RuntimeBrowser.plist"];
        NSString* tempStr=[prefs objectForKey:@"CustomBundleID"];
        NSArray * tempArr = [tempStr componentsSeparatedByString:@" "];

        if([[prefs objectForKey:[NSString stringWithFormat:@"RuntimeBrowserEnabled-%@", [[NSBundle mainBundle] bundleIdentifier]]] boolValue]
           ||[tempArr containsObject:[[NSBundle mainBundle] bundleIdentifier]])
        {
            NSLog(@"启动RuntimeBrowser Web服务器[%@]",[[NSBundle mainBundle] bundleIdentifier]);
            [[SkflyGCDWebServer sharedInstance] startWebServer];
        }
        else
        {
            NSLog(@"RuntimeBrowser Web服务器未开启[%@] 已开启服务自定义BundleID的有:[%@]",[[NSBundle mainBundle] bundleIdentifier],tempStr);
        }
    }
    return 1;
}

#ifdef THEOS_COMPILE

#import <CaptainHook/CaptainHook.h>

CHConstructor // code block that runs immediately upon load
{
    tweak_main();
}

#endif
