//
//  SkflyGCDWebServer.m
//  OCRuntime
//
//  Created by 魏鹏飞 on 2020/1/5.
//  Copyright © 2020 Nicolas Seriot. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SkflyGCDWebServer.h"

#include <sys/types.h>
#include <sys/sysctl.h>

#import "./Core/GCDWebServer.h"
#import "./Responses/GCDWebServerDataResponse.h"

//#import "RTBClassDisplayVC.h"
#import "../../model/RTBRuntimeHeader.h"
#import "../../model/RTBClass.h"
#import "../../model/RTBProtocol.h"
#import "../RTBMyIP.h"
#import "../../model/RTBRuntime.h"
//#import "RTBObjectsTVC.h"

#if (! TARGET_OS_IPHONE)
#import <objc/objc-runtime.h>
#else
#import <objc/runtime.h>
#import <objc/message.h>
#endif


static SkflyGCDWebServer *sharedInstance;

@implementation SkflyGCDWebServer

+ (SkflyGCDWebServer *)sharedInstance
{
    if(sharedInstance == nil)
    {
        sharedInstance = [[SkflyGCDWebServer alloc] init];
        sharedInstance.allClasses = [RTBRuntime sharedInstance];
    }
    return sharedInstance;
}

- (NSString *)myIPAddress
{
    NSString *myIP = [[[RTBMyIP sharedInstance] ipsForInterfaces] objectForKey:@"en0"];
    
#if TARGET_IPHONE_SIMULATOR
    if(!myIP)
    {
        myIP = [[[RTBMyIP sharedInstance] ipsForInterfaces] objectForKey:@"en1"];
    }
#endif
    
    return myIP;
}

NSMutableString *g_strSkflyAllContent = nil;

#pragma mark 处理/skfly/allContent 返回所有类和协议内容请求
- (GCDWebServerDataResponse *)responseForSkflyAllContent
{
    NSString *html=@"加载中....";
    if([g_strSkflyAllContent containsString:@"加载完毕啦!!!"])
    {
        html = [self htmlPageWithContents:g_strSkflyAllContent title:@"iOS Runtime Browser - List View"];
    }
    
    return [GCDWebServerDataResponse responseWithHTML:html];
}

#pragma mark 获取所有类和协议的内容的线程
-(void) thread_skflyAllContent
{
    g_strSkflyAllContent = [NSMutableString string];
    return;
    /**/
    NSArray *classes = [_allClasses sortedClassStubs];
    [g_strSkflyAllContent appendFormat:@"%@ classes loaded\n\n", @([classes count])];
    BOOL displayPropertiesDefaultValues = [[NSUserDefaults standardUserDefaults] boolForKey:@"RTBDisplayPropertiesDefaultValues"];
    int tempIndex=0;
    int tempLastIndex=0;
    for(RTBClass *cs in classes)
    {
        //if([cs.stubClassname compare:@"S"] == NSOrderedAscending) continue;
        [g_strSkflyAllContent appendFormat:@"<A HREF=\"/classes/%@.h\">%@.h</A><pre>&#009;[%@]</pre>\n", cs.classObjectName, cs.classObjectName,cs.imagePath];
        NSString* header=@"NULL";
        @try
        {
            header = [RTBRuntimeHeader headerForClass:NSClassFromString(cs.classObjectName) displayPropertiesDefaultValues:displayPropertiesDefaultValues];
            if(header == nil)
            {
                NSString* tempStr= [NSString stringWithFormat:@"%@ 头文件生成失败 \n",cs.classObjectName];
                NSLog(@"%@",tempStr);
                header =tempStr;
            }
        }
        @catch (NSException *exception)
        {
            NSString* tempStr=[NSString stringWithFormat:@"生成头文件时出现异常  类:[%@] 异常[%@]",cs.classObjectName,exception];
            NSLog(@"%@",tempStr);
            header=tempStr;
        }
        @finally
        {
            [g_strSkflyAllContent appendFormat:@"%@\n=====================================================",header];
        }
        tempIndex++;
        if(tempIndex-tempLastIndex>1000)
        {
            NSLog(@"类:%d/%ld",tempIndex,classes.count);
            tempLastIndex=tempIndex;
        }
    }
    
    [g_strSkflyAllContent appendString:@"=============================以下是协议=========================\n========================================\n\n"];
    
    NSArray *protocols = [_allClasses sortedProtocolStubs];
    [g_strSkflyAllContent appendFormat:@"%@ protocols loaded\n\n", @([protocols count])];
    int tempIndex2=0;
    tempLastIndex=0;
    for(RTBProtocol *p in protocols)
    {
        [g_strSkflyAllContent appendFormat:@"<A HREF=\"/protocols/%@.h\">%@.h</A>\n", p.protocolName, p.protocolName];
        NSString *header=@"NULL";
        @try
        {
            header = [RTBRuntimeHeader headerForProtocol:p];
            if(header == nil)
            {
                NSString* tempStr= [NSString stringWithFormat:@"%@ 头文件生成失败 \n",p.protocolName];
                NSLog(@"%@",tempStr);
                header =tempStr;
            }
        }
        @catch (NSException *exception)
        {
            NSString* tempStr=[NSString stringWithFormat:@"生成头文件时出现异常  类:[%@] 异常[%@]",p.protocolName,exception];
            NSLog(@"%@",tempStr);
            header=tempStr;
        }
        @finally
        {
            [g_strSkflyAllContent appendFormat:@"%@\n=====================================================",header];
        }
        [g_strSkflyAllContent appendFormat:@"%@\n=====================================================\n\n",header];
        tempIndex2++;
        if(tempIndex2-tempLastIndex>100)
        {
            NSLog(@"协议:%d/%ld",tempIndex2,protocols.count);
            tempLastIndex=tempIndex2;
        }
    }
    [g_strSkflyAllContent insertString:@"加载完毕啦!!!\n\n" atIndex:0];
}

