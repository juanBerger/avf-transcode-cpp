//
// Created by Juan Aboites on 4/8/24.
//

#import "VideoTranscoder.h"
#include <iostream>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <VideoToolbox/VideoToolbox.h>

@implementation VideoTranscoder

    NSString* currentPath = @"Current Path";
    CMTime currentPresentationTimestamp;
    std::unordered_map<CMTimeValue, NSData*> transcodeBuffer = {};

    + (NSString*) getCurrentPath{
        return currentPath;
    }

    + (NSData*) getFrame:(int32_t)ts {
        auto itemIter = transcodeBuffer.find(ts);
        if (itemIter != transcodeBuffer.end()){
            NSData* frame = transcodeBuffer[ts];
            transcodeBuffer.erase(ts); //don't think I need to release anything here?
            return frame;
        }

        else return nil;
        return nil;
    }

    + (void) transcodeToMemory:(std::string&)path{

        currentPath = [NSString stringWithUTF8String:path.c_str()];
        NSURL* url = [NSURL fileURLWithPath:currentPath];
        AVAsset* asset = [AVAsset assetWithURL:url];

        NSError *error = nil;
        AVAssetReader* reader = [AVAssetReader assetReaderWithAsset:asset error:&error];

        AVAssetReaderTrackOutput *readerTrackOutput =
                [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                 outputSettings: @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)}];

        readerTrackOutput.alwaysCopiesSampleData = NO; //this is important
        [reader addOutput:readerTrackOutput];
        BOOL success = [reader startReading];

        VTCompressionSessionRef compressionSession;
        OSStatus status = VTCompressionSessionCreate(nil, readerTrackOutput.track.naturalSize.width, readerTrackOutput.track.naturalSize.height, kCMVideoCodecType_H264, nil, nil, nil, didCompressH264, (__bridge void *)self, &compressionSession);
        if (status != noErr) {
            // Handle the error
            return;
        }

        // Set the compression session properties
        VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);

        // Read and encode the video frames
        CMSampleBufferRef sampleBuffer;
        int64_t frameNumber = 0;
        while ((sampleBuffer = [readerTrackOutput copyNextSampleBuffer])) {

            CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

            // Encode the frame using the compression session
            VTEncodeInfoFlags flags;
            CMTime pts = CMTimeMake(frameNumber++, 1000);
            VTCompressionSessionEncodeFrame(compressionSession, imageBuffer, pts, kCMTimeInvalid, nil, nil, &flags);
            CFRelease(sampleBuffer);
        }

        // Finish the compression session
        VTCompressionSessionCompleteFrames(compressionSession, kCMTimeInvalid);

        // Clean up
        VTCompressionSessionInvalidate(compressionSession);
        CFRelease(compressionSession);

    }

    // Compression session callback
    void didCompressH264(void *outputCallbackRefCon, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer) {
        if (status != noErr) {
            // Handle the error
            return;
        }

        if (!CMSampleBufferDataIsReady(sampleBuffer)) {
            // Handle the error
            return;
        }

        // Get the encoded data from the sample buffer
        CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        size_t dataLength, totalLength;
        char *dataPointer;
        OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &dataLength, &totalLength, &dataPointer);
        if (statusCodeRet != noErr) {
            // Handle the error
            return;
        }

        // Create an NSData object with the encoded data
        NSData *encodedData = [NSData dataWithBytes:dataPointer length:dataLength];

        std::cout << encodedData.length << std::endl;

        // Send the encoded data across the network
        // ...
    }

    + (void) transcodeToFile:(std::string&)path {

        currentPath = [NSString stringWithUTF8String:path.c_str()];
        NSURL* url = [NSURL fileURLWithPath:currentPath];
        AVAsset* asset = [AVAsset assetWithURL:url];

        NSError *error = nil;
        AVAssetReader* reader = [AVAssetReader assetReaderWithAsset:asset error:&error];

        AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetMediumQuality];

        exportSession.outputURL = [NSURL fileURLWithPath:@"/Users/juanaboites/dev/postlink/avf-transcode-cpp/src/videos/transcode.mp4"];
        exportSession.outputFileType = AVFileTypeMPEG4;
        exportSession.shouldOptimizeForNetworkUse = YES;

        [exportSession exportAsynchronouslyWithCompletionHandler:nil];

        // Wait for the export to complete
        while (exportSession.status == AVAssetExportSessionStatusExporting) {
            [NSThread sleepForTimeInterval:0.1];
        }

        switch (exportSession.status) {
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"Done");
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"Failed");
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"Cancel");
                break;
            default:
                break;
        }
    }

    + (BOOL) setNewSource:(std::string&)path secondArg:(float)startTime{

        currentPath = [NSString stringWithUTF8String:path.c_str()];
        NSURL* url = [NSURL fileURLWithPath:currentPath];
        AVAsset* asset = [AVAsset assetWithURL:url];

        NSError *error = nil;
        AVAssetReader* reader = [AVAssetReader assetReaderWithAsset:asset error:&error];
        if (error) {
            return false;
        }

        //Not sure about the timescale here
        CMTime start = CMTimeMakeWithSeconds(startTime, 1000);
        currentPresentationTimestamp = start;

        reader.timeRange = CMTimeRangeMake(start, asset.duration);

        NSArray<AVAssetTrack*> *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        AVAssetTrack *track = [tracks objectAtIndex:0];

        //select most appropriate one based on filename extension See here for more info
        //https://developer.apple.com/documentation/avfoundation/avassetreadertrackoutput?language=objc
        NSDictionary* readerOutputSettings  = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) };

        AVAssetReaderTrackOutput* readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:readerOutputSettings];
        readerOutput.alwaysCopiesSampleData = NO; //this is important
        [reader addOutput:readerOutput];

        //Set up writer
        NSDictionary *writerOutputSettings = @{
                AVVideoCodecKey: AVVideoCodecTypeH264,
                AVVideoWidthKey: @(960),
                AVVideoHeightKey: @(540),
                AVVideoCompressionPropertiesKey: @{
                        AVVideoAverageBitRateKey: @(3000)
                }
        };

        AVAssetWriterInput* writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:writerOutputSettings];
        writerInput.expectsMediaDataInRealTime = YES;
        AVAssetWriterInputPixelBufferAdaptor* adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];

        //Start reading
        BOOL success = [reader startReading];
        return success;

    }

    + (BOOL) decodeBatch{

        int loopNum = 0;
        CMSampleBufferRef sampleBuffer = Nil;
        AVAssetReaderOutput* readerOutput;

//        while (loopNum < 10 && (sampleBuffer = [readerOutput copyNextSampleBuffer])){
//
//            std::cout << CMSampleBufferGetTotalSampleSize(sampleBuffer) << std::endl;
//            CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//
//            if (pixelBuffer){
//
//                CMTime ts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//
//                if ([writerInput isReadyForMoreMediaData]) {
//                    [adaptor appendPixelBuffer:pixelBuffer withPresentationTime:ts];
//                }
//
//                CVPixelBufferLockBaseAddress(pixelBuffer, 0);
//                void *pixelBufferPtr = CVPixelBufferGetBaseAddress(pixelBuffer);
//
//                size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
//                size_t height = CVPixelBufferGetHeight(pixelBuffer);
//
//                NSData *frameData = [NSData dataWithBytes:pixelBufferPtr
//                                                   length:bytesPerRow * height];
//
//                transcodeBuffer[ts.value] = frameData;
//
//                CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
//                CFRelease(sampleBuffer);
//
//                //std::cout << transcodeBuffer.size() << std::endl;
//
//                ++loopNum;
//            }
//
//        }

        return true;
    }

@end


//        if (success){
//            CMSampleBufferRef sampleBuffer = nil;
//            while ((sampleBuffer = [readerTrackOutput copyNextSampleBuffer])){
//                CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//                if (imageBuffer){
//                    //CMTime ts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//                    CGSize dims = CVImageBufferGetEncodedSize(imageBuffer);
//                    std::cout << dims.width << std::endl;
//                }
//
//
//            }
//
//        }