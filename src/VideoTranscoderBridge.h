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
        //bool setNewSource(std::string& path, Float64 start);
        static std::string getCurrentPath();

    private:


};

#endif //AVF_TRANSCODE_CPP_VIDEOTRANSCODERBRIDGE_H