#pragma mark 处理/classes/返回所有类请求
- (GCDWebServerDataResponse *)responseForList
{
    NSMutableString *ms = [NSMutableString string];
    
    NSArray *classes = [_allClasses sortedClassStubs];
    [ms appendFormat:@"%@ classes loaded\n\n", @([classes count])];
    for(RTBClass *cs in classes)
    {
        //if([cs.stubClassname compare:@"S"] == NSOrderedAscending) continue;
        [ms appendFormat:@"<A HREF=\"/classes/%@.h\">%@.h</A><pre>&#009;[%@]</pre>\n", cs.classObjectName, cs.classObjectName,cs.imagePath];
    }
    
    NSString *html = [self htmlPageWithContents:ms title:@"iOS Runtime Browser - List View"];
    
    return [GCDWebServerDataResponse responseWithHTML:html];
}



#pragma mark 处理/protocols/请求
- (GCDWebServerDataResponse *)responseForProtocols
{
    NSMutableString *ms = [NSMutableString string];
    NSArray *protocols = [_allClasses sortedProtocolStubs];
    [ms appendFormat:@"%@ protocols loaded\n\n", @([protocols count])];
    for(RTBProtocol *p in protocols)
    {
        [ms appendFormat:@"<A HREF=\"/protocols/%@.h\">%@.h</A>\n", p.protocolName, p.protocolName];
    }
    NSString *html = [self htmlPageWithContents:ms title:@"iOS Runtime Browser - Protocols"];
    return [GCDWebServerDataResponse responseWithHTML:html];
}

+ (NSString *)basePath
{
    static NSString *basePath = nil;
    if(basePath == nil)
    {
#pragma mark 获取指定类所属的动态库
        const char* imageNameC = class_getImageName([NSString class]);
        if(imageNameC == NULL)
            return nil;
        
        NSString *imagePath = [NSString stringWithCString:imageNameC encoding:NSUTF8StringEncoding];
        if(imagePath == nil)
            return nil;
        
        static NSString *s = @"/System/Library/Frameworks/Foundation.framework/Foundation";
        
        if([s length] > [imagePath length])
            return nil;
        NSUInteger i = [imagePath length] - [s length];
        basePath = [imagePath substringToIndex:i];
    }
    return basePath;
}

