//
// Created by Juan Aboites on 4/8/24.
//

#ifndef AVF_TRANSCODE_CPP_VIDEOTRANSCODER_H
#define AVF_TRANSCODE_CPP_VIDEOTRANSCODER_H

#include <iostream>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>

#ifdef __cplusplus
extern "C" {
#endif
    @interface VideoTranscoder : NSObject
        + (NSString*) getCurrentPath;
        + (NSString*) getFrame:(int32_t)ts;
        + (void) transcodeToFile:(std::string&)path;
        + (void) transcodeToMemory:(std::string&)path;
        + (BOOL) setNewSource:(std::string&)path secondArg:(float)startTime;
        + (BOOL) decodeBatch;
    @end

#ifdef __cplusplus
}
#endif

#endif //AVF_TRANSCODE_CPP_VIDEOTRANSCODER_H


