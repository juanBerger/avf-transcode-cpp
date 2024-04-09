//
// Created by Juan Aboites on 4/8/24.
//


#include <iostream>
#include "VideoTranscoderBridge.h"
#include "VideoTranscoder.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>

VideoTranscoderBridge::VideoTranscoderBridge()= default;
VideoTranscoderBridge::~VideoTranscoderBridge()= default;

bool VideoTranscoderBridge::setNewSource(std::string& path, float startTime){
    return [VideoTranscoder setNewSource:path secondArg:startTime];
}

bool VideoTranscoderBridge::decodeBatch() {
    return [VideoTranscoder decodeBatch];
}

std::string VideoTranscoderBridge::getCurrentPath() {
    NSString *obj_String = [VideoTranscoder getCurrentPath];
    return [obj_String UTF8String];
}