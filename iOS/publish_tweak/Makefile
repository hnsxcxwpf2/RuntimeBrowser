
THEOS_DEVICE_IP = 192.168.1.63
THEOS_DEVICE_PORT = 22


ARCHS = arm64


include theos/makefiles/common.mk

TWEAK_NAME = runtimebrowser
runtimebrowser_FILES = Tweak.m \
                        ../GCDWebServer/SkflyGCDWebServer.m \
\
                        ../GCDWebServer/Core/GCDWebServer.m \
                        ../GCDWebServer/Core/GCDWebServerConnection.m \
                        ../GCDWebServer/Core/GCDWebServerFunctions.m \
                        ../GCDWebServer/Core/GCDWebServerRequest.m \
                        ../GCDWebServer/Core/GCDWebServerResponse.m \
\
                        ../GCDWebServer/Requests/GCDWebServerDataRequest.m \
                        ../GCDWebServer/Requests/GCDWebServerFileRequest.m \
                        ../GCDWebServer/Requests/GCDWebServerMultiPartFormRequest.m \
                        ../GCDWebServer/Requests/GCDWebServerURLEncodedFormRequest.m \
\
                        ../GCDWebServer/Responses/GCDWebServerDataResponse.m \
                        ../GCDWebServer/Responses/GCDWebServerErrorResponse.m \
                        ../GCDWebServer/Responses/GCDWebServerFileResponse.m \
                        ../GCDWebServer/Responses/GCDWebServerStreamedResponse.m \
\
                        ../../model/AAA.m \
                        ../../model/BBB.m \
                        ../../model/RTBClass.m \
                        ../../model/RTBMethod.m \
                        ../../model/RTBProtocol.m \
                        ../../model/RTBRuntime.m \
                        ../../model/RTBRuntimeHeader.m \
                        ../../model/RTBTypeDecoder.m \
\
                        ../RTBMyIP.m

_THEOS_TARGET_CFLAGS += -fobjc-arc
_THEOS_TARGET_CFLAGS += -I /Users/weipengfei/Desktop/__SKFLY/TechSupport/open_source_tool/github/RuntimeBrowser/iOS/GCDWebServer/Core/
_THEOS_TARGET_CFLAGS += -I /Users/weipengfei/Desktop/__SKFLY/TechSupport/open_source_tool/github/RuntimeBrowser/iOS/GCDWebServer/Requests/
_THEOS_TARGET_CFLAGS += -I /Users/weipengfei/Desktop/__SKFLY/TechSupport/open_source_tool/github/RuntimeBrowser/iOS/GCDWebServer/Responses/
#SHARED_CFLAGS = -fobjc-arc
#ADDITIONAL_OBJCFLAGS = -fobjc-arc

#skfly add begin
include /Users/weipengfei/Desktop/__SKFLY/workspace/theos_rpetrich_20190815/common/SkflyCommonSupport/SkflyCommonSupport/public/PublicMakeFile
#skfly add end

include $(THEOS_MAKE_PATH)/tweak.mk


