//
// Created by Juan Aboites on 4/8/24.
//
#include <iostream>
#include "VideoTranscoderBridge.h"

int main() {
    std::string inputFile = "/Users/juanaboites/dev/postlink/avf-transcode-cpp/src/videos/two.mp4";
    VideoTranscoderBridge vtb;
    std::string cp = vtb.getCurrentPath();
    std::cout << cp << std::endl;
    std::cout << "Done" << std::endl;
    return 0;
}