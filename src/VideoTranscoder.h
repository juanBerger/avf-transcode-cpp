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
        + (BOOL) setNewSource:(std::string&)path startTime:(Float64)startTime;
        + (BOOL) DecodeBatch;
    @end

#ifdef __cplusplus
}
#endif

#endif //AVF_TRANSCODE_CPP_VIDEOTRANSCODER_H


