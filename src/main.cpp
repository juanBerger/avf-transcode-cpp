//
// Created by Juan Aboites on 4/8/24.
//
#include <iostream>
#include "VideoTranscoderBridge.h"

int main() {
    std::string inputFile = "/Users/juanaboites/dev/postlink/avf-transcode-cpp/src/videos/two.mp4";

    VideoTranscoderBridge::setNewSource(inputFile, 1);
    std::string currentPath = VideoTranscoderBridge::getCurrentPath();
    std::cout << currentPath << std::endl;

    VideoTranscoderBridge::decodeBatch();

    std::cout << "Done" << std::endl;
    return 0;
}