#pragma mark 返回指定类的头文件
- (GCDWebServerDataResponse *)responseForClassHeaderPath:(NSString *)headerPath
{
    NSString *fileName = [headerPath lastPathComponent];
    NSString *className = [fileName stringByDeletingPathExtension];
    
    BOOL displayPropertiesDefaultValues = [[NSUserDefaults standardUserDefaults] boolForKey:@"RTBDisplayPropertiesDefaultValues"];
    NSString *header = [RTBRuntimeHeader headerForClass:NSClassFromString(className) displayPropertiesDefaultValues:displayPropertiesDefaultValues];
    
    if(header == nil)
    {
        NSLog(@"-- [ERROR] empty header for path %@", headerPath);
        header = @"/* empty header 头文件生成失败 */\n";
    }
    
    return [GCDWebServerDataResponse responseWithText:header];
}

#pragma mark 返回指定协议的头文件
- (GCDWebServerDataResponse *)responseForProtocolHeaderPath:(NSString *)headerPath
{
    NSString *fileName = [headerPath lastPathComponent];
    NSString *protocolName = [fileName stringByDeletingPathExtension];
    
    RTBProtocol *p = [RTBProtocol protocolStubWithProtocolName:protocolName];
    NSString *header = [RTBRuntimeHeader headerForProtocol:p];
    
    return [GCDWebServerDataResponse responseWithText:header];
}

#pragma mark 响应/tree/Frameworks/框架模块路径 请求
- (GCDWebServerDataResponse *)responseForTreeWithFrameworksName:(NSString *)name
{
    NSDictionary *allClassesByImagesPath = [[RTBRuntime sharedInstance] allClassStubsByImagePath];
    
    if([allClassesByImagesPath objectForKey:name] == NO)
    {
        [[RTBRuntime sharedInstance] emptyCachesAndReadAllRuntimeClasses];
        allClassesByImagesPath = [[RTBRuntime sharedInstance] allClassStubsByImagePath];
        //NSLog(@"-- %@", [allClassesByImagesPath objectForKey:imagePath]);
    }
    
    NSArray *classes = allClassesByImagesPath[name];
    
    NSMutableString *ms = [NSMutableString string];
    [ms appendFormat:@"%@\n%@ classes\n\n", name, @([classes count])];
    
    NSArray *sortedDylibs = [classes sortedArrayUsingComparator:^NSComparisonResult(NSString *s1, NSString *s2)
                             {
                                 return [s1 compare:s2];
                             }];
    
    for(NSString *s in sortedDylibs)
    {
        [ms appendFormat:@"<A HREF=\"/tree%@/%@.h\">%@.h</A>\n", name, s, s];
    }
    
    NSString *html = [self htmlPageWithContents:ms title:[name lastPathComponent]];
    
    return [GCDWebServerDataResponse responseWithHTML:html];
}

#pragma mark 处理/tree/other/*请求
- (GCDWebServerResponse *)responseForTreeWithDylibWithName:(NSString *)name
{
    NSDictionary *allClassesByImagesPath = [[RTBRuntime sharedInstance] allClassStubsByImagePath];
    __block NSArray *classes = nil;
    //判断是否出现了多个匹配项
    __block int tempIndex=0;
    [allClassesByImagesPath enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
     {
         //dylib有可能被缓存导致路径不一致?
         //BOOL isDylib = [[key pathExtension] isEqualToString:@"dylib"];
         //if([key rangeOfString:name].location != NSNotFound || (isDylib && [[key lastPathComponent] isEqualToString:[name lastPathComponent]]))
         if([key isEqualToString:name])
         {
             classes = obj;
             tempIndex=tempIndex+1;
             //*stop = YES;
         }
     }];
    
    NSMutableString *ms = [NSMutableString string];
    if(classes==nil)
    {
        [ms appendFormat:@"⚠️警告!!!!!!! 没有找到对应的字典项\n\n"];
    }
    else
    {
        if(tempIndex>1)
        {
            [ms appendFormat:@"⚠️警告!!!!!!! 该路径匹配到了多个字典项\n\n"];
        }
        
        [ms appendFormat:@"%@\n%@ class\n\n", name, @([classes count])];
        
        NSArray *sortedDylibs = [classes sortedArrayUsingComparator:^NSComparisonResult(NSString *s1, NSString *s2)
                                 {
                                     return [s1 compare:s2];
                                 }];
        
        for(NSString *s in sortedDylibs)
        {
            [ms appendFormat:@"<A HREF=\"/tree%@/%@.h\">%@.h</A>\n", name, s, s];
        }
    }
    NSString *html = [self htmlPageWithContents:ms title:[name lastPathComponent]];
    
    return [GCDWebServerDataResponse responseWithHTML:html];
}

