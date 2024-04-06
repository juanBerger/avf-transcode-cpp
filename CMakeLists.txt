cmake_minimum_required(VERSION 3.27)
project(avf_transcode_cpp)
set(CMAKE_CXX_STANDARD 14)

add_executable(avf_transcode_cpp
        src/main.mm)

target_link_libraries(avf_transcode_cpp "-framework Foundation")
target_link_libraries(avf_transcode_cpp "-framework AVFoundation")
target_link_libraries(avf_transcode_cpp "-framework CoreMedia")
target_link_libraries(avf_transcode_cpp "-framework CoreVideo")
target_link_libraries(avf_transcode_cpp "-framework CoreFoundation")