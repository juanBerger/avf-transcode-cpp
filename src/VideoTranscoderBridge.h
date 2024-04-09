//
// Created by Juan Aboites on 4/8/24.
//

#ifndef AVF_TRANSCODE_CPP_VIDEOTRANSCODERBRIDGE_H
#define AVF_TRANSCODE_CPP_VIDEOTRANSCODERBRIDGE_H

#include <iostream>

class VideoTranscoderBridge
{
    public:

        VideoTranscoderBridge();
        ~VideoTranscoderBridge();
        static std::string getCurrentPath();
        static bool setNewSource(std::string& path, float startTime);
        static bool decodeBatch();

    private:


};

#endif //AVF_TRANSCODE_CPP_VIDEOTRANSCODERBRIDGE_H