#pragma mark 处理/tree/*请求
- (GCDWebServerResponse *)responseForTreeWithPath:(NSString *)path
{
    GCDWebServerResponse *response=nil;
    if([path hasPrefix:@"/Frameworks/"]&&(![path isEqualToString:@"/Frameworks/"]))
    {
        path=[path substringFromIndex:[@"/Frameworks/" length]];
        response = [self responseForTreeWithFrameworksName:path];
        if(response)
            return response;
    }
    
    if([path hasPrefix:@"/PrivateFrameworks/"]&&(![path isEqualToString:@"/PrivateFrameworks/"]))
    {
        path=[path substringFromIndex:[@"/PrivateFrameworks/" length]];
        response = [self responseForTreeWithFrameworksName:path];
        if(response)
            return response;
    }
    
    if([path hasPrefix:@"/other/"]&&(![path isEqualToString:@"/other/"]))
    {
        path=[path substringFromIndex:[@"/other/" length]];
        response = [self responseForTreeWithDylibWithName:path];
        if(response)
            return response;
    }
    
#pragma mark 处理/tree/请求
    if([path isEqualToString:@"/"])
    {
        NSString *s = @"<a href=\"/tree/Frameworks/\">/System/Library/Frameworks/</a>\n"
        "<a href=\"/tree/PrivateFrameworks/\">/System/Library/PrivateFrameworks/</a>\n"
        "<a href=\"/tree/other/\">/其他/</a>\n";
        
        NSString *html = [self htmlPageWithContents:s title:@"iOS Runtime Browser - Tree View"];
        return [GCDWebServerDataResponse responseWithHTML:html];
    }
    
    NSMutableString *ms = [NSMutableString string];
    
#pragma mark 处理/tree/Frameworks/和/tree/PrivateFrameworks请求
    if([@[@"/Frameworks/", @"/PrivateFrameworks/"] containsObject:path])
    {
        NSDictionary *classStubsByImagePath = [[RTBRuntime sharedInstance] allClassStubsByImagePath];
/*
        for(id tempK in classStubsByImagePath)
        {
            NSLog(@"%@",tempK);
        }
 */
        NSMutableArray *files = [NSMutableArray array];
        [classStubsByImagePath enumerateKeysAndObjectsUsingBlock:^(NSString *imagePath, RTBClass *classStub, BOOL *stop)
         {
             NSString *prefix = [NSString stringWithFormat:@"/System/Library%@", path];
             if([imagePath hasPrefix:prefix] == NO)
             {
                 return;
             }
             [files addObject:imagePath];
         }];
        [files sortUsingSelector:@selector(compare:)];
        
        [ms appendFormat:@"%@\n%@ frameworks loaded\n\n", path, @([files count])];
        
        for(NSString *fileName in files)
        {
            [ms appendFormat:@"<a href=\"/tree%@%@\">%@/</a>\n", path, fileName, fileName];
        }
        
    }
#pragma mark 处理/tree/other
    else if([path isEqualToString:@"/other/"])
    {
        NSDictionary *classStubsByImagePath = [[RTBRuntime sharedInstance] allClassStubsByImagePath];
        NSMutableArray *files = [NSMutableArray array];
        [classStubsByImagePath enumerateKeysAndObjectsUsingBlock:^(NSString *imagePath, RTBClass *classStub, BOOL *stop)
         {
             NSString *prefix1 = @"/System/Library/Frameworks/";
             NSString *prefix2 = @"/System/Library/PrivateFrameworks/";
             if([imagePath hasPrefix:prefix1]||[imagePath hasPrefix:prefix2])
             {
                 return;
             }
             [files addObject:imagePath];
         }];
        [files sortUsingSelector:@selector(compare:)];
        [ms appendFormat:@"%@\n%@ dylibs\n\n", path, @([files count])];
        
        for(NSString *fileName in files)
        {
            [ms appendFormat:@"<a href=\"/tree%@%@\">%@/</a>\n", path, fileName, fileName];
        }
    }
#pragma mark 处理/tree/protocols
    else
    {
        [ms appendFormat:@"无法识别的请求/tree/%@", path];
    }
    
    NSString *html = [self htmlPageWithContents:ms title:@"iOS Runtime Browser - Tree View"];
    return [GCDWebServerDataResponse responseWithHTML:html];
}

