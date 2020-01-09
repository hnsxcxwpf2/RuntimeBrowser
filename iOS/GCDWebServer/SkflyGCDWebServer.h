//
//  SkflyGCDWebServer.h
//  OCRuntime
//
//  Created by 魏鹏飞 on 2020/1/5.
//  Copyright © 2020 Nicolas Seriot. All rights reserved.
//

#ifndef SkflyGCDWebServer_h
#define SkflyGCDWebServer_h

#import "./Core/GCDWebServer.h"
#import "../../model/RTBRuntime.h"

@interface SkflyGCDWebServer : NSObject

@property (strong, nonatomic) RTBRuntime *allClasses;
@property (strong, nonatomic) GCDWebServer *webServer;

+ (SkflyGCDWebServer *)sharedInstance;

- (GCDWebServerResponse *)responseForPath:(NSString *)path;
- (NSString *)myIPAddress;
- (UInt16)serverPort;

- (void)stopWebServer;
- (void)startWebServer;

@end



#endif /* SkflyGCDWebServer_h */