#pragma mark 加载header.html
- (NSString *)htmlHeader
{
    /*
     NSString *path = [[NSBundle mainBundle] pathForResource:@"header" ofType:@"html"];
     return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
     */
    NSString* retStr=
    @"<HTML>\n"
    "<HEAD>\n"
    "<TITLE>__TITLE__</TITLE>\n"
    "</HEAD>\n"
    "<BODY>\n"
    "<code>\n"
    "<pre>\n"
    "   ___          _   _             ___\n"
    "  | _ \\_  _ _ _| |_(_)_ __  ___  | _ )_ _ _____ __ _____ ___ _ _\n"
    "  |   / || | ' \\  _| | '  \\/ -_) | _ \\ '_/ _ \\ V  V (_-// -_) '_|\n"
    "  |_|_\\_,_|_||_\\__|_|_|_|_\\___| |___/_| \\___/\\_/\\_//__/\\___|_|\n"
    "  \n"
    "<h1>Objective-C 运行时类浏览器</h1>\n"
    " -------------------------------------------------------------------------------\n"
    "\n"
    "\n";
    return retStr;
}

#pragma mark 加载footer.html
- (NSString *)htmlFooter
{
    NSString* retStr=
    @"\n"
    " -------------------------------------------------------------------------------\n"
    "\n"
    " Source code: https://github.com/nst/RuntimeBrowser\n"
    "\n"
    " Authors: Ezra Epstein (eepstein@prajna.com)\n"
    "          Nicolas Seriot (nicolas@seriot.ch)\n"
    "\n"
    " Copyright (c) 2002 by Prajna IT Consulting.\n"
    "                       http://www.prajna.com\n"
    "               2015 by Nicolas Seriot\n"
    "                       http://www.seriot.ch\n"
    "魏鹏飞修正版\n"
    "\n"
    " ========================================================================\n"
    "\n"
    " THIS PROGRAM AND THIS CODE COME WITH ABSOLUTELY NO WARRANTY.\n"
    " THIS CODE HAS BEEN PROVIDED \"AS IS\" AND THE RESPONSIBILITY\n"
    " FOR ITS OPERATIONS IS 100% YOURS.\n"
    "\n"
    " ========================================================================\n"
    " \n"
    " RuntimeBrowser is free software; you can redistribute it and/or modify\n"
    " it under the terms of the GNU General Public License as published by\n"
    " the Free Software Foundation; either version 2 of the License, or\n"
    " (at your option) any later version.\n"
    "\n"
    " RuntimeBrowser is distributed in the hope that it will be useful,\n"
    " but WITHOUT ANY WARRANTY; without even the implied warranty of\n"
    " MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n"
    " GNU General Public License for more details.\n"
    "\n"
    " You should have received a copy of the GNU General Public License\n"
    " along with RuntimeBrowser (in a file called \"COPYING.txt\"); if not,\n"
    " write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330,\n"
    " Boston, MA  02111-1307  USA\n"
    "\n"
    "</pre>\n"
    "</code>\n"
    "</BODY>\n"
    "\n";
    return retStr;
}

#pragma mark 生成一个html页面
- (NSString *)htmlPageWithContents:(NSString *)contents title:(NSString *)title
{
    NSString *header = [[[self htmlHeader] mutableCopy] stringByReplacingOccurrencesOfString:@"__TITLE__" withString:title];
    return [@[header, contents, [self htmlFooter]] componentsJoinedByString:@"\n"];
}

#pragma mark 处理http请求的总入口
- (GCDWebServerResponse *)responseForPath:(NSString *)path
{
    BOOL isProtocol = [path hasPrefix:@"/protocols/"] || [path hasPrefix:@"/tree/protocols/"];
    BOOL isHeaderFile = [path hasSuffix:@".h"];
    if(isHeaderFile)
    {
        if(isProtocol)
        {
            return [self responseForProtocolHeaderPath:path];
        }
        else
        {
            return [self responseForClassHeaderPath:path];
        }
    }
    
    if([path hasPrefix:@"/classes"])
    {
        return [self responseForList];
    }
    else if ([path hasPrefix:@"/tree"])
    {
        NSString *subPath = [path substringFromIndex:[@"/tree" length]];
        return [self responseForTreeWithPath:subPath];
    }
    else if([path hasPrefix:@"/protocols"])
    {
        return [self responseForProtocols];
    }
    else if ([path isEqualToString:@"/"])
    {
        NSString *s = [NSString stringWithFormat:
                       @" You can browse the loaded <a href=\"/classes/\">classes</a> and <a href=\"/protocols/\">protocols</a>, or browse everything presented in <a href=\"/tree/\">tree</a>.\n\n"
                       "<a href=\"/skfly/allcontent\">所有类和协议内容</a>\n\n"
                       "<a href=\"/skfly/reloadAll\">重新加载类和协议</a>\n\n"
                       " To retrieve the headers as on <a href=\"https://github.com/nst/iOS-Runtime-Headers\">https://github.com/nst/iOS-Runtime-Headers</a>:\n\n"
                       "     1. iOS OCRuntime > Frameworks tab > Load All\n"
                       "     2. $ wget -r http://%@:10000/tree/\n", [self myIPAddress]];
        
        NSString *html = [self htmlPageWithContents:s title:@"iOS Runtime Browser"];
        
        return [GCDWebServerDataResponse responseWithHTML:html];
    }
    else if([path isEqualToString:@"/skfly/allcontent"])
    {
        return [self responseForSkflyAllContent];
    }
    else if([path isEqualToString:@"/skfly/reloadAll"])
    {
        [[RTBRuntime sharedInstance] emptyCachesAndReadAllRuntimeClasses];
        if([g_strSkflyAllContent containsString:@"加载完毕啦!!!"])
        {
            NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(thread_skflyAllContent) object:nil];
            [thread start];
            return [self responseForPath:@"/"];
        }
        else
        {
            NSString *html = [self htmlPageWithContents:@"正在加载中, 请稍后再试" title:@"iOS Runtime Browser"];
            return [GCDWebServerDataResponse responseWithHTML:html];
        }
    }
    
    return nil;
}

#pragma mark 关闭Web服务器
- (void)stopWebServer
{
    [_webServer stop];
}

#pragma mark 启动Web服务器
- (void)startWebServer
{
    if([_webServer isRunning])
    {
        NSLog(@"重复启动");
    }
    NSDictionary *ips = [[RTBMyIP sharedInstance] ipsForInterfaces];
    BOOL isConnectedThroughWifi = [ips objectForKey:@"en0"] != nil;
    
    if(isConnectedThroughWifi || TARGET_IPHONE_SIMULATOR)
    {
        [GCDWebServer setLogLevel:2];
        self.webServer = [[GCDWebServer alloc] init];
        //__weak typeof(self) weakSelf = self;
        [_webServer addDefaultHandlerForMethod:@"GET"
                                  requestClass:[GCDWebServerRequest class]
                                  processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
                                    {
                                      //__strong typeof(weakSelf) strongSelf = weakSelf;
                                      if(self == nil) return nil;
                                      
                                      //NSLog(@"-- %@ %@", request.method, request.path);
                                      
                                      return [self responseForPath:request.path];
                                      
                                  }];
        
        NSProcessInfo *pInfo = [NSProcessInfo processInfo];  // 获取当前进程
        BOOL success = [_webServer startWithPort:[pInfo processIdentifier] bonjourName:[pInfo processName]];
        if(success == NO)
        {
            NSLog(@"Error starting HTTP Server.");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error starting HTTP Server"
                                                            message:@""
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            
            [self.webServer stop];
            self.webServer = nil;
        }
        else
        {
            NSString* tempStr=[NSString stringWithFormat:@"Visit %@ in your web browser\n[进程名:%@]",_webServer.serverURL,pInfo.processName];
            NSLog(@"%@", tempStr);
#ifndef THEOS_COMPILE
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"服务器"
                                                            message:tempStr
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
#endif
            [UIApplication sharedApplication].idleTimerDisabled = YES; // prevent sleep
        }
    }
    else
    {
        // TODO: allow USB connection..
        NSLog(@"Not connected through wifi, don't start web server.");
    }
    
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(thread_skflyAllContent) object:nil];
    [thread start];
}

- (UInt16)serverPort
{
    return [_webServer port];
}


@end
